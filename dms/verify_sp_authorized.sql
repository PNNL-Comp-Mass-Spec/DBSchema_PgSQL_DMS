--
-- Name: verify_sp_authorized(text, text, boolean, boolean, boolean); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.verify_sp_authorized(_procedurename text, _targetschema text DEFAULT 'public'::text, _logerror boolean DEFAULT false, _infoonly boolean DEFAULT false, _showauthsrc boolean DEFAULT false) RETURNS TABLE(authorized boolean, procedure_name text, user_name text, host_ip text, message text)
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
**    _showAuthSrc      When true, show the authorization source using RAISE INFO when the user is allowed to use the procedure
**
**  Returns:
**      Table where the authorized column is true if authorized, false if not authorized
**
**      If authorized, the message column is empty; otherwise it will be of the form:
**      'User Username cannot call procedure ProcedureName from host IP 130.20.228.1
**
**  Example usage:
**      SELECT schema_name, object_name, name_with_schema
**      INTO _currentSchema, _currentProcedure, _nameWithSchema
**      FROM get_current_function_info('<auto>', _showDebug => false);
**
**      SELECT authorized, message
**      INTO _authorized, _message
**      FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);
**
**      If Not _authorized Then
**          BEGIN
**              -- Commit changes to persist the message logged to public.t_log_entries
**              COMMIT;
**          EXCEPTION
**              WHEN OTHERS THEN
**              -- The commit failed, likely because this procedure was called from the DMS website, which wraps procedure calls in a transaction
**              -- Ignore the commit error (t_log_entries will not be updated, but _message will be updated)
**          END;
**
**          If Coalesce(_message, '') = '' Then
**              _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
**          End If;
**
**          RAISE EXCEPTION '%', _message;
**      End If;
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
**          03/12/2024 mem - Use 127.0.0.1 for the client host IP if inet_client_addr() is null
**                         - Use CURRENT_USER instead of SESSION_USER when _infoOnly is true
**          03/24/2024 mem - Include the authorization table name in the error message
**          06/23/2024 mem - Update usage example to have an exception handler around the Commit statement
**          12/10/2024 mem - Add support for column cascade_to_all_schema in public.t_sp_authorization (only applicable for rows where procedure_name is '*')
**          12/11/2024 mem - Add parameter _showAuthSrc to optionally show the authorization source using RAISE INFO when the user is allowed to use the procedure
**                         - Only include the authorization source in the query results if _infoOnly is true
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
    _authorizationDescription text = '';
    _authorizationTableDescription text;

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
    _showAuthSrc   := Coalesce(_showAuthSrc, false);

    _targetSchema  := Trim(Coalesce(_targetSchema, ''));

    If _targetSchema = '' Then
        _targetSchema := 'public';
    End If;

    ---------------------------------------------------
    -- Determine client host IP and user name
    ---------------------------------------------------

    -- Option 1:
    -- Note that inet_client_addr() is null if the current connection is via a Unix-domain socket

    SELECT Coalesce(inet_client_addr(), '127.0.0.1'::inet) AS inet_client_addr,
           CURRENT_USER
           -- , inet_server_addr() AS host
           -- , inet_server_port() AS port
           -- , current_database() AS db_name
    INTO _clientHostIP, _userName;

    -- Option 2:
    -- Note that get_active_connections() reports null for host_ip if the current connection is via a Unix-domain socket.
    /*
        SELECT a.host_ip,
               a.user_name
        INTO _clientHostIP, _userName
        FROM public.get_active_connections() a
        WHERE a.pid = pg_backend_pid();

        If Not FOUND Then
            _message := format('PID %s not found in the table returned by function get_active_connections; will assume access denied for the current user (%s)',
                               pg_backend_pid(), CURRENT_USER);

            RETURN QUERY
            SELECT false AS authorized, _procedureName AS procedure_name, _userName AS user_name, host(_clientHostIP) AS host_ip, _message AS message;

            RETURN;
        Elsif Coalesce(_userName, '') = '' Then
            _message := format('Function get_active_connections returned a blank username for PID %s; will assume access denied for the current user (%s)',
                               pg_backend_pid(), CURRENT_USER);

            RETURN QUERY
            SELECT false AS authorized, _procedureName AS procedure_name, _userName AS user_name, host(_clientHostIP) AS host_ip, _message AS message;

            RETURN;
        End If;
    */

    _authorizationTableWithSchema := format('%I.%I', _targetSchema, 't_sp_authorization');

    ---------------------------------------------------
    -- Look for procedure _procedureName in t_sp_authorization in the specified schema
    ---------------------------------------------------

    _s := format(
            'SELECT COUNT(*) '
            'FROM %s auth '
            'WHERE auth.procedure_name = $1::citext AND '
                  '(auth.login_name = $2::citext OR login_name LIKE ''PNL\\%%'' AND Substring(login_name, 5)::citext = $2::citext) AND '
                  '(auth.host_ip = $3 Or auth.host_ip = ''*'')',
            _authorizationTableWithSchema);

    EXECUTE _s
    INTO _result
    USING _procedureName, _userName, host(_clientHostIP);

    If _result > 0 Then
        _authorized := true;
        _authorizationDescription := format('User found in %s with procedure_name ''%s''', 'public.t_sp_authorization', _procedureName);
    Else
        ---------------------------------------------------
        -- Look for procedure '*' in t_sp_authorization in the specified schema
        ---------------------------------------------------

        _s := format(
                'SELECT COUNT(*) '
                'FROM %s auth '
                'WHERE auth.procedure_name = ''*'' AND '
                      '(auth.login_name = $1::citext OR login_name LIKE ''PNL\\%%'' AND Substring(login_name, 5)::citext = $1::citext) AND '
                      '(auth.host_ip = $2 Or auth.host_ip = ''*'')',
                _authorizationTableWithSchema);

        EXECUTE _s
        INTO _result
        USING Coalesce(_userName, '??'), host(_clientHostIP);

        If _result > 0 Then
            _authorized := true;
            _authorizationDescription := format('User found in %s with procedure_name ''*''', _authorizationTableWithSchema);
        Else
            ---------------------------------------------------
            -- Look for procedure '*' with cascade_to_all_schema=true in public.t_sp_authorization
            ---------------------------------------------------

            _s := format(
                    'SELECT COUNT(*) '
                    'FROM %s auth '
                    'WHERE auth.procedure_name = ''*'' AND cascade_to_all_schema AND '
                          '(auth.login_name = $1::citext OR login_name LIKE ''PNL\\%%'' AND Substring(login_name, 5)::citext = $1::citext) AND '
                          '(auth.host_ip = $2 Or auth.host_ip = ''*'')',
                    'public.t_sp_authorization');

            EXECUTE _s
            INTO _result
            USING Coalesce(_userName, '??'), host(_clientHostIP);

            If _result > 0 Then
                _authorized := true;
                _authorizationDescription := format('User found in %s with procedure_name ''*'' and cascade_to_all_schema = true', 'public.t_sp_authorization');
            End If;
        End If;
    End If;

    _procedureNameWithSchema := format('%I.%I', _targetSchema, _procedureName);

    If _authorized Then
        If _showAuthSrc Then
            RAISE INFO '%', _authorizationDescription;
        End If;

        RETURN QUERY
        SELECT true AS authorized,
               _procedureName,
               _userName,
               host(_clientHostIP) AS host_ip,
               CASE WHEN _infoOnly
                    THEN _authorizationDescription
                    ELSE ''
               END AS message;

        RETURN;
    End If;

    _authorizationTableDescription := format('%s%s',
                                             _authorizationTableWithSchema,
                                             CASE WHEN Lower(_authorizationTableWithSchema) = 'public.t_sp_authorization'
                                                  THEN ''
                                                  ELSE ' (and also public.t_sp_authorization)'
                                             END);

    If _infoOnly Then
        _message := format('Access denied to %s for current user (%s on host IP %s); see table %s',
                           Coalesce(_procedureNameWithSchema, _procedureName),
                           Coalesce(_userName, '??'),
                           Coalesce(host(_clientHostIP), 'null'),
                           _authorizationTableDescription);

        RETURN QUERY
        SELECT false, _procedureName, _userName, host(_clientHostIP), _message AS message;

        RETURN;
    End If;

    _message := format('User %s cannot call procedure %s from host IP %s; see table %s',
                       Coalesce(_userName, '??'),
                       Coalesce(_procedureNameWithSchema, _procedureName),
                       Coalesce(host(_clientHostIP), 'null'),
                       _authorizationTableDescription);

    If _logError Then
        -- Set _ignoreErrors to true when calling post_log_entry since the calling user might not have permission to add a row to t_log_entries
        CALL post_log_entry ('Error', _message, 'Verify_SP_Authorized', _ignoreErrors => true);
    End If;

    RETURN QUERY
    SELECT false, _procedureName, _userName, host(_clientHostIP), _message AS message;

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
    SELECT false, _procedureName, _userName, host(_clientHostIP), _message AS message;
END
$_$;


ALTER FUNCTION public.verify_sp_authorized(_procedurename text, _targetschema text, _logerror boolean, _infoonly boolean, _showauthsrc boolean) OWNER TO d3l243;

--
-- Name: FUNCTION verify_sp_authorized(_procedurename text, _targetschema text, _logerror boolean, _infoonly boolean, _showauthsrc boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.verify_sp_authorized(_procedurename text, _targetschema text, _logerror boolean, _infoonly boolean, _showauthsrc boolean) IS 'VerifySPAuthorized';

