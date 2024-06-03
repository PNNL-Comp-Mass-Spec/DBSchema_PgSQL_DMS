--
-- Name: v_table_index_usage; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_table_index_usage AS
 WITH lookupq AS (
         SELECT pg_stat_all_indexes.schemaname AS schema_name,
            pg_stat_all_indexes.relname AS table_name,
            pg_stat_all_indexes.indexrelname AS index_name,
            ((pg_stat_all_indexes.idx_scan + pg_stat_all_indexes.idx_tup_read) + pg_stat_all_indexes.idx_tup_fetch) AS idx_usage,
            pg_stat_all_indexes.idx_scan,
            pg_stat_all_indexes.idx_tup_read,
            pg_stat_all_indexes.idx_tup_fetch,
            pg_relation_size((pg_stat_all_indexes.indexrelid)::regclass) AS size_bytes
           FROM pg_stat_all_indexes
          WHERE ((NOT (pg_stat_all_indexes.schemaname = ANY (ARRAY['pg_catalog'::name, 'pg_toast'::name]))) AND (NOT (pg_stat_all_indexes.schemaname ~ similar_to_escape('pg[_]%temp[_]%'::text))))
        )
 SELECT (lookupq.schema_name)::public.citext AS schema_name,
    (lookupq.table_name)::public.citext AS table_name,
    (lookupq.index_name)::public.citext AS index_name,
    lookupq.idx_usage,
    lookupq.idx_scan,
    lookupq.idx_tup_read,
    lookupq.idx_tup_fetch,
    pg_size_pretty(lookupq.size_bytes) AS size,
    lookupq.size_bytes,
    sumq.table_idx_size_sum
   FROM (lookupq
     JOIN ( SELECT lookupq_1.schema_name,
            lookupq_1.table_name,
            lookupq_1.index_name,
            pg_size_pretty(sum(lookupq_1.size_bytes) OVER (PARTITION BY lookupq_1.schema_name, lookupq_1.table_name)) AS table_idx_size_sum
           FROM lookupq lookupq_1) sumq ON (((lookupq.schema_name = sumq.schema_name) AND (lookupq.table_name = sumq.table_name) AND (lookupq.index_name = sumq.index_name))))
  ORDER BY lookupq.idx_usage DESC, (lookupq.schema_name)::public.citext, (lookupq.table_name)::public.citext;


ALTER VIEW public.v_table_index_usage OWNER TO d3l243;

--
-- Name: TABLE v_table_index_usage; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_table_index_usage TO readaccess;
GRANT SELECT ON TABLE public.v_table_index_usage TO writeaccess;

