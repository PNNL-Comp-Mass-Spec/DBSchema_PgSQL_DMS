--
-- Name: v_table_index_sizes; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_table_index_sizes AS
 SELECT (statsq.schema_name)::public.citext AS schema_name,
    (statsq.table_name)::public.citext AS table_name,
    (statsq.index_name)::public.citext AS index_name,
    statsq.num_rows,
    pg_size_pretty(statsq.table_size_bytes) AS table_size,
    pg_size_pretty(statsq.index_size_bytes) AS index_size,
    statsq.unique_idx,
    statsq.number_of_scans,
    statsq.tuples_read,
    statsq.tuples_fetched,
    statsq.table_size_bytes,
    statsq.index_size_bytes
   FROM ( SELECT t.schemaname AS schema_name,
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
          WHERE ((t.schemaname <> ALL (ARRAY['pg_catalog'::name, 'information_schema'::name])) AND (NOT (t.schemaname ~ similar_escape('pg[_]%temp[_]%'::text, NULL::text))))) statsq
  ORDER BY statsq.schema_name, statsq.table_name, statsq.index_name;


ALTER TABLE public.v_table_index_sizes OWNER TO d3l243;

--
-- Name: TABLE v_table_index_sizes; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_table_index_sizes TO readaccess;
GRANT SELECT ON TABLE public.v_table_index_sizes TO writeaccess;

