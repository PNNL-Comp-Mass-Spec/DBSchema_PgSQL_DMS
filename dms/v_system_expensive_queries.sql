--
-- Name: v_system_expensive_queries; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_system_expensive_queries AS
 SELECT round(((((100)::double precision * ss.total_exec_time) / sum(ss.total_exec_time) OVER ()))::numeric, 2) AS percent,
    round((ss.total_exec_time)::numeric, 2) AS total_exec_time,
    ss.calls,
    round((ss.mean_exec_time)::numeric, 2) AS mean_exec_time,
    "substring"(ss.query, 1, 200) AS query_excerpt,
    ss.queryid
   FROM public.pg_stat_statements ss
  ORDER BY ss.total_exec_time DESC
 LIMIT 500;


ALTER TABLE public.v_system_expensive_queries OWNER TO d3l243;

--
-- Name: VIEW v_system_expensive_queries; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_system_expensive_queries IS 'Lists the top 500 most expensive queries (lots of calls and/or high cumulative runtime)';

--
-- Name: TABLE v_system_expensive_queries; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_system_expensive_queries TO readaccess;
GRANT SELECT ON TABLE public.v_system_expensive_queries TO writeaccess;

