--
-- Name: drop_old_time_partitions(integer, boolean, text); Type: FUNCTION; Schema: admin; Owner: d3l243
--

CREATE OR REPLACE FUNCTION admin.drop_old_time_partitions(older_than_days integer, dry_run boolean DEFAULT true, schema_type text DEFAULT ''::text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE
  r record;
  r2 record;
  i int := 0;
BEGIN

  IF schema_type = '' THEN
    SELECT st.schema_type INTO schema_type FROM admin.storage_schema_type st;
  END IF;


  IF schema_type IN ('metric-time', 'metric-dbname-time') THEN

    FOR r IN (
      SELECT time_partition_name FROM (
        SELECT
            'subpartitions.' || quote_ident(c.relname) as time_partition_name,
            pg_catalog.pg_get_expr(c.relpartbound, c.oid) as limits,
            (regexp_match(pg_catalog.pg_get_expr(c.relpartbound, c.oid),
                E'TO \\((''.*?'')'))[1]::timestamp < (current_date  - '1day'::interval * (case when c.relname::text ~ '_realtime' then 0 else older_than_days end)) is_old
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

  ELSIF schema_type = 'timescale' THEN

        if dry_run then
            FOR r in (select * from (
                   select h.table_name                                  as                                                     metric,
                             format('%I.%I', c.schema_name, c.table_name)  as                                                     chunk,
                             pg_catalog.pg_get_constraintdef(co.oid, true) as                                                     limits,
                             (regexp_match(
                                     pg_catalog.pg_get_constraintdef(co.oid, true),
                                     $$ < '(.*)'$$)
                                 )[1]::timestamp < (current_date - '1day'::interval * older_than_days) is_old
                      from _timescaledb_catalog.hypertable h
                               join _timescaledb_catalog.chunk c on c.hypertable_id = h.id
                               join pg_catalog.pg_class cl on cl.relname = c.table_name
                               join pg_catalog.pg_namespace n on n.nspname = c.schema_name
                               join pg_catalog.pg_constraint co on co.conrelid = cl.oid
                      where h.schema_name = 'public'
            ) x where is_old)
            LOOP
                    raise notice 'would drop timescale old time sub-partition: %', r.chunk;
            END LOOP;

        else /* loop over all to level hypertables */
            FOR r IN (
                select
                  h.table_name::text as metric
                from
                  _timescaledb_catalog.hypertable h
                where
                  h.schema_name = 'public'
            )
            LOOP
                --raise notice 'dropping old timescale sub-partitions for hypertable: %', r.metric;
                IF (SELECT ((regexp_matches(extversion, '\d+\.\d+'))[1])::numeric FROM pg_extension WHERE extname = 'timescaledb') >= 2.0 THEN
                    FOR r2 in (select drop_chunks(r.metric, older_than_days * ' 1 day'::interval))
                    LOOP
                        i := i + 1;
                    END LOOP;
                ELSE
                    FOR r2 in (select drop_chunks(older_than_days * ' 1 day'::interval , r.metric))
                    LOOP
                        i := i + 1;
                    END LOOP;
                END IF;
            END LOOP;
        end if;

        -- as timescale doesn't support unlogged tables we need to use still PG native partitions for realtime metrics
        PERFORM admin.drop_old_time_partitions(older_than_days, dry_run, 'metric-time');

  ELSE
    raise warning 'unsupported schema type: %', l_schema_type;
  END IF;

  RETURN i;
END;
$_$;


ALTER FUNCTION admin.drop_old_time_partitions(older_than_days integer, dry_run boolean, schema_type text) OWNER TO d3l243;

--
-- Name: FUNCTION drop_old_time_partitions(older_than_days integer, dry_run boolean, schema_type text); Type: ACL; Schema: admin; Owner: d3l243
--

GRANT ALL ON FUNCTION admin.drop_old_time_partitions(older_than_days integer, dry_run boolean, schema_type text) TO pgwatch2;

