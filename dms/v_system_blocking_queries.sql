--
-- Name: v_system_blocking_queries; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_system_blocking_queries AS
 SELECT a.pid,
    a.datname AS database,
    a.usename AS "user",
    a.application_name,
    a.state,
    a.query_start,
    a.query,
    b.pid AS blocking_id,
    b.query AS blocking_query
   FROM (pg_stat_activity a
     JOIN pg_stat_activity b ON ((b.pid = ANY (pg_blocking_pids(a.pid)))));


ALTER TABLE public.v_system_blocking_queries OWNER TO d3l243;

--
-- Name: TABLE v_system_blocking_queries; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_system_blocking_queries TO readaccess;

