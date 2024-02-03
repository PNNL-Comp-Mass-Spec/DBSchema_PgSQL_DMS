--
-- Name: delete_param_entries_for_id(integer, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.delete_param_entries_for_id(IN _paramfileid integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete rows from t_param_entries and t_param_file_mass_mods for a given parameter file ID
**
**  Arguments:
**    _paramFileID  Parameter file ID
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   kja
**  Date:   07/22/2004
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/02/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
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

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    If Coalesce(_paramFileID, 0) <= 0 Then
        RAISE WARNING 'Parameter file ID is not a positive integer; nothing to delete';
        RETURN;
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


ALTER PROCEDURE public.delete_param_entries_for_id(IN _paramfileid integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE delete_param_entries_for_id(IN _paramfileid integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.delete_param_entries_for_id(IN _paramfileid integer, INOUT _message text, INOUT _returncode text) IS 'DeleteParamEntriesForID';

