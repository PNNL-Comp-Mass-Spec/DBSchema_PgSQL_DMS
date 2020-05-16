--
-- Name: truncate_all_metric_tables(); Type: FUNCTION; Schema: admin; Owner: d3l243
--

CREATE OR REPLACE FUNCTION admin.truncate_all_metric_tables() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  r record;
  i int := 0;
BEGIN
  FOR r IN select * from admin.get_top_level_metric_tables()
  LOOP
    raise notice 'dropping %', r.table_name;
    EXECUTE 'TRUNCATE TABLE ' || r.table_name;
    i := i + 1;
  END LOOP;
  
  EXECUTE 'truncate admin.all_distinct_dbname_metrics';
  
  RETURN i;
END;
$$;


ALTER FUNCTION admin.truncate_all_metric_tables() OWNER TO d3l243;

--
-- Name: FUNCTION truncate_all_metric_tables(); Type: ACL; Schema: admin; Owner: d3l243
--

GRANT ALL ON FUNCTION admin.truncate_all_metric_tables() TO pgwatch2;

