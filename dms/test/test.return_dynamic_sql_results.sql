--
-- Name: return_dynamic_sql_results(timestamp without time zone, timestamp without time zone, integer); Type: FUNCTION; Schema: test; Owner: d3l243
--

CREATE OR REPLACE FUNCTION test.return_dynamic_sql_results(_startdate timestamp without time zone DEFAULT '2005-01-01 00:00:00'::timestamp without time zone, _enddate timestamp without time zone DEFAULT '2005-01-21 00:00:00'::timestamp without time zone, _hourinterval integer DEFAULT 6) RETURNS TABLE(dy timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns a series of date/time values spaced _hourInterval hours apart
**
**      Demonstrates use of RETURN QUERY with EXECUTE _sql
**
**  Arguments:
**    _startDate        Starting timestamp
**    _endDate          Ending timestamp
**    _hourInterval     Interval, in hours
**
**  Example usage:
**      SELECT * FROM test.return_dynamic_sql_results('1/20/2023', '1/23/2023');
**      SELECT * FROM test.return_dynamic_sql_results('1/20/2023', '1/23/2023', _hourInterval => 4);
**
**  Auth:   mem
**  Date:   01/24/2023 mem - Initial release
**
*****************************************************/
DECLARE
    _sql text;
    _startDateText text;
    _endDateText text;
BEGIN
    _startDateText := make_date(Extract(year from _startDate)::int, Extract(month from _startDate)::int, Extract(day from _startDate)::int)::text;
    _endDateText   := make_date(Extract(year from _endDate)::int,   Extract(month from _endDate)::int,   Extract(day from _endDate)::int)::text;

    _sql := format('SELECT the_date FROM generate_series (''%s''::timestamp, ''%s''::timestamp, make_interval(hours => %s)) AS the_date',
                   _startDate::text, _endDate::text, _hourInterval);

    -- Uncomment to show the SQL
    -- RAISE INFO '%', _sql;

    RETURN QUERY
    EXECUTE _sql;
END
$$;


ALTER FUNCTION test.return_dynamic_sql_results(_startdate timestamp without time zone, _enddate timestamp without time zone, _hourinterval integer) OWNER TO d3l243;

