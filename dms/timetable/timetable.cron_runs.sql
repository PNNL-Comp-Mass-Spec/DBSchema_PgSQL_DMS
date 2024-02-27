--
-- Name: cron_runs(timestamp with time zone, text); Type: FUNCTION; Schema: timetable; Owner: d3l243
--

CREATE OR REPLACE FUNCTION timetable.cron_runs(from_ts timestamp with time zone, cron text) RETURNS SETOF timestamp with time zone
    LANGUAGE sql STRICT
    AS $$
    SELECT cd + ct
    FROM
        timetable.cron_split_to_arrays(cron) a,
        timetable.cron_times(a.hours, a.mins) ct CROSS JOIN
        timetable.cron_days(from_ts, a.months, a.days, a.dow) cd
    WHERE cd + ct > from_ts
    ORDER BY 1 ASC;
$$;


ALTER FUNCTION timetable.cron_runs(from_ts timestamp with time zone, cron text) OWNER TO d3l243;

