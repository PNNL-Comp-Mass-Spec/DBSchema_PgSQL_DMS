--
-- Name: v_system_activity; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_system_activity AS
 SELECT a.pid,
    a.datname AS database,
    a.usename AS "user",
    a.application_name,
    a.state,
    a.query_start,
    (now() - a.query_start) AS query_runtime,
    a.xact_start,
    a.query,
    a.wait_event_type,
    a.wait_event
   FROM pg_stat_activity a
  WHERE (a.backend_type = 'client backend'::text);


ALTER TABLE public.v_system_activity OWNER TO d3l243;

--
-- Name: TABLE v_system_activity; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_system_activity TO readaccess;

