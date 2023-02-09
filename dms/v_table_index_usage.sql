--
-- Name: v_table_index_usage; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_table_index_usage AS
 SELECT (statsq.schema_name)::public.citext AS schema_name,
    (statsq.table_name)::public.citext AS table_name,
    (statsq.index_name)::public.citext AS index_name,
    statsq.idx_usage,
    statsq.idx_scan,
    statsq.idx_tup_read,
    statsq.idx_tup_fetch,
    pg_size_pretty(statsq.size_bytes) AS size,
    statsq.size_bytes
   FROM ( SELECT pg_stat_all_indexes.schemaname AS schema_name,
            pg_stat_all_indexes.relname AS table_name,
            pg_stat_all_indexes.indexrelname AS index_name,
            ((pg_stat_all_indexes.idx_scan + pg_stat_all_indexes.idx_tup_read) + pg_stat_all_indexes.idx_tup_fetch) AS idx_usage,
            pg_stat_all_indexes.idx_scan,
            pg_stat_all_indexes.idx_tup_read,
            pg_stat_all_indexes.idx_tup_fetch,
            pg_relation_size((pg_stat_all_indexes.indexrelid)::regclass) AS size_bytes
           FROM pg_stat_all_indexes
          WHERE ((NOT (pg_stat_all_indexes.schemaname = ANY (ARRAY['pg_catalog'::name, 'pg_toast'::name]))) AND (NOT (pg_stat_all_indexes.schemaname ~ similar_escape('pg[_]%temp[_]%'::text, NULL::text))))) statsq
  ORDER BY statsq.idx_usage DESC, statsq.schema_name, statsq.table_name;


ALTER TABLE public.v_table_index_usage OWNER TO d3l243;

--
-- Name: TABLE v_table_index_usage; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_table_index_usage TO readaccess;
GRANT SELECT ON TABLE public.v_table_index_usage TO writeaccess;

