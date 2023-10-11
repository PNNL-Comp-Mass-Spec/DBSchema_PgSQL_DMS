--
-- Name: update_data_package_items(integer, text, text, text, text, integer, text, text, text, boolean); Type: PROCEDURE; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE dpkg.update_data_package_items(IN _packageid integer, IN _itemtype text, IN _itemlist text, IN _comment text, IN _mode text DEFAULT 'update'::text, IN _removeparents integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates data package items in list according to command mode
**      This procedure is used by web page "DMS Data Package Detail Report" (data_package/show)
**
**  Arguments:
**    _packageID       Data package ID
**    _itemType        'analysis_jobs', 'jobs', 'job', 'datasets', 'dataset', 'experiments', 'experiment', 'biomaterial', 'proposals', 'EUSProposal'
**    _itemList        Comma-separated list of item IDs or Names
**                     Allowed values: Job IDs, Dataset Names, Dataset IDs, Experiment Names, Biomaterial Names, or EUSProposal IDs
**    _mode            'add', 'comment', or 'delete'
**    _removeParents    When 1 and _mode is 'delete', remove parent datasets and experiments for affected jobs (or experiments for affected datasets)
**    _message          Output: status message
**    _returnCode       Output: return code
**    _callingUser      Username of the calling user
**    _infoOnly         When true, preview updates
**
**  Auth:   grk
**  Date:   05/21/2009
**          06/10/2009 grk - Changed size of item list to max
**          05/23/2010 grk - Factored out grunt work into new sproc UpdateDataPackageItemsUtility
**          03/07/2012 grk - Changed data type of _itemList from varchar(max) to text
**          12/31/2013 mem - Added support for EUS Proposals
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/07/2016 mem - Switch to Parse_Delimited_List
**          05/18/2016 mem - Add parameter _infoOnly
**          10/19/2016 mem - Update Tmp_DataPackageItems to use an integer field for data package ID
**          11/14/2016 mem - Add parameter _removeParents
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          03/10/2022 mem - Replace spaces and tabs in the item list with commas
**          08/17/2023 mem - Ported to PostgreSQL
**          09/27/2023 mem - Add support for _itemType = 'EUSProposal'
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_list for a comma-separated list
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _entityName text;
    _logUsage bool := false;
    _logMessage text;

    _removeParentItems boolean;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN
        _entityName := CASE
                            WHEN _itemType::citext IN ('analysis_jobs', 'job', 'jobs') THEN 'Job'
                            WHEN _itemType::citext IN ('datasets', 'dataset')          THEN 'Dataset'
                            WHEN _itemType::citext IN ('experiments', 'experiment')    THEN 'Experiment'
                            WHEN _itemType::citext IN ('biomaterial')                  THEN 'Biomaterial'
                            WHEN _itemType::citext IN ('proposals', 'EUSProposal')     THEN 'EUSProposal'
                            ELSE ''
                       END;

        If Coalesce(_entityName, '') = '' Then
            _message := format('Item type "%s" is unrecognized', Coalesce(_itemType, 'Error: _itemType is Null'));
            RAISE EXCEPTION '%', _message;
        End If;

        _removeParents := Coalesce(_removeParents, 0);
        _removeParentItems := CASE WHEN _removeParents > 0 THEN true ELSE false END;

        -- Set this to true to log a debug message
        If _logUsage Then
            _logMessage := format('Updating %ss for data package %s', _entityName, _packageID);
            CALL public.post_log_entry ('Debug', _logMessage, 'Update_Data_Package_Items', 'dpkg');
        End If;

        _itemList := Trim(Coalesce(_itemList, ''));

        -- Replace spaces and tabs with commas
        _itemList := Replace(Replace(_itemList, ' ', ','), chr(9), ',');

        ---------------------------------------------------
        -- Create and populate a temporary table using the XML in _paramListXML
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_DataPackageItems (
            DataPackageID int not null,   -- Data package ID
            ItemType   citext null,       -- 'Job', 'Dataset', 'Experiment', 'Biomaterial', or 'EUSProposal'
            Identifier citext null        -- Job ID, Dataset Name or ID, Experiment Name, Biomaterial Name, or EUSProposal ID
        );

        INSERT INTO Tmp_DataPackageItems (DataPackageID, ItemType, Identifier)
        SELECT _packageID, _entityName, Value
        FROM public.parse_delimited_list(_itemList);

        ---------------------------------------------------
        -- Apply the changes
        ---------------------------------------------------

        CALL dpkg.update_data_package_items_utility (
                    _comment,
                    _mode,
                    _removeParents => _removeParentItems,
                    _message       => _message,         -- Output
                    _returnCode    => _returnCode,      -- Output
                    _callingUser   => _callingUser,
                    _infoOnly      => _infoOnly);

        If _returnCode <> '' Then
            If Coalesce(_message, '') = '' Then
                _message := format('Unknown error calling update_data_package_items_utility (return code %s)', _returnCode);
            End If;

            RAISE EXCEPTION '%', _message;
        End If;

        DROP TABLE Tmp_DataPackageItems;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _exceptionMessage := format('%s; Data Package ID %s', _exceptionMessage, _packageID);

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        DROP TABLE IF EXISTS Tmp_DataPackageItems;
    END;

END
$$;


ALTER PROCEDURE dpkg.update_data_package_items(IN _packageid integer, IN _itemtype text, IN _itemlist text, IN _comment text, IN _mode text, IN _removeparents integer, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE update_data_package_items(IN _packageid integer, IN _itemtype text, IN _itemlist text, IN _comment text, IN _mode text, IN _removeparents integer, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _infoonly boolean); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON PROCEDURE dpkg.update_data_package_items(IN _packageid integer, IN _itemtype text, IN _itemlist text, IN _comment text, IN _mode text, IN _removeparents integer, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _infoonly boolean) IS 'UpdateDataPackageItems';

