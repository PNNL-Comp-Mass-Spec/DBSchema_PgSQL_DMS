--
-- Name: verify_sp_authorized(text, text, boolean, boolean); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.verify_sp_authorized(_procedurename text, _targetschema text DEFAULT 'public'::text, _logerror boolean DEFAULT false, _infoonly boolean DEFAULT false) RETURNS TABLE(authorized boolean, procedure_name text, user_name text, host_ip text, message text)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Verify that a user can use the given procedure
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
**        SELECT schema_name, object_name, name_with_schema
**        INTO _currentSchema, _currentProcedure, _nameWithSchema
**        FROM get_current_function_info('<auto>', _showDebug => false);
**
**        SELECT authorized
**        INTO _authorized
**        FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);
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
**          02/14/2023 mem - Use case-insensitive comparisons with procedure_name and login_name
**          05/10/2023 mem - Simplify call to post_log_entry()
**          05/17/2023 mem - Change _authorized from int to boolean
**          05/18/2023 mem - Remove implicit string concatenation
**          05/22/2023 mem - Capitalize reserved words
**          05/31/2023 mem - Use format() for string concatenation
**                         - Add back implicit string concatenation
**                         - Rename variable
**          06/12/2023 mem - Ignore prefix 'PNL\' when looking for the login name in t_sp_authorization
**          09/07/2023 mem - Align assignment statements
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**
*****************************************************/
DECLARE
    _clientHostIP inet;
    _userName text;
    _authorizationTableWithSchema text;
    _procedureNameWithSchema text;
    _s text;
    _result int;
    _authorized boolean := false;
    _message text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _procedureName := Trim(Coalesce(_procedureName, ''));
    _logError      := Coalesce(_logError, false);
    _infoOnly      := Coalesce(_infoOnly, false);

    _targetSchema  := Trim(Coalesce(_targetSchema, ''));

    If _targetSchema = '' Then
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
            _message := format('PID %s not found in the table returned by function get_active_connections; will assume access denied for the current user (%s)',
                               pg_backend_pid(), session_user);

            RETURN QUERY
            SELECT false AS authorized, _procedureName AS procedure_name, _userName AS user_name, host(_clientHostIP) AS host_ip, _message as message;

            RETURN;
        Elsif Coalesce(_userName, '') = '' Then
            _message := format('Function get_active_connections returned a blank username for PID %s; will assume access denied for the current user (%s)',
                               pg_backend_pid(), session_user);

            RETURN QUERY
            SELECT false AS authorized, _procedureName AS procedure_name, _userName AS user_name, host(_clientHostIP) AS host_ip, _message as message;

            RETURN;
        End If;
    */

    ---------------------------------------------------
    -- Query t_sp_authorization in the specified schema
    ---------------------------------------------------

    _authorizationTableWithSchema := format('%I.%I', _targetSchema, 't_sp_authorization');

    _s := format(
            'SELECT COUNT(*) '
            'FROM %s auth '
            'WHERE auth.procedure_name = $1::citext AND '
                  '(auth.login_name = $2::citext OR login_name LIKE ''PNL\\%%'' AND Substring(login_name, 5)::citext = $2::citext) AND '
                  '(auth.host_ip = $3::text Or auth.host_ip = ''*'')',
            _authorizationTableWithSchema);

    EXECUTE _s
    INTO _result
    USING _procedureName, _userName, host(_clientHostIP);

    If _result > 0 Then
        _authorized := true;
    Else
        _s := format(
                'SELECT COUNT(*) '
                'FROM %s auth '
                'WHERE auth.procedure_name = ''*'' AND '
                      '(auth.login_name = $1::citext OR login_name LIKE ''PNL\\%%'' AND Substring(login_name, 5)::citext = $1::citext) AND '
                      '(auth.host_ip = $2::text Or auth.host_ip = ''*'')',
                _authorizationTableWithSchema);

        EXECUTE _s
        INTO _result
        USING _userName, host(_clientHostIP);

        If _result > 0 Then
            _authorized := true;
        End If;
    End If;

    _procedureNameWithSchema := format('%I.%I', _targetSchema, _procedureName);

    If _authorized Then
        RETURN QUERY
        SELECT true, _procedureName, _userName, host(_clientHostIP), '' as message;

        RETURN;
    End If;

    If _infoOnly Then
        _message := format('Access denied to %s for current user (%s on host IP %s)',
                            _procedureNameWithSchema, session_user, Coalesce(_clientHostIP::text, 'null'));

        RETURN QUERY
        SELECT false, _procedureName, _userName, host(_clientHostIP), _message as message;

        RETURN;
    End If;

    _message := format('User %s cannot call procedure %s from host IP %s',
                Coalesce(_userName, '??'),
                Coalesce(_procedureNameWithSchema, _procedureName),
                Coalesce(_clientHostIP::text, 'null'));

    If _logError Then
        -- Set _ignoreErrors to true when calling post_log_entry since the calling user might not have permission to add a row to t_log_entries
        CALL post_log_entry ('Error', _message, 'Verify_SP_Authorized', _ignoreErrors => true);
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

