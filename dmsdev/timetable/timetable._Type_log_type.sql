--
-- Name: log_type; Type: TYPE; Schema: timetable; Owner: d3l243
--

CREATE TYPE timetable.log_type AS ENUM (
    'DEBUG',
    'NOTICE',
    'INFO',
    'ERROR',
    'PANIC',
    'USER'
);


ALTER TYPE timetable.log_type OWNER TO d3l243;

