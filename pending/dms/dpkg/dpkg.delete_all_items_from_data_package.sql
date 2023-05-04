--
CREATE OR REPLACE PROCEDURE dpkg.delete_all_items_from_data_package
(
    _packageID INT,
    _mode text default 'delete',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text default ''
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
BEGIN
    _message := '';
    _returnCode:= '';

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

        DELETE FROM dpkg.t_data_package_analysis_jobs
        WHERE data_pkg_id  = _packageID;

        DELETE FROM dpkg.t_data_package_datasets
        WHERE data_pkg_id  = _packageID;

        DELETE FROM dpkg.t_data_package_experiments
        WHERE data_pkg_id  = _packageID;

        DELETE FROM dpkg.t_data_package_biomaterial
        WHERE data_pkg_id = _packageID;

        DELETE FROM dpkg.t_data_package_eus_proposals
        WHERE data_pkg_id = _packageID;

    END TRY
    BEGIN CATCH
        Call format_error_message _message output, _myError output

        -- rollback any open transactions
        If (XACT_STATE()) <> 0 Then
            ROLLBACK TRANSACTION;
        End If;

        Call post_log_entry 'Error', _msgForLog, 'DeleteAllItemsFromDataPackage'
    END CATCH

    COMMIT;

    BEGIN TRY

        ---------------------------------------------------
        -- Update item counts
        ---------------------------------------------------

        Call update_data_package_item_counts (_packageID);

        UPDATE dpkg.t_data_package
        SET last_modified = CURRENT_TIMESTAMP
        WHERE data_pkg_id = _packageID;

    END TRY
    BEGIN CATCH
        Call format_error_message _message output, _myError output

        -- rollback any open transactions
        If (XACT_STATE()) <> 0 Then
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
