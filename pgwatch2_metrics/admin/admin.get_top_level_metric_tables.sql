--
-- Name: get_top_level_metric_tables(); Type: FUNCTION; Schema: admin; Owner: d3l243
--

CREATE OR REPLACE FUNCTION admin.get_top_level_metric_tables(OUT table_name text) RETURNS SETOF text
    LANGUAGE sql
    AS $$
  select nspname||'.'||quote_ident(c.relname) as tbl
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where relkind in ('r', 'p') and nspname = 'public'
  and exists (select 1 from pg_attribute where attrelid = c.oid and attname = 'time')
  and pg_catalog.obj_description(c.oid, 'pg_class') = 'pgwatch2-generated-metric-lvl'
  order by 1
$$;


ALTER FUNCTION admin.get_top_level_metric_tables(OUT table_name text) OWNER TO d3l243;

--
-- Name: FUNCTION get_top_level_metric_tables(OUT table_name text); Type: ACL; Schema: admin; Owner: d3l243
--

GRANT ALL ON FUNCTION admin.get_top_level_metric_tables(OUT table_name text) TO pgwatch2;

