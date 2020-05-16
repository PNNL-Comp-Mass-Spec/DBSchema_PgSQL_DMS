--
-- Name: drop_old_time_partitions(integer, boolean); Type: FUNCTION; Schema: admin; Owner: d3l243
--

CREATE OR REPLACE FUNCTION admin.drop_old_time_partitions(older_than_days integer, dry_run boolean DEFAULT true) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  r record;
  i int := 0;
  l_schema_type text;
BEGIN

  SELECT schema_type INTO l_schema_type FROM admin.storage_schema_type;

  IF l_schema_type IN ('metric-time', 'metric-dbname-time') THEN

    FOR r IN (
      SELECT time_partition_name FROM (
        SELECT
            'subpartitions.' || quote_ident(c.relname) as time_partition_name,
            pg_catalog.pg_get_expr(c.relpartbound, c.oid) as limits,
            (regexp_match(pg_catalog.pg_get_expr(c.relpartbound, c.oid),
                E'TO \\((''.*?'')'))[1]::timestamp < (current_date  - '1day'::interval * (case when c.relname::text ~ 'realtime' then 0 else older_than_days end)) is_old
        FROM
            pg_class c
          JOIN
            pg_inherits i ON c.oid=i.inhrelid
            JOIN
            pg_namespace n ON n.oid = relnamespace
        WHERE
          c.relkind IN ('r', 'p')
            AND nspname = 'subpartitions'
            AND pg_catalog.obj_description(c.oid, 'pg_class') IN (
              'pgwatch2-generated-metric-time-lvl',
              'pgwatch2-generated-metric-dbname-time-lvl'
            )
        ) x
        WHERE is_old
        ORDER BY 1
    )
    LOOP
      if dry_run then
        raise notice 'would drop old time sub-partition: %', r.time_partition_name;
      else
        raise notice 'dropping old time sub-partition: %', r.time_partition_name;
        EXECUTE 'drop table ' || r.time_partition_name;
        i := i + 1;
      end if;
    END LOOP;

  ELSE
    raise warning 'unsupported schema type: %', l_schema_type;
  END IF;

  RETURN i;
END;
$$;


ALTER FUNCTION admin.drop_old_time_partitions(older_than_days integer, dry_run boolean) OWNER TO d3l243;

--
-- Name: FUNCTION drop_old_time_partitions(older_than_days integer, dry_run boolean); Type: ACL; Schema: admin; Owner: d3l243
--

GRANT ALL ON FUNCTION admin.drop_old_time_partitions(older_than_days integer, dry_run boolean) TO pgwatch2;

