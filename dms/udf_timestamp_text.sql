--
-- Name: udf_timestamp_text(timestamp without time zone); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE FUNCTION public.udf_timestamp_text(_currenttime timestamp without time zone) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**  Returns a time stamp for the value specified by the currentTime argument
**  The time stamp will be in the form: 2020-01-09 15:12:18
**
**  To get the current time, use either
**      SELECT udf_timestamp_text(localtimestamp);
**  or
**      SELECT udf_timestamp_text(current_timestamp::timestamp);
**
**  Auth: mem
**  Date: 01/09/2020
*****************************************************/

BEGIN
    RETURN to_char(_currentTime, 'YYYY-MM-DD HH24:MI:SS');
END
$$;


ALTER FUNCTION public.udf_timestamp_text(_currenttime timestamp without time zone) OWNER TO d3l243;
