--
-- Name: v_table_row_counts; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_table_row_counts AS
 SELECT t.schema_name,
    t.relname AS object_name,
        CASE t.relkind
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
            ELSE t.relkind
        END AS object_type,
    pg_size_pretty(t.size_bytes) AS size,
    t.size_bytes
   FROM ( SELECT pg_namespace.nspname AS schema_name,
            pg_class.relname,
            (pg_class.relkind)::public.citext AS relkind,
            pg_class.reltuples AS table_row_count,
            pg_relation_size((pg_class.oid)::regclass) AS size_bytes
           FROM (pg_class
             JOIN pg_namespace ON ((pg_class.relnamespace = pg_namespace.oid)))) t
  WHERE (t.schema_name !~~ 'pg_%'::text)
  ORDER BY t.size_bytes DESC;


ALTER TABLE public.v_table_row_counts OWNER TO d3l243;

--
-- Name: TABLE v_table_row_counts; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_table_row_counts TO readaccess;

