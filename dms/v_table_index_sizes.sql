--
-- Name: v_table_index_sizes; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_table_index_sizes AS
 SELECT (indexq.schema_name)::public.citext AS schema_name,
    (indexq.table_name)::public.citext AS table_name,
    (indexq.index_name)::public.citext AS index_name,
    indexq.num_rows AS index_row_count,
    tableq.table_row_count,
    pg_size_pretty(indexq.index_size_bytes) AS index_size,
    pg_size_pretty(indexq.table_size_bytes) AS table_size,
    indexq.unique_idx,
    indexq.number_of_scans,
    indexq.tuples_read,
    indexq.tuples_fetched,
    indexq.index_size_bytes,
    indexq.table_size_bytes
   FROM (( SELECT t.schemaname AS schema_name,
            t.tablename AS table_name,
            lookupq.indexname AS index_name,
            c.reltuples AS num_rows,
            pg_relation_size((((quote_ident((t.schemaname)::text) || '.'::text) || quote_ident((t.tablename)::text)))::regclass) AS table_size_bytes,
            pg_relation_size((((quote_ident((t.schemaname)::text) || '.'::text) || quote_ident((lookupq.indexrelname)::text)))::regclass) AS index_size_bytes,
                CASE
                    WHEN lookupq.indisunique THEN 'Y'::text
                    ELSE 'N'::text
                END AS unique_idx,
            lookupq.number_of_scans,
            lookupq.tuples_read,
            lookupq.tuples_fetched
           FROM ((pg_tables t
             LEFT JOIN pg_class c ON ((t.tablename = c.relname)))
             LEFT JOIN ( SELECT c_1.relname AS ctablename,
                    ipg.relname AS indexname,
                    x.indnatts AS number_of_columns,
                    psai.idx_scan AS number_of_scans,
                    psai.idx_tup_read AS tuples_read,
                    psai.idx_tup_fetch AS tuples_fetched,
                    psai.indexrelname,
                    x.indisunique,
                    psai.schemaname
                   FROM (((pg_index x
                     JOIN pg_class c_1 ON ((c_1.oid = x.indrelid)))
                     JOIN pg_class ipg ON ((ipg.oid = x.indexrelid)))
                     JOIN pg_stat_all_indexes psai ON ((x.indexrelid = psai.indexrelid)))) lookupq ON (((t.tablename = lookupq.ctablename) AND (t.schemaname = lookupq.schemaname))))
          WHERE ((t.schemaname <> ALL (ARRAY['pg_catalog'::name, 'information_schema'::name])) AND (NOT (t.schemaname ~ similar_escape('pg[_]%temp[_]%'::text, NULL::text))))) indexq
     LEFT JOIN ( SELECT pg_namespace.nspname AS table_schema,
            pg_class.relname AS table_name,
            pg_class.reltuples AS table_row_count
           FROM (pg_namespace
             JOIN pg_class ON ((pg_namespace.oid = pg_class.relnamespace)))
          WHERE ((NOT (pg_namespace.nspname = ANY (ARRAY['information_schema'::name, 'pg_catalog'::name]))) AND (NOT (pg_namespace.nspname ~ similar_escape('pg[_]%temp[_]%'::text, NULL::text))) AND (pg_class.relkind = ANY (ARRAY['r'::"char", 'm'::"char", 'f'::"char", 'p'::"char"])))) tableq ON (((tableq.table_schema = indexq.schema_name) AND (tableq.table_name = indexq.table_name))))
  ORDER BY indexq.schema_name, indexq.table_name, indexq.index_name;


ALTER VIEW public.v_table_index_sizes OWNER TO d3l243;

--
-- Name: TABLE v_table_index_sizes; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_table_index_sizes TO readaccess;
GRANT SELECT ON TABLE public.v_table_index_sizes TO writeaccess;

