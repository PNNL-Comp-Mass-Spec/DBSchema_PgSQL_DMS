--
-- Name: verify_sp_authorized(text, text, boolean, boolean); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.verify_sp_authorized(_procedurename text, _targetschema text DEFAULT 'public'::text, _logerror boolean DEFAULT false, _infoonly boolean DEFAULT false) RETURNS TABLE(authorized boolean, procedure_name text, user_name text, host_ip text, message text)
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
**    _logError         When true, try to log an error message to t_log_entries (in the given schema) if the user does not have permission to call the procedure
**                      If the user does not have write access to t_log_entries, a warning will be raised instead
**    _infoOnly         When true, check for access, but do not log errors, even if _logError is true
**
**  Returns:
**      Table where the authorized column is true if authorized, false if not authorized
**
**      If authorized, the message column is empty; otherwise it will be of the form:
**      'User Username cannot call procedure ProcedureName from host IP 130.20.228.1
**
**  Example usage:
**
**        SELECT schema_name, name_with_schema
**        INTO _schemaName, _nameWithSchema
**        FROM get_current_function_info('<auto>', _showDebug => false);
**
**        SELECT authorized
**        INTO _authorized
**        FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);
**
**        If Not _authorized Then
**            -- Commit changes to persist the message logged to public.t_log_entries
**            COMMIT;
**
**            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
**            RAISE EXCEPTION '%', _message;
**        End If;
**
**  Auth:   mem
**  Date:   06/16/2017 mem - Initial version
**          01/05/2018 mem - Include username and host_name in RAISERROR message
**          08/18/2022 mem - Ported to PostgreSQL
**          08/19/2022 mem - Check for null when updating _message
**          08/23/2022 mem - Log messages to t_log_entries in the public schema
**          08/24/2022 mem - Use function local_error_handler() to display the formatted error message
**          08/26/2022 mem - Change _logError and _infoOnly to booleans
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
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    ---------------------------------------------------
    -- Validate inputs
    ---------------------------------------------------

    _procedureName := Coalesce(_procedureName, '');
    _logError := Coalesce(_logError, false);
    _infoOnly := Coalesce(_infoOnly, false);

    _targetSchema := COALESCE(_targetSchema, '');
    If (char_length(_targetSchema) = 0) Then
        _targetSchema := 'public';
    End If;

    ---------------------------------------------------
    -- Determine client host IP and user name
    ---------------------------------------------------

    -- Option 1:
    SELECT inet_client_addr(),      -- This will be null if the current connection is via a Unix-domain socket.
           CURRENT_USER
           -- , inet_server_addr() as host
           -- , inet_server_port() as port
           -- , current_database() as db_name
    INTO _clientHostIP, _userName;

    -- Option 2:
    /*
        SELECT a.host_ip,               -- This will be null if the current connection is via a Unix-domain socket.
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
    */

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

    If _infoOnly Then
        _message := 'Access denied to ' || _procedureNameWithSchema || ' for current user (' || SESSION_USER || ' on host IP ' || Coalesce(_clientHostIP::text, 'null') || ')';

        RETURN QUERY
        SELECT false, _procedureName, _userName, host(_clientHostIP), _message as message;

        return;
    End If;

    _message := 'User ' || Coalesce(_userName, '??') ||
                ' cannot call procedure ' || Coalesce(_procedureNameWithSchema, _procedureName) ||
                ' from host IP ' || Coalesce(_clientHostIP::text, 'null');

    If _logError Then
        -- Passing true to _ignoreErrors when calling post_log_entry since the calling user might not have permission to add a row to t_log_entries
        Call public.post_log_entry ('Error', _message, 'verify_sp_authorized', 'public', _ignoreErrors => true);
    End If;

    RETURN QUERY
    SELECT false, _procedureName, _userName, host(_clientHostIP), _message as message;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlState         = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionDetail  = pg_exception_detail,
            _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        format('Checking for permission to call procedure %s', Coalesce(_procedureNameWithSchema, _procedureName)),
                        _logError => false, _displayError => true);

    RETURN QUERY
    SELECT false, _procedureName, _userName, host(_clientHostIP), _message as message;
END
$_$;


ALTER FUNCTION public.verify_sp_authorized(_procedurename text, _targetschema text, _logerror boolean, _infoonly boolean) OWNER TO d3l243;

--
-- Name: FUNCTION verify_sp_authorized(_procedurename text, _targetschema text, _logerror boolean, _infoonly boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.verify_sp_authorized(_procedurename text, _targetschema text, _logerror boolean, _infoonly boolean) IS 'VerifySPAuthorized';

