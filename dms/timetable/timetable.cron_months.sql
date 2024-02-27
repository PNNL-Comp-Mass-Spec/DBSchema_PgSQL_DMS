--
-- Name: cron_months(timestamp with time zone, integer[]); Type: FUNCTION; Schema: timetable; Owner: d3l243
--

CREATE OR REPLACE FUNCTION timetable.cron_months(from_ts timestamp with time zone, allowed_months integer[]) RETURNS SETOF timestamp with time zone
    LANGUAGE sql STRICT
    AS $$
    WITH
    am(am) AS (SELECT UNNEST(allowed_months)),
    genm(ts) AS ( --generated months
        SELECT date_trunc('month', ts)
        FROM pg_catalog.generate_series(from_ts, from_ts + INTERVAL '1 year', INTERVAL '1 month') g(ts)
    )
    SELECT ts FROM genm JOIN am ON date_part('month', genm.ts) = am.am
$$;


ALTER FUNCTION timetable.cron_months(from_ts timestamp with time zone, allowed_months integer[]) OWNER TO d3l243;

