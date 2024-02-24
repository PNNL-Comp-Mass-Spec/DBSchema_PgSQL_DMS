--
-- Name: get_fiscal_year_start(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_fiscal_year_start(_numberofrecentyears integer) RETURNS timestamp without time zone
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Returns starting date for fiscal year N years ago
**
**  Return value: Fiscal year start date, e.g. 2021-10-01
**
**  Auth:   grk
**  Date:   07/18/2011 grk - Initial Version
**          02/10/2022 mem - Update to work properly when running between January 1 and September 30
**          06/21/2022 mem - Ported to PostgreSQL
**          12/15/2022 mem - Use Extract(year from _variable) and Extract(month from) to extract the year and month from timestamps
**          05/22/2023 mem - Capitalize reserved word
**          06/08/2023 mem - Directly pass value to function argument
**
*****************************************************/
DECLARE
    _referenceDate timestamp;
    _targetYear int;
    _fiscalYearStart timestamp;
BEGIN
    _referenceDate := CURRENT_TIMESTAMP;

    _targetYear := Extract(year from _referenceDate - make_interval(years => _numberOfRecentYears));

    If Extract(month from _referenceDate) < 10 Then
        _targetYear := _targetYear - 1;
    End If;

    _fiscalYearStart := make_date(_targetYear, 10, 1);

    RETURN _fiscalYearStart;
END
$$;


ALTER FUNCTION public.get_fiscal_year_start(_numberofrecentyears integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_fiscal_year_start(_numberofrecentyears integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_fiscal_year_start(_numberofrecentyears integer) IS 'GetFiscalYearStart';

