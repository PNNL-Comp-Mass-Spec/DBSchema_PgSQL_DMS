--
-- Name: get_fiscal_year_text_from_date(timestamp without time zone); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_fiscal_year_text_from_date(_rawdate timestamp without time zone) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return Fiscal year for given date
**
**  Return value: Fiscal year description, e.g. FY_22
**
**  Auth:   grk
**  Date:   07/18/2011
**          06/21/2022 mem - Ported to PostgreSQL
**          12/15/2022 mem - Use Extract(year from _variable) and Extract(month from) to extract the year and month from timestamps
**          05/30/2023 mem - Use format() for string concatenation
**
*****************************************************/
DECLARE
    _fiscalYear timestamp;
BEGIN
    _fiscalYear := CASE WHEN Extract(month from _rawDate) > 9
                        THEN _rawDate + INTERVAL '1 year'
                        ELSE _rawDate
                   END;

    RETURN format('FY_%s', Right(Extract(year from _fiscalYear)::text, 2));
END
$$;


ALTER FUNCTION public.get_fiscal_year_text_from_date(_rawdate timestamp without time zone) OWNER TO d3l243;

--
-- Name: FUNCTION get_fiscal_year_text_from_date(_rawdate timestamp without time zone); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_fiscal_year_text_from_date(_rawdate timestamp without time zone) IS 'GetFiscalYearFromDate';

