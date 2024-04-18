--
-- Name: ensure_partition_metric_time(text, timestamp with time zone, integer); Type: FUNCTION; Schema: admin; Owner: d3l243
--

CREATE OR REPLACE FUNCTION admin.ensure_partition_metric_time(metric text, metric_timestamp timestamp with time zone, partitions_to_precreate integer DEFAULT 0, OUT part_available_from timestamp with time zone, OUT part_available_to timestamp with time zone) RETURNS record
    LANGUAGE plpgsql
    AS $_$
DECLARE
  l_year int;
  l_week int;
  l_doy int;
  l_part_name text;
  l_part_start date;
  l_part_end date;
  l_sql text;
  l_template_table text := 'admin.metrics_template';
  l_unlogged text := '';
BEGIN

  PERFORM pg_advisory_xact_lock(regexp_replace( md5(metric) , E'\\D', '', 'g')::varchar(10)::int8);

  IF metric ~ 'realtime' THEN
      l_template_table := 'admin.metrics_template_realtime';
      l_unlogged := 'UNLOGGED';
  END IF;

  IF NOT EXISTS (SELECT 1
                   FROM pg_tables
                  WHERE tablename = metric
                    AND schemaname = 'public')
  THEN
    --RAISE NOTICE 'creating top level metrics partition % ...', metric;
    l_sql := format($$CREATE %s TABLE IF NOT EXISTS public.%s (LIKE %s INCLUDING INDEXES) PARTITION BY RANGE (time)$$,
                    l_unlogged, quote_ident(metric), l_template_table);
    EXECUTE l_sql;
    EXECUTE format($$COMMENT ON TABLE public.%s IS 'pgwatch2-generated-metric-lvl'$$, quote_ident(metric));
  END IF;

  FOR i IN 0..partitions_to_precreate LOOP

    IF l_unlogged > '' THEN     /* realtime / unlogged metrics have always 1d partitions */
        l_year := extract(year from (metric_timestamp + '1day'::interval * i));
        l_doy := extract(doy from (metric_timestamp + '1day'::interval * i));

        l_part_name := format('%s_y%sd%s', metric, l_year, to_char(l_doy, 'fm000'));

        IF i = 0 THEN
            l_part_start := to_date(l_year::text || to_char(l_doy, 'fm000'), 'YYYYDDD');
            l_part_end := l_part_start + '1day'::interval;
            part_available_from := l_part_start;
            part_available_to := l_part_end;
        ELSE
            l_part_start := l_part_start + '1day'::interval;
            l_part_end := l_part_start + '1day'::interval;
            part_available_to := l_part_end;
        END IF;
    ELSE
      l_year := extract(isoyear from (metric_timestamp + '1week'::interval * i));
      l_week := extract(week from (metric_timestamp + '1week'::interval * i));

      l_part_name := format('%s_y%sw%s', metric, l_year, to_char(l_week, 'fm00' ));

      IF i = 0 THEN
          l_part_start := to_date(l_year::text || l_week::text, 'iyyyiw');
          l_part_end := l_part_start + '1week'::interval;
          part_available_from := l_part_start;
          part_available_to := l_part_end;
      ELSE
          l_part_start := l_part_start + '1week'::interval;
          l_part_end := l_part_start + '1week'::interval;
          part_available_to := l_part_end;
      END IF;
    END IF;

  IF NOT EXISTS (SELECT 1
                   FROM pg_tables
                  WHERE tablename = l_part_name
                    AND schemaname = 'subpartitions')
  THEN
    --RAISE NOTICE 'creating sub-partition % ...', l_part_name;
    l_sql := format($$CREATE %s TABLE IF NOT EXISTS subpartitions.%s PARTITION OF public.%s FOR VALUES FROM ('%s') TO ('%s')$$,
                    l_unlogged, quote_ident(l_part_name), quote_ident(metric), l_part_start, l_part_end);
    EXECUTE l_sql;
    EXECUTE format($$COMMENT ON TABLE subpartitions.%s IS 'pgwatch2-generated-metric-time-lvl'$$, quote_ident(l_part_name));
  END IF;

  END LOOP;


END;
$_$;


ALTER FUNCTION admin.ensure_partition_metric_time(metric text, metric_timestamp timestamp with time zone, partitions_to_precreate integer, OUT part_available_from timestamp with time zone, OUT part_available_to timestamp with time zone) OWNER TO d3l243;

--
-- Name: FUNCTION ensure_partition_metric_time(metric text, metric_timestamp timestamp with time zone, partitions_to_precreate integer, OUT part_available_from timestamp with time zone, OUT part_available_to timestamp with time zone); Type: ACL; Schema: admin; Owner: d3l243
--

GRANT ALL ON FUNCTION admin.ensure_partition_metric_time(metric text, metric_timestamp timestamp with time zone, partitions_to_precreate integer, OUT part_available_from timestamp with time zone, OUT part_available_to timestamp with time zone) TO pgwatch2;

