--
-- Name: command_kind; Type: TYPE; Schema: timetable; Owner: d3l243
--

CREATE TYPE timetable.command_kind AS ENUM (
    'SQL',
    'PROGRAM',
    'BUILTIN'
);


ALTER TYPE timetable.command_kind OWNER TO d3l243;

