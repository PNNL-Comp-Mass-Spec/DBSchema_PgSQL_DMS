--
-- Name: verify_sp_authorized(text, text, integer, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.verify_sp_authorized(_procedurename text, _targetschema text DEFAULT 'public'::text, _logerror integer DEFAULT 0, _infoonly integer DEFAULT 0) RETURNS TABLE(authorized boolean, procedure_name text, user_name text, host_ip text, message text)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Verifies that a user can use the given procedure
**      Authorization is controlled via table t_sp_authorization (in the target schema)
**
**  Arguments:
**    _procedureName    Procedure name to verify permissions to call (do not include schema)
**    _targetSchema     Schema name for the procedure
**    _logError         When 1, try to log an error message to t_log_entries (in the given schema) if the user does not have permission to call the procedure
**                      If the user does not have write access to t_log_entries, a warning will be raised instead
**    _infoOnly         Check for access, but do not log errors, even if _logError is non-zero
**
**  Returns:
**      Table where the authorized column is 1 if authorized, 0 if not authorized
**
**      If authorized, the message column is empty; otherwise it will be of the form:
**      'User Username cannot call procedure ProcedureName from host IP 130.20.228.1
**
**  Auth:   mem
**  Date:   06/16/2017 mem - Initial version
**          01/05/2018 mem - Include username and host_name in RAISERROR message
**          08/18/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _clientHostIP inet;
    _userName text;
    _targetTableWithSchema text;
    _procedureNameWithSchema text;
    _s text;
    _result int;
    _authorized int := 0;
    _message text;
    _sqlState text;
    _exceptionMessage text;
    _exceptionContext text;
BEGIN
    ---------------------------------------------------
    -- Validate inputs
    ---------------------------------------------------

    _procedureName := Coalesce(_procedureName, '');
    _logError := Coalesce(_logError, 0);
    _infoOnly := Coalesce(_infoOnly, 0);

    _targetSchema := COALESCE(_targetSchema, '');
    If (char_length(_targetSchema) = 0) Then
        _targetSchema := 'public';
    End If;

    ---------------------------------------------------
    -- Determine host IP and user name
    ---------------------------------------------------

    SELECT a.host_ip,
           a.user_name
    INTO _clientHostIP, _userName
    FROM public.get_active_connections() a
    WHERE a.pid = pg_backend_pid();

    If Not FOUND Then
        _message := 'PID ' || pg_backend_pid()::text || ' not found in the table returned by function get_active_connections; ' ||
                    'will assume access denied for the current user (' || SESSION_USER || ')';

        RETURN QUERY
        SELECT false AS authorized, _procedureName AS procedure_name, _userName AS user_name, host(_clientHostIP) AS host_ip, _message as message;

        return;
    Elsif Coalesce(_userName, '') = '' Then
        _message := 'Function get_active_connections returned a blank username for PID ' || pg_backend_pid()::text || '; ' ||
                    'will assume access denied for the current user (' || SESSION_USER || ')';

        RETURN QUERY
        SELECT false AS authorized, _procedureName AS procedure_name, _userName AS user_name, host(_clientHostIP) AS host_ip, _message as message;

        return;
    End If;

    ---------------------------------------------------
    -- Query t_sp_authorization in the specified schema
    ---------------------------------------------------

    _targetTableWithSchema := format('%I.%I', _targetSchema, 't_sp_authorization');

    _s := format(
            'SELECT COUNT(*) '
            'FROM %s auth '
            'WHERE auth.procedure_name = $1 AND '
            '      auth.login_name = $2 AND '
            '      (auth.host_ip = $3::text Or auth.host_ip = ''*'')',
            _targetTableWithSchema);

    EXECUTE _s
    INTO _result
    USING _procedureName, _userName, host(_clientHostIP);

    If _result > 0 Then
        _authorized := 1;
    Else
        _s := format(
                'SELECT COUNT(*) '
                'FROM %s auth '
                'WHERE auth.procedure_name = ''*'' AND '
                '      auth.login_name = $1 AND '
                '      (auth.host_ip = $2::text Or auth.host_ip = ''*'')',
                _targetTableWithSchema);

        EXECUTE _s
        INTO _result
        USING _userName, host(_clientHostIP);

        If _result > 0 Then
            _authorized := 1;
        End If;
    End If;

    _procedureNameWithSchema := format('%I.%I', _targetSchema, _procedureName);

    If _authorized > 0 Then
        RETURN QUERY
        SELECT true, _procedureName, _userName, host(_clientHostIP), '' as message;

        return;
    End if;

    If _infoOnly > 0 Then
        _message := 'Access denied to ' || _procedureNameWithSchema || ' for current user (' || SESSION_USER || ' on host IP ' || _clientHostIP || ')';

        RETURN QUERY
        SELECT false, _procedureName, _userName, host(_clientHostIP), _message as message;

        return;
    End If;

    _message := 'User ' || _userName || ' cannot call procedure ' || _procedureNameWithSchema || ' from host IP ' || _clientHostIP;

    If _logError > 0 Then
        -- Passing true to _ignoreErrors when calling post_log_entry since the calling user might not have permission to add a row to t_log_entries
        Call post_log_entry ('Error', _message, 'verify_sp_authorized', _targetSchema, _ignoreErrors := true);
    End If;

    RETURN QUERY
    SELECT false, _procedureName, _userName, host(_clientHostIP), _message as message;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlState = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionContext = pg_exception_context;

    _message := format('Exception checking for permission to call procedure; %s', _exceptionMessage);

    RAISE Warning '%', _message;
    RAISE Warning 'Context: %', _exceptionContext;

    RETURN QUERY
    SELECT false, _procedureName, _userName, host(_clientHostIP), _message as message;
END
$_$;


ALTER FUNCTION public.verify_sp_authorized(_procedurename text, _targetschema text, _logerror integer, _infoonly integer) OWNER TO d3l243;

--
-- Name: FUNCTION verify_sp_authorized(_procedurename text, _targetschema text, _logerror integer, _infoonly integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.verify_sp_authorized(_procedurename text, _targetschema text, _logerror integer, _infoonly integer) IS 'VerifySPAuthorized';

