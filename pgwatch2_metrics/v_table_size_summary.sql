--
-- Name: v_table_size_summary; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_table_size_summary AS
 SELECT (table_schema)::public.citext AS schema_name,
    (table_name)::public.citext AS table_name,
    table_row_count,
    pg_size_pretty(size_bytes) AS size,
    size_bytes,
    index_count,
    has_unique_idx,
    single_column_idx,
    multi_column_idx,
    has_triggers
   FROM ( SELECT pg_namespace.nspname AS table_schema,
            pg_class.relname AS table_name,
            pg_class.reltuples AS table_row_count,
            ((pg_class.relpages * (8)::bigint) * 1024) AS size_bytes,
            count(lookpuq.indexname) AS index_count,
                CASE
                    WHEN (x.is_unique = 1) THEN 'Y'::text
                    ELSE 'N'::text
                END AS has_unique_idx,
            sum(
                CASE
                    WHEN (lookpuq.number_of_columns = 1) THEN 1
                    ELSE 0
                END) AS single_column_idx,
            sum(
                CASE
                    WHEN (lookpuq.number_of_columns IS NULL) THEN 0
                    WHEN (lookpuq.number_of_columns = 1) THEN 0
                    ELSE 1
                END) AS multi_column_idx,
            pg_class.relhastriggers AS has_triggers
           FROM (((pg_namespace
             LEFT JOIN pg_class ON ((pg_namespace.oid = pg_class.relnamespace)))
             LEFT JOIN ( SELECT pg_index.indrelid,
                    max((pg_index.indisunique)::integer) AS is_unique
                   FROM pg_index
                  GROUP BY pg_index.indrelid) x ON ((pg_class.oid = x.indrelid)))
             LEFT JOIN ( SELECT c.relname AS ctablename,
                    ipg.relname AS indexname,
                    x_1.indnatts AS number_of_columns
                   FROM ((pg_index x_1
                     JOIN pg_class c ON ((c.oid = x_1.indrelid)))
                     JOIN pg_class ipg ON ((ipg.oid = x_1.indexrelid)))) lookpuq ON ((pg_class.relname = lookpuq.ctablename)))
          WHERE ((NOT (pg_namespace.nspname = ANY (ARRAY['information_schema'::name, 'pg_catalog'::name]))) AND (NOT (pg_namespace.nspname ~ similar_escape('pg[_]%temp[_]%'::text, NULL::text))) AND (pg_class.relkind = ANY (ARRAY['r'::"char", 'm'::"char", 'f'::"char", 'p'::"char"])))
          GROUP BY pg_namespace.nspname, pg_class.relname, pg_class.reltuples, pg_class.relpages, x.is_unique, pg_class.relhastriggers) statsq
  ORDER BY size_bytes DESC;


ALTER VIEW public.v_table_size_summary OWNER TO d3l243;

--
-- Name: VIEW v_table_size_summary; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_table_size_summary IS 'Reports the rows and size (in bytes) of tables; row counts are an estimate, especially for large tables. Also includes information on indexes defined for each table. Includes foreign tables, but row counts and sizes are meaningless for those objects';

