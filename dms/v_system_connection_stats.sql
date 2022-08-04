--
-- Name: v_system_connection_stats; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_system_connection_stats AS
 SELECT pg_stat_activity.datname AS database,
    count(*) AS open,
    count(*) FILTER (WHERE (pg_stat_activity.state = 'active'::text)) AS active,
    count(*) FILTER (WHERE (pg_stat_activity.state = 'idle'::text)) AS idle,
    count(*) FILTER (WHERE (pg_stat_activity.state = 'idle in transaction'::text)) AS idle_in_transaction
   FROM pg_stat_activity
  WHERE (pg_stat_activity.backend_type = 'client backend'::text)
  GROUP BY ROLLUP(pg_stat_activity.datname);


ALTER TABLE public.v_system_connection_stats OWNER TO d3l243;

--
-- Name: VIEW v_system_connection_stats; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_system_connection_stats IS 'Connection stats, by database; also includes a row with totals for all databases';

--
-- Name: TABLE v_system_connection_stats; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_system_connection_stats TO readaccess;

