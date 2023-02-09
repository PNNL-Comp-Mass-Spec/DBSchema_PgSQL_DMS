--
-- Name: v_system_activity_long_running; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_system_activity_long_running AS
 SELECT a.pid,
    a.datname AS database,
    a.usename AS username,
    a.application_name,
    a.state,
    a.query_start,
    (now() - a.query_start) AS query_runtime,
    a.xact_start,
    a.query,
    a.wait_event_type,
    a.wait_event
   FROM pg_stat_activity a
  WHERE ((now() - a.query_start) > '00:02:00'::interval);


ALTER TABLE public.v_system_activity_long_running OWNER TO d3l243;

--
-- Name: VIEW v_system_activity_long_running; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_system_activity_long_running IS 'Long running queries (duration over 2 minutes); includes idle connections';

--
-- Name: TABLE v_system_activity_long_running; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_system_activity_long_running TO readaccess;
GRANT SELECT ON TABLE public.v_system_activity_long_running TO writeaccess;

