--
-- Name: v_active_connections; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_active_connections AS
 SELECT client_addr AS host_ip,
    client_hostname AS host,
    client_port AS port,
    application_name AS application,
    usename AS user_name,
    datname AS db_name,
    pid,
    backend_start,
    query_start,
    state,
    wait_event,
    query
   FROM pg_stat_activity
  WHERE ((backend_type = 'client backend'::text) OR ((backend_type IS NULL) AND (COALESCE(usename, 'postgres'::name) <> 'postgres'::name)));


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

