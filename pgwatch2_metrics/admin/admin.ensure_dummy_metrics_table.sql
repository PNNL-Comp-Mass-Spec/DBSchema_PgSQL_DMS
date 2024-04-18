--
-- Name: ensure_dummy_metrics_table(text); Type: FUNCTION; Schema: admin; Owner: pgwatch2
--

CREATE OR REPLACE FUNCTION admin.ensure_dummy_metrics_table(metric text) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
  l_schema_type text;
  l_template_table text := 'admin.metrics_template';
  l_unlogged text := '';
BEGIN
  SELECT schema_type INTO l_schema_type FROM admin.storage_schema_type;

    IF NOT EXISTS (SELECT 1
                    FROM pg_tables
                    WHERE tablename = metric
                      AND schemaname = 'public')
    THEN
      IF metric ~ 'realtime' THEN
          l_template_table := 'admin.metrics_template_realtime';
          l_unlogged := 'UNLOGGED';
      END IF;

      IF l_schema_type = 'metric' THEN
        EXECUTE format($$CREATE %s TABLE public."%s" (LIKE %s INCLUDING INDEXES)$$, l_unlogged, metric, l_template_table);
      ELSIF l_schema_type = 'metric-time' THEN
        EXECUTE format($$CREATE %s TABLE public."%s" (LIKE %s INCLUDING INDEXES) PARTITION BY RANGE (time)$$, l_unlogged, metric, l_template_table);
      ELSIF l_schema_type = 'metric-dbname-time' THEN
        EXECUTE format($$CREATE %s TABLE public."%s" (LIKE %s INCLUDING INDEXES) PARTITION BY LIST (dbname)$$, l_unlogged, metric, l_template_table);
      ELSIF l_schema_type = 'timescale' THEN
          IF metric ~ 'realtime' THEN
              EXECUTE format($$CREATE TABLE public."%s" (LIKE %s INCLUDING INDEXES) PARTITION BY RANGE (time)$$, metric, l_template_table);
          ELSE
              PERFORM admin.ensure_partition_timescale(metric);
          END IF;
      END IF;

      EXECUTE format($$COMMENT ON TABLE public."%s" IS 'pgwatch2-generated-metric-lvl'$$, metric);

      RETURN true;

    END IF;

  RETURN false;
END;
$_$;


ALTER FUNCTION admin.ensure_dummy_metrics_table(metric text) OWNER TO pgwatch2;

