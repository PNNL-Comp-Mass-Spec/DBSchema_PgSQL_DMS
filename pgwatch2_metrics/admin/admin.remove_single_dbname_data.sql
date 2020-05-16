--
-- Name: remove_single_dbname_data(text); Type: FUNCTION; Schema: admin; Owner: d3l243
--

CREATE OR REPLACE FUNCTION admin.remove_single_dbname_data(dbname text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE
  r record;
  i int := 0;
  j int;
  l_schema_type text;
BEGIN
  SELECT schema_type INTO l_schema_type FROM admin.storage_schema_type;
  
  IF l_schema_type IN ('metric', 'metric-time') THEN
    FOR r IN select * from admin.get_top_level_metric_tables()
    LOOP
      raise notice 'deleting data for %', r.table_name;
      EXECUTE format('DELETE FROM %s WHERE dbname = $1', r.table_name) USING dbname;
      GET DIAGNOSTICS j = ROW_COUNT;
      i := i + j;
    END LOOP;
  ELSIF l_schema_type = 'metric-dbname-time' THEN
    FOR r IN (
 select 'subpartitions.'|| quote_ident(c.relname) as table_name
                 from pg_class c
                join pg_namespace n on n.oid = c.relnamespace
                join pg_inherits i ON c.oid=i.inhrelid                
                join pg_class c2 on i.inhparent = c2.oid
                where c.relkind in ('r', 'p') and nspname = 'subpartitions'
                and exists (select 1 from pg_attribute where attrelid = c.oid and attname = 'time')
                and pg_catalog.obj_description(c.oid, 'pg_class') = 'pgwatch2-generated-metric-dbname-lvl'
                and (regexp_match(pg_catalog.pg_get_expr(c.relpartbound, c.oid), E'FOR VALUES IN \\(''(.*)''\\)'))[1] = dbname
                order by 1
    )
    LOOP
        raise notice 'dropping sub-partition % ...', r.table_name;
        EXECUTE 'drop table ' || r.table_name;
        GET DIAGNOSTICS j = ROW_COUNT;
        i := i + j;
    END LOOP;
  ELSE
    raise exception 'unsupported schema type: %', l_schema_type;
  END IF;
  
  EXECUTE 'delete from admin.all_distinct_dbname_metrics where dbname = $1' USING dbname;
  
  RETURN i;
END;
$_$;


ALTER FUNCTION admin.remove_single_dbname_data(dbname text) OWNER TO d3l243;

--
-- Name: FUNCTION remove_single_dbname_data(dbname text); Type: ACL; Schema: admin; Owner: d3l243
--

GRANT ALL ON FUNCTION admin.remove_single_dbname_data(dbname text) TO pgwatch2;

