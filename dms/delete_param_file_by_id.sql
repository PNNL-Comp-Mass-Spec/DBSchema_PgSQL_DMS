--
-- Name: delete_param_file_by_id(integer, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.delete_param_file_by_id(IN _paramfileid integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete given parameter file from the t_param_files and all referencing tables
**
**      The parameter file will not be deleted if any analysis jobs reference it
**
**  Arguments:
**    _paramFileID      Parameter file ID
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   kja
**  Date:   08/11/2004 kja
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

    _parameterFile citext;
    _jobCount int;
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
        _message := format('Parameter file ID is not a positive integer; nothing to delete');
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Look for analysis jobs that use the parameter file
    ---------------------------------------------------

    SELECT param_file_name
    INTO _parameterFile
    FROM t_param_files
    WHERE param_file_id = _paramFileID;

    If Not FOUND Then
        _message := format('Parameter file ID %s does not exist; nothing to delete', _paramFileID);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    SELECT COUNT(job)
    INTO _jobCount
    FROM t_analysis_job
    WHERE param_file_name = _parameterFile;

    If _jobCount > 0 Then
        _message := format('Parameter file cannot be deleted because it is referenced by %s %s: %s',
                           _jobCount,
                           public.check_plural(_jobCount, 'analysis job', 'analysis jobs'),
                           _parameterFile);

        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Delete any entries for the parameter file from the entries table
    ---------------------------------------------------

    CALL public.delete_param_entries_for_id (
                    _paramFileID => _paramFileID,
                    _message     => _message,       -- Output
                    _returnCode  => _returnCode);   -- Output

    If _returnCode <> '' Then
        RAISE EXCEPTION 'Delete from entries table was unsuccessful for param file';
    End If;

    ---------------------------------------------------
    -- Delete entry from table
    ---------------------------------------------------

    DELETE FROM t_param_files
    WHERE param_file_id = _paramFileID;

    _message := format('Deleted parameter file ID %s: %s', _paramFileID, _parameterFile);
    RAISE INFO '%', _message;
END
$$;


ALTER PROCEDURE public.delete_param_file_by_id(IN _paramfileid integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE delete_param_file_by_id(IN _paramfileid integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.delete_param_file_by_id(IN _paramfileid integer, INOUT _message text, INOUT _returncode text) IS 'DeleteParamFileByID';

