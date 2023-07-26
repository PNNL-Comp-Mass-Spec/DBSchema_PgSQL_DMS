--
-- Name: log_ddl_command_end(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.log_ddl_command_end() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds log entries to t_schema_change_log regarding DDL updates
**
**  Auth:   mem
**  Date:   10/08/2019 mem - Initial version
**          02/12/2020 mem - Ignore schema pg_temp
**          08/19/2022 mem - Add an exception handler
**                         - Move the Insert Into command to inside an If statement
**
*****************************************************/
DECLARE
    _message text;
    _sqlState text;
    _exceptionMessage text;
    _exceptionContext text;
BEGIN

    If Exists (Select * from pg_event_trigger_ddl_commands() WHERE NOT schema_name in ('pg_temp', 'pg_toast')) Then

        INSERT INTO public.t_schema_change_log (entered, login_name, client_addr, command_tag, object_type, schema_name, object_name, function_name, function_source)
        SELECT now(),
               current_user,
               inet_client_addr(),
               e.command_tag,
               e.object_type,
               e.schema_name,
               coalesce(FunctionInfo.proname, e.object_identity) as object_name,
               FunctionInfo.proname as function_name,
               FunctionInfo.prosrc as function_source
        FROM pg_event_trigger_ddl_commands() e
             LEFT OUTER JOIN pg_proc as FunctionInfo
               ON FunctionInfo.oid = e.objid
        WHERE NOT e.schema_name in ('pg_temp', 'pg_toast');

    End If;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlState = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionContext = pg_exception_context;

    _message := format('Exception adding row to t_schema_change_log; %s', _exceptionMessage);

    RAISE WARNING '%', _message;
    -- RAISE WARNING 'Context: %', _exceptionContext;

END
$$;


ALTER FUNCTION public.log_ddl_command_end() OWNER TO d3l243;

--
-- Name: FUNCTION log_ddl_command_end(); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.log_ddl_command_end() IS 'Adds log entries to t_schema_change_log regarding DDL updates';

