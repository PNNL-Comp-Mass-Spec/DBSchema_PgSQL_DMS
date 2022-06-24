--
-- Name: timestamp_text(timestamp without time zone); Type: FUNCTION; Schema: public; Owner: d3l243
--
-- Overload 1

CREATE OR REPLACE FUNCTION public.timestamp_text(_currenttime timestamp without time zone) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns a text representation for the value specified by the _currentTime argument
**      The time stamp will be in the form: 2020-01-09 15:12:18
**
**      There are two timestamp_text functions; this one accepts a timestamp that does not have a timezone
**
**  Example usage:
**      To get the current time, use either
**        SELECT timestamp_text(localtimestamp);
**      or
**        SELECT timestamp_text(current_timestamp::timestamp);
**
**  Auth: mem
**  Date: 01/09/2020
**
*****************************************************/

BEGIN
    Return to_char(_currentTime, 'YYYY-MM-DD HH24:MI:SS');
END
$$;


ALTER FUNCTION public.timestamp_text(_currenttime timestamp without time zone) OWNER TO d3l243;

--
-- Name: timestamp_text(timestamp with time zone); Type: FUNCTION; Schema: public; Owner: d3l243
--
-- Overload 2

CREATE OR REPLACE FUNCTION public.timestamp_text(_currenttime timestamp with time zone) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns a text representation for the value specified by the _currentTime argument
**      The time stamp will be in the form: 2020-01-09 15:12:18
**
**      There are two timestamp_text functions; this one accepts a timestamp with a timezone
**
**  Example usage:
**      To get the current time, use either
**        SELECT timestamp_text(localtimestamp);
**      or
**        SELECT timestamp_text(current_timestamp);
**
**  Auth: mem
**  Date: 01/14/2020
**
*****************************************************/

BEGIN
    Return to_char(_currentTime::timestamp, 'YYYY-MM-DD HH24:MI:SS');
END
$$;


ALTER FUNCTION public.timestamp_text(_currenttime timestamp with time zone) OWNER TO d3l243;

