--
-- Name: udf_timestamp_text(timestamp without time zone); Type: FUNCTION; Schema: public; Owner: d3l243
--
-- Overload 1

CREATE FUNCTION public.udf_timestamp_text(_currenttime timestamp without time zone) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**  Returns a time stamp for the value specified by the _currentTime argument
**  The time stamp will be in the form: 2020-01-09 15:12:18
**
**  There are two udf_timestamp_text functions; this one accepts a timestamp that does not have a timezone
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

--
-- Name: udf_timestamp_text(timestamp with time zone); Type: FUNCTION; Schema: public; Owner: d3l243
--
-- Overload 2

CREATE FUNCTION public.udf_timestamp_text(_currenttime timestamp with time zone) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**  Returns a time stamp for the value specified by the _currentTime argument
**  The time stamp will be in the form: 2020-01-09 15:12:18
*
**  There are two udf_timestamp_text functions; this one accepts a timestamp with a timezone
**
**  To get the current time, use either
**      SELECT udf_timestamp_text(localtimestamp);
**  or
**      SELECT udf_timestamp_text(current_timestamp);
**
**  Auth: mem
**  Date: 01/14/2020
*****************************************************/

BEGIN
    RETURN to_char(_currentTime::timestamp, 'YYYY-MM-DD HH24:MI:SS');
END
$$;


ALTER FUNCTION public.udf_timestamp_text(_currenttime timestamp with time zone) OWNER TO d3l243;

