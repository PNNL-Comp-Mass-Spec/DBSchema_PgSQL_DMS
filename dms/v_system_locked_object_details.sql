--
-- Name: v_system_locked_object_details; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_system_locked_object_details AS
 SELECT a.pid,
    a.datname AS database,
    a.usename AS username,
    a.application_name,
    a.state,
    c.relname AS object_name,
    l.locktype,
    l.mode,
    l.granted,
    l.fastpath,
    l.waitstart,
    a.query_start,
    (now() - a.query_start) AS query_runtime,
    a.xact_start,
    a.query,
    a.wait_event_type,
    a.wait_event
   FROM ((pg_stat_activity a
     JOIN pg_locks l ON ((a.pid = l.pid)))
     JOIN pg_class c ON ((l.relation = c.oid)));


ALTER TABLE public.v_system_locked_object_details OWNER TO d3l243;

--
-- Name: TABLE v_system_locked_object_details; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_system_locked_object_details TO readaccess;
GRANT SELECT ON TABLE public.v_system_locked_object_details TO writeaccess;

