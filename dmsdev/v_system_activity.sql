--
-- Name: v_system_activity; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_system_activity AS
 SELECT pid,
    datname AS database,
    usename AS username,
    application_name,
    state,
    query_start,
    (now() - query_start) AS query_runtime,
    xact_start,
    query,
    wait_event_type,
    wait_event
   FROM pg_stat_activity a
  WHERE ((backend_type = 'client backend'::text) OR ((backend_type IS NULL) AND (COALESCE(usename, 'postgres'::name) <> 'postgres'::name)));


ALTER VIEW public.v_system_activity OWNER TO d3l243;

--
-- Name: TABLE v_system_activity; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_system_activity TO readaccess;
GRANT SELECT ON TABLE public.v_system_activity TO writeaccess;

