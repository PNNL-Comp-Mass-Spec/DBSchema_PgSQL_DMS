--
-- Name: cron_times(integer[], integer[]); Type: FUNCTION; Schema: timetable; Owner: d3l243
--

CREATE OR REPLACE FUNCTION timetable.cron_times(allowed_hours integer[], allowed_minutes integer[]) RETURNS SETOF time without time zone
    LANGUAGE sql STRICT
    AS $$
    WITH
    ah(ah) AS (SELECT UNNEST(allowed_hours)),
    am(am) AS (SELECT UNNEST(allowed_minutes))
    SELECT make_time(ah.ah, am.am, 0) FROM ah CROSS JOIN am
$$;


ALTER FUNCTION timetable.cron_times(allowed_hours integer[], allowed_minutes integer[]) OWNER TO d3l243;

