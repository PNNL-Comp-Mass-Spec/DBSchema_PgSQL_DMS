--
CREATE OR REPLACE PROCEDURE dpkg.delete_all_items_from_data_package
(
    _packageID INT,
    _mode text = 'delete',
    INOUT _message text,
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**  removes all existing items from data package
**
**  Auth:   grk
**  Date:   06/10/2009 grk - initial release
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/05/2016 mem - Add T_Data_Package_EUS_Proposals
**          05/18/2016 mem - Log errors to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _authorized int := 0;
    _transName text;
    _msgForLog text := ERROR_MESSAGE();
BEGIN
    _message := '';

    BEGIN TRY

        ---------------------------------------------------
        -- Verify that the user can EXECUTE this procedure from the given client host
        ---------------------------------------------------

        Call _authorized => verify_sp_authorized 'DeleteAllItemsFromDataPackage', _raiseError => 1
        If _authorized = 0 Then
            RAISERROR ('Access denied', 11, 3)
        End If;

        _transName := 'DeleteAllItemsFromDataPackage';
        begin transaction _transName

        DELETE FROM dpkg.t_data_package_analysis_jobs
        WHERE data_pkg_id  = _packageID

        DELETE FROM dpkg.t_data_package_datasets
        WHERE data_pkg_id  = _packageID

        DELETE FROM dpkg.t_data_package_experiments
        WHERE data_pkg_id  = _packageID

        DELETE FROM dpkg.t_data_package_biomaterial
        WHERE data_pkg_id = _packageID

        DELETE FROM dpkg.t_data_package_eus_proposals
        WHERE data_pkg_id = _packageID

        ---------------------------------------------------
        commit transaction _transName

        ---------------------------------------------------
        -- Update item counts
        ---------------------------------------------------

        Call update_data_package_item_counts (_packageID);

        UPDATE dpkg.t_data_package
        SET last_modified = CURRENT_TIMESTAMP
        WHERE data_pkg_id = _packageID

     ---------------------------------------------------
     ---------------------------------------------------
    END TRY
    BEGIN CATCH
        Call format_error_message _message output, _myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0 Then
            ROLLBACK TRANSACTION;
        End If;

        Call post_log_entry 'Error', _msgForLog, 'DeleteAllItemsFromDataPackage'
    END CATCH

     ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    return _myError

END
$$;

COMMENT ON PROCEDURE dpkg.delete_all_items_from_data_package IS 'DeleteAllItemsFromDataPackage';
