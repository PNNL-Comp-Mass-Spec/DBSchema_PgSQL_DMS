--
-- Name: delete_param_file(text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.delete_param_file(IN _paramfilename text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete given parameter file from the t_param_files and all referencing tables
**
**  Arguments:
**    _paramFileName    Parameter file name
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   kja
**  Date:   07/22/2004 mem
**          02/12/2010 mem - Now updating _message when the parameter file is successfully deleted
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

    _paramFileID int;
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

    _paramFileName := Trim(Coalesce(_paramFileName, ''));

    If _paramFileName = '' Then
        _message := format('Parameter file name not specified');
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Get ParamFileID
    ---------------------------------------------------

    SELECT param_file_id
    INTO _paramFileID
    FROM t_param_files
    WHERE param_file_name = _paramFileName::citext;

    If Not FOUND Then
        _message := format('Parameter file does not exist: %s', _paramFileName);
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    CALL public.delete_param_file_by_id (
                    _paramFileID,
                    _message => _message,           -- Output
                    _returnCode => _returnCode);    -- Output

    If _returnCode = '' And _message = '' Then
        _message := format('Deleted parameter file %s', _paramFileName);
        RAISE INFO '%', _message;
    End If;

END
$$;


ALTER PROCEDURE public.delete_param_file(IN _paramfilename text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE delete_param_file(IN _paramfilename text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.delete_param_file(IN _paramfilename text, INOUT _message text, INOUT _returncode text) IS 'DeleteParamFile';

