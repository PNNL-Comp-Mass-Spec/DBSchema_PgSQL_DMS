--
-- Name: get_fiscal_year_from_date(timestamp without time zone); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_fiscal_year_from_date(_rawdate timestamp without time zone) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return Fiscal year for given date
**
**  Return value: Fiscal year, e.g. 2021
**
**  Auth:   grk
**  Date:   03/15/2012
**          06/21/2022 mem - Ported to PostgreSQL
**          12/15/2022 mem - Use extract(year from _variable) and extract(month from) to extract the year and month from timestamps
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/
DECLARE
    _fiscalYear timestamp;
BEGIN
    _fiscalYear := CASE WHEN extract(month from _rawDate) > 9
                        THEN _rawDate + Interval '1 year'
                        ELSE _rawDate
                   END;

    RETURN extract(year from _fiscalYear);
END
$$;


ALTER FUNCTION public.get_fiscal_year_from_date(_rawdate timestamp without time zone) OWNER TO d3l243;

--
-- Name: FUNCTION get_fiscal_year_from_date(_rawdate timestamp without time zone); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_fiscal_year_from_date(_rawdate timestamp without time zone) IS 'GetFiscalYearFromDate or GetFYFromDate';

