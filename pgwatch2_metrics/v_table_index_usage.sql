--
-- Name: v_table_index_usage; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_table_index_usage AS
 SELECT pg_stat_all_indexes.schemaname AS schema_name,
    pg_stat_all_indexes.relname AS table_name,
    pg_stat_all_indexes.indexrelname AS index_name,
    ((pg_stat_all_indexes.idx_scan + pg_stat_all_indexes.idx_tup_read) + pg_stat_all_indexes.idx_tup_fetch) AS idx_usage,
    pg_stat_all_indexes.idx_scan,
    pg_stat_all_indexes.idx_tup_read,
    pg_stat_all_indexes.idx_tup_fetch,
    pg_relation_size((pg_stat_all_indexes.indexrelid)::regclass) AS index_size_bytes
   FROM pg_stat_all_indexes
  WHERE ((NOT (pg_stat_all_indexes.schemaname = ANY (ARRAY['pg_catalog'::name, 'pg_toast'::name]))) AND (NOT (pg_stat_all_indexes.schemaname ~ similar_escape('pg[_]%temp[_]%'::text, NULL::text))))
  ORDER BY ((pg_stat_all_indexes.idx_scan + pg_stat_all_indexes.idx_tup_read) + pg_stat_all_indexes.idx_tup_fetch) DESC, pg_stat_all_indexes.schemaname, pg_stat_all_indexes.relname;


ALTER TABLE public.v_table_index_usage OWNER TO d3l243;

