--

CREATE OR REPLACE PROCEDURE dpkg.update_osm_package
(
    _osmPackageID INT,
    _mode text,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**  Update or delete given OSM Package
**
**
**  Auth:   grk
**  Date:   07/08/2013 grk - Initial release
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/18/2016 mem - Log errors to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _debugMode int := 0;
    _authorized int := 0;
    _transName text;
    _msgForLog text := ERROR_MESSAGE();
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

    ---------------------------------------------------
    -- verify OSM package exists
    ---------------------------------------------------

    IF _mode = 'delete' Then
    --<delete>

        ---------------------------------------------------
        -- start transaction
        ---------------------------------------------------
        --
        _transName := 'UpdateOSMPackage';
        begin transaction _transName

        ---------------------------------------------------
        -- 'delete' (mark as inactive) associated file attachments
        ---------------------------------------------------

        UPDATE S_File_Attachment
        SET [Active] = 0
        WHERE Entity_Type = 'osm_package'
        AND Entity_ID = _osmPackageID

        ---------------------------------------------------
        -- remove OSM package from table
        ---------------------------------------------------

        DELETE  FROM dbo.t_osm_package
        WHERE   osm_pkg_id = _osmPackageID

        commit transaction _transName

    End If; --<delete>

    IF _mode = 'test' Then
        RAISERROR ('Test: %d', 11, 20, _osmPackageID)
    End If;

    END TRY
    BEGIN CATCH
        Call format_error_message _message output, _myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0 Then
            ROLLBACK TRANSACTION;
        End If;

        Call post_log_entry 'Error', _msgForLog, 'UpdateOSMPackage'

    END CATCH
    RETURN _myError

/*
*/
END
$$;

COMMENT ON PROCEDURE dpkg.update_osm_package IS 'UpdateOSMPackage';

