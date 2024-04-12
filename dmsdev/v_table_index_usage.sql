--
-- Name: v_table_index_usage; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_table_index_usage AS
 SELECT (schema_name)::public.citext AS schema_name,
    (table_name)::public.citext AS table_name,
    (index_name)::public.citext AS index_name,
    idx_usage,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch,
    pg_size_pretty(size_bytes) AS size,
    size_bytes
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
  ORDER BY idx_usage DESC, schema_name, table_name;


ALTER VIEW public.v_table_index_usage OWNER TO d3l243;

--
-- Name: TABLE v_table_index_usage; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_table_index_usage TO readaccess;
GRANT SELECT ON TABLE public.v_table_index_usage TO writeaccess;

