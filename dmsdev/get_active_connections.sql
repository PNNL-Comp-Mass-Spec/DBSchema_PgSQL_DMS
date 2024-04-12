--
-- Name: get_active_connections(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_active_connections() RETURNS TABLE(host_ip inet, user_name name, db_name name, pid integer, backend_start timestamp with time zone, query_start timestamp with time zone, query_runtime interval, state text, wait_event text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
/****************************************************
**
**  Desc:
**      Return several columns from pg_stat_activity, including username and host ip
**
**      This is similar to view v_active_connections, but does not include the query details (or the application name)
**
**      This function was created by a superuser and uses SECURITY DEFINER, meaning any user can use this function
**      (since it will run with superuser privileges, even for normal users)
**
**  Auth:   mem
**  Date:   08/17/2022 mem - Initial Version
**
*****************************************************/
BEGIN
    RETURN QUERY
    SELECT a.client_addr AS host_ip,
           a.usename AS user_name,
           a.datname AS db_name,
           a.pid,
           a.backend_start,
           a.query_start,
           now() - a.query_start AS query_runtime,
           a.state,
           a.wait_event
    FROM pg_stat_activity a
    WHERE a.backend_type = 'client backend';

END
$$;


ALTER FUNCTION public.get_active_connections() OWNER TO d3l243;

