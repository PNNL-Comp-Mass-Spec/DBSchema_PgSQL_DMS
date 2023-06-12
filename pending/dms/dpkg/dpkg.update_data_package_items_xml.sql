--
CREATE OR REPLACE PROCEDURE dpkg.update_data_package_items_xml
(
    _paramListXML text,
    _comment text,
    _mode text = 'update',
    _removeParents int = 0,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates data package items in list according to command mode
**      This procedure is used by web page "Data Package Items List Report page" (data_package_items/report)
**
**      Example contents of _paramListXML
**      <item pkg="194" type="Job" id="913603"></item><item pkg="194" type="Job" id="913604"></item>
**
**  Arguments:
**    _mode            'add', 'update', 'comment', 'delete'
**    _removeParents   When 1, remove parent datasets and experiments for affected jobs (or experiments for affected datasets)
**
**  Auth:   grk
**  Date:   06/10/2009 grk - Initial release
**          05/23/2010 grk - Factored out grunt work into new sproc UpdateDataPackageItemsUtility
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/18/2016 mem - Log errors to T_Log_Entries
**          10/19/2016 mem - Update Tmp_DataPackageItems to use an integer field for data package ID
**          11/11/2016 mem - Add parameter _removeParents
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          04/25/2018 mem - Assure that _removeParents is not null
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _itemCountChanged int := 0;
    _logUsage bool := false;
    _logMessage text;
    _xml xml;

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

        _removeParents := Coalesce(_removeParents, 0);

        -- Set this to true to log a debug message
        If _logUsage Then
            _logMessage := format('Mode: %s; RemoveParents: %s; %s',
                                _mode,
                                _removeParents,
                                Coalesce(_paramListXML, 'Error: _paramListXML is null'));

            CALL public.post_log_entry ('Debug', _logMessage, 'Update_Data_Package_Items_XML', 'dpkg');
        End If;

        ---------------------------------------------------
        -- Create and populate a temporary table using the XML in _paramListXML
        ---------------------------------------------------
        --
        CREATE TEMP TABLE Tmp_DataPackageItems (
            DataPackageID int not null,   -- Data package ID
            ItemType   citext null,       -- 'Job', 'Dataset', 'Experiment', 'Biomaterial', or 'EUSProposal'
            Identifier citext null        -- Job ID, Dataset Name or ID, Experiment Name, Cell_Culture Name, or EUSProposal ID
        );

        _xml := _paramListXML;

        INSERT INTO Tmp_DataPackageItems (DataPackageID, ItemType, Identifier)
        SELECT
            xmlNode.value('@pkg', 'int') Package,
            xmlNode.value('@type', 'text') ItemType,
            xmlNode.value('@id', 'text') Identifier
        FROM _xml.nodes('//item') AS R(xmlNode)

        ---------------------------------------------------
        CALL update_data_package_items_utility (
                                _comment,
                                _mode,
                                _removeParents,
                                _message => _message,           -- Output
                                _returnCode => _returnCode,     -- Output
                                _callingUser => _callingUser);

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

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        DROP TABLE If Exists Tmp_DataPackageItems;
    END;

END
$$;

COMMENT ON PROCEDURE dpkg.update_data_package_items_xml IS 'UpdateDataPackageItemsXML';
