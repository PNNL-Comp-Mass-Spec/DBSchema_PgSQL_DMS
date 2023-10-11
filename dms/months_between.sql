--
-- Name: months_between(timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: d3l243
--
-- Overload 1

CREATE OR REPLACE FUNCTION public.months_between(_start timestamp without time zone, _end timestamp without time zone) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $_$
/****************************************************
**
**  Desc:
**      Returns the calendar month difference between two timestamps
**      (from https://stackoverflow.com/a/51928739/1179467)
**
**  Arguments:
**    _start    First timestamp  (as a timestamp without a timezone)
**    _end      Second timestamp (as a timestamp without a timezone)
**
**  Example results:
**      SELECT * FROM public.months_between('2022-02-28', '2022-03-02');         -- Result:  1
**      SELECT * FROM public.months_between('2022-01-01', '2022-03-02');         -- Result:  2
**      SELECT * FROM public.months_between('2022-03-01', '2022-03-02');         -- Result:  0
**      SELECT * FROM public.months_between('2021-10-20', '2022-03-02');         -- Result:  5
**      SELECT * FROM public.months_between('2022-10-20', '2022-03-30');         -- Result: -7
**      SELECT * FROM public.months_between(null, CURRENT_TIMESTAMP::timestamp); -- Result: null
**
**  Auth:   mem
**  Date:   11/16/2022 mem - Initial version
**
*****************************************************/
BEGIN
    RETURN ((extract('years' from $2)::int - extract('years' from $1)::int) * 12) -
             extract('month' from $1)::int + extract('month' from $2)::int;
END
$_$;


ALTER FUNCTION public.months_between(_start timestamp without time zone, _end timestamp without time zone) OWNER TO d3l243;

--
-- Name: months_between(timestamp without time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: d3l243
--
-- Overload 2

CREATE OR REPLACE FUNCTION public.months_between(_start timestamp without time zone, _end timestamp with time zone) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $$
/****************************************************
**
**  Desc:
**      Returns the calendar month difference between two timestamps
**
**  Arguments:
**    _start    First timestamp  (as a timestamp without a timezone)
**    _end      Second timestamp (as a timestamp with a timezone)
**
**  Example results:
**      SELECT * FROM public.months_between('2022-02-28', '2022-03-02'::timestamptz);   -- Result:  1
**      SELECT * FROM public.months_between('2022-01-01', '2022-03-02'::timestamptz);   -- Result:  2
**      SELECT * FROM public.months_between('2022-03-01', '2022-03-02'::timestamptz);   -- Result:  0
**      SELECT * FROM public.months_between('2021-10-20', '2022-03-02'::timestamptz);   -- Result:  5
**      SELECT * FROM public.months_between('2022-10-20', '2022-03-30'::timestamptz);   -- Result: -7
**      SELECT * FROM public.months_between(null, CURRENT_TIMESTAMP);                   -- Result: null
**
**  Auth:   mem
**  Date:   10/10/2023 mem - Initial version
**
*****************************************************/
BEGIN
    RETURN public.months_between(_start, _end::timestamp);
END
$$;


ALTER FUNCTION public.months_between(_start timestamp without time zone, _end timestamp with time zone) OWNER TO d3l243;

