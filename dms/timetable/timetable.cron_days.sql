--
-- Name: cron_days(timestamp with time zone, integer[], integer[], integer[]); Type: FUNCTION; Schema: timetable; Owner: d3l243
--

CREATE OR REPLACE FUNCTION timetable.cron_days(from_ts timestamp with time zone, allowed_months integer[], allowed_days integer[], allowed_week_days integer[]) RETURNS SETOF timestamp with time zone
    LANGUAGE sql STRICT
    AS $$
    WITH
    ad(ad) AS (SELECT UNNEST(allowed_days)),
    am(am) AS (SELECT * FROM timetable.cron_months(from_ts, allowed_months)),
    gend(ts) AS ( --generated days
        SELECT date_trunc('day', ts)
        FROM am,
            pg_catalog.generate_series(am.am, am.am + INTERVAL '1 month'
                - INTERVAL '1 day',  -- don't include the same day of the next month
                INTERVAL '1 day') g(ts)
    )
    SELECT ts
    FROM gend JOIN ad ON date_part('day', gend.ts) = ad.ad
    WHERE extract(dow from ts)=ANY(allowed_week_days)
$$;


ALTER FUNCTION timetable.cron_days(from_ts timestamp with time zone, allowed_months integer[], allowed_days integer[], allowed_week_days integer[]) OWNER TO d3l243;

