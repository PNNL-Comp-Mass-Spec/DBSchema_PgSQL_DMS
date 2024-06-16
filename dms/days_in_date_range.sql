--
-- Name: days_in_date_range(timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: d3l243
--
-- Overload 1

CREATE OR REPLACE FUNCTION public.days_in_date_range(_startdate timestamp without time zone DEFAULT '2005-01-01 00:00:00'::timestamp without time zone, _enddate timestamp without time zone DEFAULT '2005-01-21 00:00:00'::timestamp without time zone) RETURNS TABLE(dy timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**  	Returns a series of date/time values spaced 1 day apart
**
**  Auth:   grk
**  Date:   01/22/2005
**          06/17/2022 mem - Ported to PostgreSQL
**          10/22/2022 mem - Directly pass value to function argument
**
*****************************************************/
BEGIN
    RETURN QUERY
    SELECT generate_series (_startDate, _endDate, make_interval(days => 1));
END
$$;


ALTER FUNCTION public.days_in_date_range(_startdate timestamp without time zone, _enddate timestamp without time zone) OWNER TO d3l243;

--
-- Name: FUNCTION days_in_date_range(_startdate timestamp without time zone, _enddate timestamp without time zone); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.days_in_date_range(_startdate timestamp without time zone, _enddate timestamp without time zone) IS 'DaysInDateRange';

--
-- Name: days_in_date_range(timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: d3l243
--
-- Overload 2

CREATE OR REPLACE FUNCTION public.days_in_date_range(_startdate timestamp with time zone DEFAULT '2005-01-01 00:00:00-08'::timestamp with time zone, _enddate timestamp with time zone DEFAULT '2005-01-21 00:00:00-08'::timestamp with time zone) RETURNS TABLE(dy timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**  	Returns a series of date/time values spaced 1 day apart
**
**  Auth:   grk
**  Date:   01/22/2005
**          06/17/2022 mem - Ported to PostgreSQL
**          10/22/2022 mem - Directly pass value to function argument
**
*****************************************************/
BEGIN
    RETURN QUERY
    SELECT generate_series (_startDate, _endDate, make_interval(days => 1));
END
$$;


ALTER FUNCTION public.days_in_date_range(_startdate timestamp with time zone, _enddate timestamp with time zone) OWNER TO d3l243;

--
-- Name: FUNCTION days_in_date_range(_startdate timestamp with time zone, _enddate timestamp with time zone); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.days_in_date_range(_startdate timestamp with time zone, _enddate timestamp with time zone) IS 'DaysInDateRange';

