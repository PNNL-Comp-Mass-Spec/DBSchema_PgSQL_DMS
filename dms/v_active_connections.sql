--
-- Name: v_active_connections; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_active_connections AS
 SELECT pg_stat_activity.client_addr AS host_ip,
    pg_stat_activity.client_hostname AS host,
    pg_stat_activity.client_port AS port,
    pg_stat_activity.application_name AS application,
    pg_stat_activity.usename AS user_name,
    pg_stat_activity.datname AS db_name,
    pg_stat_activity.pid,
    pg_stat_activity.backend_start,
    pg_stat_activity.query_start,
    pg_stat_activity.state,
    pg_stat_activity.wait_event,
    pg_stat_activity.query
   FROM pg_stat_activity
  WHERE ((pg_stat_activity.backend_type = 'client backend'::text) OR ((pg_stat_activity.backend_type IS NULL) AND (COALESCE(pg_stat_activity.usename, 'postgres'::name) <> 'postgres'::name)));


ALTER VIEW public.v_active_connections OWNER TO d3l243;

--
-- Name: VIEW v_active_connections; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_active_connections IS 'Shows details on active connections by querying pg_stat_activity. If the user is not a superuser, only shows the current user''s connections. Non super-users can use function get_active_connections() to see the host IP, username, and database name of active connections';

--
-- Name: TABLE v_active_connections; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_active_connections TO readaccess;
GRANT SELECT ON TABLE public.v_active_connections TO writeaccess;

