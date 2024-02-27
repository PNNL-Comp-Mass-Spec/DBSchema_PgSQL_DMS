--
-- Name: is_cron_in_time(timetable.cron, timestamp with time zone); Type: FUNCTION; Schema: timetable; Owner: d3l243
--

CREATE OR REPLACE FUNCTION timetable.is_cron_in_time(run_at timetable.cron, ts timestamp with time zone) RETURNS boolean
    LANGUAGE sql
    AS $$
    SELECT
    CASE WHEN run_at IS NULL THEN
        TRUE
    ELSE
        date_part('month', ts) = ANY(a.months)
        AND (date_part('dow', ts) = ANY(a.dow) OR date_part('isodow', ts) = ANY(a.dow))
        AND date_part('day', ts) = ANY(a.days)
        AND date_part('hour', ts) = ANY(a.hours)
        AND date_part('minute', ts) = ANY(a.mins)
    END
    FROM
        timetable.cron_split_to_arrays(run_at) a
$$;


ALTER FUNCTION timetable.is_cron_in_time(run_at timetable.cron, ts timestamp with time zone) OWNER TO d3l243;

