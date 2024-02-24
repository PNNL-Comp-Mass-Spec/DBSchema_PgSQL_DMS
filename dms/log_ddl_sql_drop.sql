--
-- Name: log_ddl_sql_drop(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.log_ddl_sql_drop() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add log entries to t_schema_change_log regarding the dropped object
**
**  Auth:   mem
**  Date:   10/08/2019 mem - Initial version
**          02/12/2020 mem - Ignore schema pg_temp
**          03/20/2022 mem - Use object_identity for the object name since object_name is null for dropped objects
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

    If Exists (SELECT schema_name FROM pg_event_trigger_dropped_objects() WHERE NOT schema_name IN ('pg_temp', 'pg_toast')) Then

        INSERT INTO public.t_schema_change_log (entered, login_name, client_addr, command_tag, object_type, schema_name, object_name)
        SELECT now(),
               current_user,
               inet_client_addr(),
               'DROP',
               e.object_type,
               e.schema_name,
               e.object_identity
        FROM pg_event_trigger_dropped_objects() e
        WHERE NOT e.schema_name in ('pg_temp', 'pg_toast') AND NOT e.object_identity is null;

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


ALTER FUNCTION public.log_ddl_sql_drop() OWNER TO d3l243;

--
-- Name: FUNCTION log_ddl_sql_drop(); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.log_ddl_sql_drop() IS 'Adds log entries to t_schema_change_log regarding the dropped object';

