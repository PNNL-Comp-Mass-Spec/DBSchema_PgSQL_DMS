--
CREATE OR REPLACE PROCEDURE dpkg.update_data_package_items_xml
(
    _paramListXML text,
    _comment text,
    _mode text = 'update',
    _removeParents int = 0,
    INOUT _message text,
    _callingUser text = ''
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
**  Date:   06/10/2009 grk - initial release
**          05/23/2010 grk - factored out grunt work into new sproc UpdateDataPackageItemsUtility
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/18/2016 mem - Log errors to T_Log_Entries
**          10/19/2016 mem - Update Tmp_DataPackageItems to use an integer field for data package ID
**          11/11/2016 mem - Add parameter _removeParents
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          04/25/2018 mem - Assure that _removeParents is not null
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _itemCountChanged int;
    _wasModified int;
    _authorized int := 0;
    _logUsage int := 0;
    _logMessage text;
    _xml xml;
    _msgForLog text := ERROR_MESSAGE();
BEGIN
    _message := '';

    _itemCountChanged := 0;

    _wasModified := 0;

    -- these are necessary to avoid XML throwing errors
    -- when this stored procedure is called from web page
    --
    SET CONCAT_NULL_YIELDS_NULL ON
    SET ANSI_PADDING ON
    SET ANSI_WARNINGS ON

    BEGIN TRY

        ---------------------------------------------------
        -- Verify that the user can EXECUTE this procedure from the given client host
        ---------------------------------------------------

        Call _authorized => verify_sp_authorized 'UpdateDataPackageItemsXML', _raiseError => 1
        If _authorized = 0 Then
            RAISERROR ('Access denied', 11, 3)
        End If;

        _removeParents := Coalesce(_removeParents, 0);

        -- Set this to 1 to debug

        If _logUsage > 0 Then
            _logMessage := 'Mode: ' ||;
                              Coalesce(_mode, 'Null mode') || '; ' ||
                              'RemoveParents: ' || Cast(_removeParents as varchar(2)) || '; ' ||
                              Coalesce(_paramListXML, 'Error: _paramListXML is null')
            Call post_log_entry 'Debug', _logMessage, 'UpdateDataPackageItemsXML'
        End If;

        ---------------------------------------------------
        -- Create and populate a temporary table using the XML in _paramListXML
        ---------------------------------------------------
        --
        CREATE TEMPORARY TABLE Tmp_DataPackageItems (
            DataPackageID int not null,   -- Data package ID
            ItemType text null,           -- 'Job', 'Dataset', 'Experiment', 'Biomaterial', or 'EUSProposal'
            Identifier text null          -- Job ID, Dataset Name or ID, Experiment Name, Cell_Culture Name, or EUSProposal ID
        );

        _xml := _paramListXML;

        INSERT INTO Tmp_DataPackageItems (DataPackageID, ItemType, Identifier)
        SELECT
            xmlNode.value('@pkg', 'int') Package,
            xmlNode.value('@type', 'text') ItemType,
            xmlNode.value('@id', 'text') Identifier
        FROM _xml.nodes('//item') AS R(xmlNode)

        ---------------------------------------------------
        Call update_data_package_items_utility (
                                _comment,
                                _mode,
                                _removeParents,
                                _message output,
                                _callingUser);

        if _myError <> 0 Then
            RAISERROR(_message, 11, 14);
        End If;

        DROP TABLE Tmp_DataPackageItems;
     ---------------------------------------------------
     ---------------------------------------------------
    END TRY
    BEGIN CATCH
        Call format_error_message _message output, _myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0 Then
            ROLLBACK TRANSACTION;
        End If;

        Call post_log_entry 'Error', _msgForLog, 'UpdateDataPackageItemsXML'

        DROP TABLE IF EXISTS Tmp_DataPackageItems;
    END CATCH

     ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    return _myError
END
$$;

COMMENT ON PROCEDURE dpkg.update_data_package_items_xml IS 'UpdateDataPackageItemsXML';
