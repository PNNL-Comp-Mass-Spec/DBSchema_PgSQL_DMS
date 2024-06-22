--
-- Name: timestamp_text_immutable(timestamp without time zone); Type: FUNCTION; Schema: public; Owner: d3l243
--
-- Overload 1

CREATE OR REPLACE FUNCTION public.timestamp_text_immutable(_currenttime timestamp without time zone) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/****************************************************
**
**  Desc:
**      Return a text representation for the value specified by the _currentTime argument
**      The function is marked as immutable because if _currentTime is null, it returns an empty string
**
**      The text will include milliseconds and will not have any spaces
**      For example: 2022-05-31_14:38:32.410
**
**      There are two timestamp_text_immutable functions; this one accepts a timestamp that does not have a timezone
**
**  Arguments:
**    _currentTime      Timestamp to convert to text
**
**  Example usage:
**      To convert the timestamp to text, use either
**        SELECT timestamp_text_immutable(localtimestamp);
**      or
**        SELECT timestamp_text_immutable(current_timestamp);
**
**  Auth:   mem
**  Date:   05/31/2022
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/

BEGIN
    RETURN CASE
               WHEN _currentTime IS NULL THEN ''
               ELSE to_char(_currentTime, 'YYYY-MM-DD_HH24:MI:SS.MS')
           END;
END
$$;


ALTER FUNCTION public.timestamp_text_immutable(_currenttime timestamp without time zone) OWNER TO d3l243;

--
-- Name: timestamp_text_immutable(timestamp with time zone); Type: FUNCTION; Schema: public; Owner: d3l243
--
-- Overload 2

CREATE OR REPLACE FUNCTION public.timestamp_text_immutable(_currenttime timestamp with time zone) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/****************************************************
**
**  Desc:
**      Return a text representation for the value specified by the _currentTime argument
**      The function is marked as immutable because if _currentTime is null, it returns an empty string
**
**      The text will include milliseconds and will not have any spaces
**      For example: 2022-05-31_14:38:32.410
**
**      There are two timestamp_text_immutable functions; this one accepts a timestamp with a timezone
**
**  Arguments:
**    _currentTime      Timestamp to convert to text
**
**  Example usage:
**      To convert the timestamp to text, use either
**        SELECT timestamp_text_immutable(localtimestamp);
**      or
**        SELECT timestamp_text_immutable(current_timestamp);
**
**  Auth:   mem
**  Date:   05/31/2022
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/

BEGIN
    RETURN CASE
               WHEN _currentTime IS NULL THEN ''
               ELSE to_char(_currentTime::timestamp, 'YYYY-MM-DD_HH24:MI:SS.MS')
           END;
END
$$;


ALTER FUNCTION public.timestamp_text_immutable(_currenttime timestamp with time zone) OWNER TO d3l243;

