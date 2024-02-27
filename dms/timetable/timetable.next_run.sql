--
-- Name: next_run(timetable.cron); Type: FUNCTION; Schema: timetable; Owner: d3l243
--

CREATE OR REPLACE FUNCTION timetable.next_run(cron timetable.cron) RETURNS timestamp with time zone
    LANGUAGE sql STRICT
    AS $$
    SELECT * FROM timetable.cron_runs(now(), cron) LIMIT 1
$$;


ALTER FUNCTION timetable.next_run(cron timetable.cron) OWNER TO d3l243;

