--
-- Name: v_table_row_counts; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_table_row_counts AS
 SELECT pg_namespace.nspname AS table_schema,
    pg_class.relname AS table_name,
    pg_class.reltuples AS table_row_count,
    (pg_class.relpages * 8) AS table_size_bytes,
    pg_size_pretty(((pg_class.relpages)::bigint * 8)) AS table_size
   FROM (pg_namespace
     LEFT JOIN pg_class ON ((pg_namespace.oid = pg_class.relnamespace)))
  WHERE ((NOT (pg_namespace.nspname = ANY (ARRAY['information_schema'::name, 'pg_catalog'::name]))) AND (NOT (pg_namespace.nspname ~ similar_escape('pg[_]%temp[_]%'::text, NULL::text))) AND (pg_class.relkind = 'r'::"char"))
  ORDER BY pg_namespace.nspname, pg_class.relname;


ALTER TABLE public.v_table_row_counts OWNER TO d3l243;

