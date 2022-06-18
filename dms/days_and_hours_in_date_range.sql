--
-- Name: days_and_hours_in_date_range(timestamp without time zone, timestamp without time zone, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--
-- Overload 1

CREATE OR REPLACE FUNCTION public.days_and_hours_in_date_range(_startdate timestamp without time zone DEFAULT '2005-01-01 00:00:00'::timestamp without time zone, _enddate timestamp without time zone DEFAULT '2005-01-21 00:00:00'::timestamp without time zone, _hourinterval integer DEFAULT 6) RETURNS TABLE(dy timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Returns a series of date/time values spaced _hourInterval hours apart
**
**  Auth:   mem
**  Date:   11/07/2007
**          11/29/2007 mem - Fixed bug that started at _startDate + _hourInterval instead of at _startDate
**          06/17/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    RETURN QUERY
    SELECT generate_series (_startDate, _endDate, make_interval(0, 0, 0, 0, _hourInterval));
END
$$;


ALTER FUNCTION public.days_and_hours_in_date_range(_startdate timestamp without time zone, _enddate timestamp without time zone, _hourinterval integer) OWNER TO d3l243;

--
-- Name: FUNCTION days_and_hours_in_date_range(_startdate timestamp without time zone, _enddate timestamp without time zone, _hourinterval integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.days_and_hours_in_date_range(_startdate timestamp without time zone, _enddate timestamp without time zone, _hourinterval integer) IS 'DaysAndHoursInDateRange';

--
-- Name: days_and_hours_in_date_range(timestamp with time zone, timestamp with time zone, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--
-- Overload 2

CREATE OR REPLACE FUNCTION public.days_and_hours_in_date_range(_startdate timestamp with time zone DEFAULT '2005-01-01 00:00:00-08'::timestamp with time zone, _enddate timestamp with time zone DEFAULT '2005-01-21 00:00:00-08'::timestamp with time zone, _hourinterval integer DEFAULT 6) RETURNS TABLE(dy timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Returns a series of date/time values spaced _hourInterval hours apart
**
**  Auth:   mem
**  Date:   11/07/2007
**          11/29/2007 mem - Fixed bug that started at _startDate + _hourInterval instead of at _startDate
**          06/17/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    RETURN QUERY
    SELECT generate_series (_startDate, _endDate, make_interval(0, 0, 0, 0, _hourInterval));
END
$$;


ALTER FUNCTION public.days_and_hours_in_date_range(_startdate timestamp with time zone, _enddate timestamp with time zone, _hourinterval integer) OWNER TO d3l243;

--
-- Name: FUNCTION days_and_hours_in_date_range(_startdate timestamp with time zone, _enddate timestamp with time zone, _hourinterval integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.days_and_hours_in_date_range(_startdate timestamp with time zone, _enddate timestamp with time zone, _hourinterval integer) IS 'DaysAndHoursInDateRange';

