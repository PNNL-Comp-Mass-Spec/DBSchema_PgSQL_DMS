--
-- Name: get_old_time_partitions(integer, text); Type: FUNCTION; Schema: admin; Owner: d3l243
--

CREATE OR REPLACE FUNCTION admin.get_old_time_partitions(older_than_days integer, schema_type text DEFAULT ''::text) RETURNS SETOF text
    LANGUAGE plpgsql
    AS $$
BEGIN

    IF schema_type = '' THEN
        SELECT st.schema_type INTO schema_type FROM admin.storage_schema_type st;
    END IF;

    IF schema_type IN ('metric-time', 'metric-dbname-time') THEN

        RETURN QUERY
            SELECT time_partition_name FROM (
                SELECT
                    'subpartitions.' || quote_ident(c.relname) as time_partition_name,
                    pg_catalog.pg_get_expr(c.relpartbound, c.oid) as limits,
                    (regexp_match(pg_catalog.pg_get_expr(c.relpartbound, c.oid),
                        E'TO \\((''.*?'')'))[1]::timestamp < (
                            current_date  - '1day'::interval * (case when c.relname::text ~ '_realtime' then 0 else older_than_days end)
                        ) is_old
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
            ORDER BY 1;
    ELSE
        RAISE EXCEPTION 'only metric-time and metric-dbname-time partitioning schemas supported currently!';
    END IF;

END;
$$;


ALTER FUNCTION admin.get_old_time_partitions(older_than_days integer, schema_type text) OWNER TO d3l243;

--
-- Name: FUNCTION get_old_time_partitions(older_than_days integer, schema_type text); Type: ACL; Schema: admin; Owner: d3l243
--

GRANT ALL ON FUNCTION admin.get_old_time_partitions(older_than_days integer, schema_type text) TO pgwatch2;

