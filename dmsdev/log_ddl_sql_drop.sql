--
-- Name: log_ddl_sql_drop(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.log_ddl_sql_drop() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds log entries to t_schema_change_log regarding the dropped object
**
**  Auth:   mem
**  Date:   10/08/2019 mem - Initial version
**          02/12/2020 mem - Ignore schema pg_temp
**
*****************************************************/
DECLARE
    -- _msg text;
BEGIN

    INSERT INTO public.t_schema_change_log (entered, login_name, client_addr, command_tag, object_type, schema_name, object_name)
    SELECT now(),
           current_user,
           inet_client_addr(),
           'DROP',
           e.object_type,
           e.schema_name,
           e.object_name
    FROM pg_event_trigger_dropped_objects() e
    WHERE NOT e.schema_name in ('pg_temp', 'pg_toast') AND NOT e.object_name is null;

END
$$;


ALTER FUNCTION public.log_ddl_sql_drop() OWNER TO d3l243;

--
-- Name: FUNCTION log_ddl_sql_drop(); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.log_ddl_sql_drop() IS 'Adds log entries to t_schema_change_log regarding the dropped object';

