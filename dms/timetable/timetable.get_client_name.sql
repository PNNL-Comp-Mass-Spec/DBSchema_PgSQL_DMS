--
-- Name: get_client_name(integer); Type: FUNCTION; Schema: timetable; Owner: d3l243
--

CREATE OR REPLACE FUNCTION timetable.get_client_name(integer) RETURNS text
    LANGUAGE sql
    AS $_$
    SELECT client_name FROM timetable.active_session WHERE server_pid = $1 LIMIT 1
$_$;


ALTER FUNCTION timetable.get_client_name(integer) OWNER TO d3l243;

