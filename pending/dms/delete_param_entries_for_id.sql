--
CREATE OR REPLACE PROCEDURE public.delete_param_entries_for_id
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
**      Deletes Sequest Param Entries from a given Param File ID
**
**  Auth:   kja
**  Date:   07/22/2004
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _authorized boolean;

    _msg text;
    _result int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name
    INTO _currentSchema, _currentProcedure
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

    ---------------------------------------------------
    -- Delete any entries for the parameter file from the entries table
    ---------------------------------------------------

    DELETE FROM t_param_entries
    WHERE param_file_id = _paramFileID;

    ---------------------------------------------------
    -- Delete any entries for the parameter file from the global mod mapping table
    ---------------------------------------------------

    DELETE FROM t_param_file_mass_mods
    WHERE param_file_id = _paramFileID;

END
$$;

COMMENT ON PROCEDURE public.delete_param_entries_for_id IS 'DeleteParamEntriesForID';
