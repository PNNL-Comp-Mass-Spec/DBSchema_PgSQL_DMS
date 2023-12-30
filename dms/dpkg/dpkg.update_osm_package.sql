--
-- Name: update_osm_package(integer, text, text, text, text); Type: PROCEDURE; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE dpkg.update_osm_package(IN _osmpackageid integer, IN _mode text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update or delete the given OSM Package
**      (the only supported mode is 'delete')
**
**  Arguments:
**    _osmPackageID     OSM Package ID
**    _mode             Mode: 'delete'
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   grk
**  Date:   07/08/2013 grk - Initial release
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/18/2016 mem - Log errors to T_Log_Entries
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/16/2023 mem - Ported to PostgreSQL
**          12/09/2023 mem - Add missing semicolon before Return
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

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _mode := Trim(Coalesce(_mode, ''));

        If Not _mode In ( 'delete') Then
            _message := format('The only supported mode is delete; "%s" is invalid', _mode);
            RAISE WARNING '%', _message;
            RETURN;
        End If;

        If _mode = 'delete' Then
            ---------------------------------------------------
            -- 'delete' (mark as inactive) associated file attachments
            ---------------------------------------------------

            UPDATE public.t_file_attachment
            SET active = 0
            WHERE Entity_Type = 'osm_package' AND
                  Entity_ID = _osmPackageID::text;

            ---------------------------------------------------
            -- Remove OSM package from table
            ---------------------------------------------------

            DELETE FROM dpkg.t_osm_package
            WHERE osm_pkg_id = _osmPackageID;

            If FOUND Then
                _message := format('Deleted OSM package %s', _osmPackageID);
            Else
                _message := format('OSM package %s does not exist; nothing to delete', _osmPackageID);
            End If;

        End If;

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
    END;

END
$$;


ALTER PROCEDURE dpkg.update_osm_package(IN _osmpackageid integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_osm_package(IN _osmpackageid integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON PROCEDURE dpkg.update_osm_package(IN _osmpackageid integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateOSMPackage';

