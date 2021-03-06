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
**
*****************************************************/
DECLARE
    -- _msg text;
BEGIN

    INSERT INTO t_schema_change_log (entered, login_name, client_addr, command_tag, object_type, schema_name, object_name, function_name, function_source)
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

END
$$;


ALTER FUNCTION public.log_ddl_command_end() OWNER TO d3l243;

--
-- Name: FUNCTION log_ddl_command_end(); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.log_ddl_command_end() IS 'Adds log entries to t_schema_change_log regarding DDL updates';

