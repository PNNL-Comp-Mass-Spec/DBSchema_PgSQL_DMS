--
-- Name: get_timestamp_from_excel_date(double precision); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_timestamp_from_excel_date(_datefloat double precision) RETURNS timestamp without time zone
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/****************************************************
**
**  Desc:
**      Convert an integer or float based date from Excel to a timestamp
**      The base date is December 30, 1899 because Excel erroneously assumes that 1900 is a leap year, see https://learn.microsoft.com/en-us/office/troubleshoot/excel/wrongly-assumes-1900-is-leap-year
**
**  Arguments:
**    _dateFloat    Float-based date from Microsoft Excel
**
**  Auth:   mem
**  Date:   02/06/2026 mem - Initial version
**
*****************************************************/
DECLARE
    _computedDate timestamp;
BEGIN
    _computedDate := MAKE_DATE(1899, 12, 30) +
                     INTERVAL '1 day' * FLOOR(_dateFloat) +
                     INTERVAL '1 sec' * (_dateFloat - FLOOR(_dateFloat)) * 3600 * 24;

    RETURN _computedDate;
END
$$;


ALTER FUNCTION public.get_timestamp_from_excel_date(_datefloat double precision) OWNER TO d3l243;

