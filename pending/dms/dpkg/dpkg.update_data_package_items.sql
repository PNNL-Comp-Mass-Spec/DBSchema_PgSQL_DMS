--
CREATE OR REPLACE PROCEDURE dpkg.update_data_package_items
(
    _packageID int,
    _itemType text,
    _itemList text,
    _comment text,
    _mode text = 'update',
    _removeParents int = 0,
    INOUT _message text = '',
    _callingUser text = '',
    _infoOnly boolean = false
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
    _wasModified int := 0;
    _authorized int := 0;
    _entityName text;
    _logUsage int := 0;
    _usageMessage text := 'Updating ' + @entityName + 's for data package ' + Cast(@packageID as varchar(12));
    _msgForLog text := ERROR_MESSAGE();
BEGIN
    _message := '';

    BEGIN TRY

        ---------------------------------------------------
        -- Verify that the user can EXECUTE this procedure from the given client host
        ---------------------------------------------------

        Call _authorized => verify_sp_authorized 'UpdateDataPackageItems', _raiseError => 1

        If _authorized = 0 Then
            RAISERROR ('Access denied', 11, 3)
        End If;

        SELECT CASE INTO _entityName
                                 WHEN _itemType IN ('analysis_jobs', 'job', 'jobs') THEN 'Job'
                                 WHEN _itemType IN ('datasets', 'dataset') THEN 'Dataset'
                                 WHEN _itemType IN ('experiments', 'experiment') THEN 'Experiment'
                                 WHEN _itemType = 'biomaterial' THEN 'Biomaterial'
                                 WHEN _itemType = 'proposals' THEN 'EUSProposal'
                                 ELSE ''
                             END
        --
        If Coalesce(_entityName, '') = '' Then
            RAISERROR('Item type "%s" is unrecognized', 11, 14, _itemType);
        End If;

        If _logUsage > 0 Then
            Call post_log_entry 'Debug', _usageMessage, 'UpdateDataPackageItems'
        End If;

        _itemList := Trim(Coalesce(_itemList, ''));
        _itemList := Replace(Replace(_itemList, ' ', ','), Char(9), ',');

        ---------------------------------------------------
        -- Create and populate a temporary table using the XML in _paramListXML
        ---------------------------------------------------
        --
        CREATE TEMPORARY TABLE Tmp_DataPackageItems (
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
