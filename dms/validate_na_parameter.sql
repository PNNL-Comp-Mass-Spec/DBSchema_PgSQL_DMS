--
-- Name: validate_na_parameter(text, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.validate_na_parameter(_parameter text, _trimwhitespace integer DEFAULT 1) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes sure that the parameter text is 'na' if blank or null, or if it matches 'na' or 'n/a'
**
**  Arguments:
**    _parameter        Text to check
**    _trimWhitespace   When 1, trim whitespace
**
**  Return value: the validated parameter
**
**  Auth:   mem
**  Date:   09/12/2008 mem - Ticket #688, http://prismtrac.pnl.gov/trac/ticket/688
**          01/14/2009 mem - Expanded _parameter length to 4000 characters (Ticket #714, http://prismtrac.pnl.gov/trac/ticket/714)
**          06/24/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/
BEGIN
    _parameter := Coalesce(_parameter, 'na');

    If Coalesce(_trimWhitespace, 1) <> 0 Then
        _parameter := Trim(_parameter);
    End If;

    If _parameter = '' Then
        _parameter := 'na';
    End If;

    If Lower(_parameter) = 'na' or Lower(_parameter) = 'n/a' Then
        _parameter := 'na';
    End If;

    RETURN _parameter;
END
$$;


ALTER FUNCTION public.validate_na_parameter(_parameter text, _trimwhitespace integer) OWNER TO d3l243;

--
-- Name: FUNCTION validate_na_parameter(_parameter text, _trimwhitespace integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.validate_na_parameter(_parameter text, _trimwhitespace integer) IS 'ValidateNAParameter';

