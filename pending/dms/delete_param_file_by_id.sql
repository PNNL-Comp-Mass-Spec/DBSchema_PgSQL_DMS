--
CREATE OR REPLACE PROCEDURE public.delete_param_file_by_id
(
    _paramFileID int,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Deletes a parameter file by ID
**
**  Auth:   kja
**  Date:   08/11/2004 kja
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _msg text;
    _result int;
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

    ---------------------------------------------------
    -- Delete any entries for the parameter file from the entries table
    ---------------------------------------------------

    CALL delete_param_entries_for_id (_paramFileID, _message => _message, _returnCode => _returnCode);

    If _returnCode <> '' Then
        RAISE EXCEPTION 'Delete from entries table was unsuccessful for param file';
    End If;

    ---------------------------------------------------
    -- Delete entry from dataset table
    ---------------------------------------------------

    DELETE FROM t_param_files
    WHERE param_file_id = _paramFileID;

END
$$;

COMMENT ON PROCEDURE public.delete_param_file_by_id IS 'DeleteParamFileByID';

