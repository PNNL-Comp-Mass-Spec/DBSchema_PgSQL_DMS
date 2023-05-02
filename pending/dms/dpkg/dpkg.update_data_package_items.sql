--
CREATE OR REPLACE PROCEDURE dpkg.update_data_package_items
(
    _packageID int,
    _itemType text,
    _itemList text,
    _comment text,
    _mode text = 'update',
    _removeParents int default 0,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text default '',
    _infoOnly boolean default false
)
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
**    _itemType        analysis_jobs, datasets, experiments, biomaterial, or proposals
**    _itemList        Comma separated list of items
**    _mode            'add', 'update', 'comment', 'delete'
**    _removeParents   When 1, remove parent datasets and experiments for affected jobs (or experiments for affected datasets)
**
**  Auth:   grk
**  Date:   05/21/2009
**          06/10/2009 grk - Changed size of item list to max
**          05/23/2010 grk - Factored out grunt work into new sproc UpdateDataPackageItemsUtility
**          03/07/2012 grk - Changed data type of _itemList from varchar(max) to text
**          12/31/2013 mem - Added support for EUS Proposals
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/07/2016 mem - Switch to udfParseDelimitedList
**          05/18/2016 mem - Add parameter _infoOnly
**          10/19/2016 mem - Update Tmp_DataPackageItems to use an integer field for data package ID
**          11/14/2016 mem - Add parameter _removeParents
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          03/10/2022 mem - Replace spaces and tabs in the item list with commas
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _authorized int := 0;
    _entityName text;
    _logUsage bool := false;
    _usageMessage text;
    _msgForLog text := ERROR_MESSAGE();
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN TRY
        SELECT CASE
                WHEN _itemType::citext IN ('analysis_jobs', 'job', 'jobs') THEN 'Job'
                WHEN _itemType::citext IN ('datasets', 'dataset') THEN 'Dataset'
                WHEN _itemType::citext IN ('experiments', 'experiment') THEN 'Experiment'
                WHEN _itemType::citext = 'biomaterial' THEN 'Biomaterial'
                WHEN _itemType::citext = 'proposals' THEN 'EUSProposal'
                ELSE ''
               END
        INTO _entityName;
        --
        If Coalesce(_entityName, '') = '' Then
            RAISERROR('Item type "%s" is unrecognized', 11, 14, _itemType);
        End If;

        -- Set this to true to log a debug message
        If _logUsage Then
            _usageMessage := format('Updating %ss for data package %s', _entityName, _packageID);
            Call post_log_entry ('Debug', _usageMessage, 'dpkg.update_data_package_items')
        End If;

        _itemList := Trim(Coalesce(_itemList, ''));
        _itemList := Replace(Replace(_itemList, ' ', ','), Char(9), ',');

        ---------------------------------------------------
        -- Create and populate a temporary table using the XML in _paramListXML
        ---------------------------------------------------
        --
        CREATE TEMP TABLE Tmp_DataPackageItems (
            DataPackageID int not null,   -- Data package ID
            ItemType text null,           -- 'Job', 'Dataset', 'Experiment', 'Biomaterial', or 'EUSProposal'
            Identifier text null          -- Job ID, Dataset Name or ID, Experiment Name, Cell_Culture Name, or EUSProposal ID
        );

        INSERT INTO Tmp_DataPackageItems (DataPackageID, ItemType, Identifier)
        SELECT _packageID, _entityName, Value
        FROM public.parse_delimited_list(_itemList, ',');

        ---------------------------------------------------
        -- Apply the changes
        ---------------------------------------------------
        --
        Call update_data_package_items_utility (
                                    _comment,
                                    _mode,
                                    _removeParents,
                                    _message => _message,           -- Output
                                    _returnCode => _returnCode,     -- Output
                                    _callingUser => _callingUser,
                                    _infoOnly => _infoOnly);
        if _myError <> 0 Then
            RAISERROR(_message, 11, 14);
        End If;

        DROP TABLE Tmp_DataPackageItems;
    END TRY
    BEGIN CATCH
        Call format_error_message _message output, _myError output

        -- Rollback any open transactions
        IF (XACT_STATE()) <> 0 Then
            ROLLBACK TRANSACTION;
        End If;

        Call post_log_entry 'Error', _msgForLog, 'UpdateDataPackageItems'

        DROP TABLE IF EXISTS Tmp_DataPackageItems;
    END CATCH

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    return _myError

END
$$;

COMMENT ON PROCEDURE dpkg.update_data_package_items IS 'UpdateDataPackageItems';
