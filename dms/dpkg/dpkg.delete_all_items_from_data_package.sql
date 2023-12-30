--
-- Name: delete_all_items_from_data_package(integer, text, text, text, text); Type: PROCEDURE; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE dpkg.delete_all_items_from_data_package(IN _packageid integer, IN _mode text DEFAULT 'delete'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Remove all existing items from a data package, deleting rows in the associated tracking tables:
**      - dpkg.t_data_package_analysis_jobs
**      - dpkg.t_data_package_datasets
**      - dpkg.t_data_package_experiments
**      - dpkg.t_data_package_biomaterial
**      - dpkg.t_data_package_eus_proposals
**
**  Arguments:
**    _packageID        Data package ID
**    _mode             Mode: should be 'delete', but the actual value is ignored
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   grk
**  Date:   06/10/2009 grk - Initial release
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/05/2016 mem - Add T_Data_Package_EUS_Proposals
**          05/18/2016 mem - Log errors to T_Log_Entries
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

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

        RETURN;
    END;

    BEGIN

        ---------------------------------------------------
        -- Update item counts
        ---------------------------------------------------

        CALL dpkg.update_data_package_item_counts (_packageID);

        UPDATE dpkg.t_data_package
        SET last_modified = CURRENT_TIMESTAMP
        WHERE data_pkg_id = _packageID;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _exceptionMessage := format('%s; calling update_data_package_item_counts for data package ID %s', _exceptionMessage, _packageID);

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        RETURN;
    END;

END
$$;


ALTER PROCEDURE dpkg.delete_all_items_from_data_package(IN _packageid integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE delete_all_items_from_data_package(IN _packageid integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON PROCEDURE dpkg.delete_all_items_from_data_package(IN _packageid integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'DeleteAllItemsFromDataPackage';

