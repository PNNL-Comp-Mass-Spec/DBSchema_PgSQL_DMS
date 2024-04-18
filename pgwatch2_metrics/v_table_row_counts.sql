--
-- Name: v_table_row_counts; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_table_row_counts AS
 SELECT (schema_name)::public.citext AS schema_name,
    (relname)::public.citext AS object_name,
        CASE relkind
            WHEN 'r'::public.citext THEN 'Table'::public.citext
            WHEN 'i'::public.citext THEN 'Index'::public.citext
            WHEN 'S'::public.citext THEN 'Sequence'::public.citext
            WHEN 't'::public.citext THEN 'TOAST table'::public.citext
            WHEN 'v'::public.citext THEN 'View'::public.citext
            WHEN 'm'::public.citext THEN 'Materialized View'::public.citext
            WHEN 'c'::public.citext THEN 'Composite Type'::public.citext
            WHEN 'f'::public.citext THEN 'Foreign Table'::public.citext
            WHEN 'p'::public.citext THEN 'Partitioned Table'::public.citext
            WHEN 'I'::public.citext THEN 'Partitioned Index'::public.citext
            ELSE relkind
        END AS object_type,
    table_row_count,
    pg_size_pretty(size_bytes) AS size,
    size_bytes,
        CASE
            WHEN (relkind OPERATOR(public.=) ANY (ARRAY['r'::public.citext, 't'::public.citext, 'f'::public.citext, 'p'::public.citext])) THEN (relname)::public.citext
            ELSE NULL::public.citext
        END AS table_name,
        CASE
            WHEN (relkind OPERATOR(public.=) ANY (ARRAY['v'::public.citext, 'm'::public.citext])) THEN (relname)::public.citext
            ELSE NULL::public.citext
        END AS view_name
   FROM ( SELECT pg_namespace.nspname AS schema_name,
            pg_class.relname,
            (pg_class.relkind)::public.citext AS relkind,
            pg_class.reltuples AS table_row_count,
            pg_relation_size((pg_class.oid)::regclass) AS size_bytes
           FROM (pg_class
             JOIN pg_namespace ON ((pg_class.relnamespace = pg_namespace.oid)))) t
  WHERE (schema_name !~~ 'pg_%'::text)
  ORDER BY size_bytes DESC;


ALTER VIEW public.v_table_row_counts OWNER TO d3l243;

--
-- Name: VIEW v_table_row_counts; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_table_row_counts IS 'Reports the number of rows and size (in bytes) of tables and views; row counts are an estimate, especially for large tables. Also includes sequences, views, and foreign tables, but row counts and sizes are meaningless for those objects';

