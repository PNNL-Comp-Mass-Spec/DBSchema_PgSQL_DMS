--
-- Name: validate_wildcard_filter(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.validate_wildcard_filter(_wildcardfilter text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Make sure that _wildcardFilter contains a percent sign
**      Add percent signs at the beginning and end if it does not have them
**
**  Arguments:
**    _wildcardFilter   Filter text to examine
**
**  Returns:
**      Updated wildcard filter
**
**  Auth:   mem
**  Date:   06/10/2019 mem - Initial version
**          06/24/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**
*****************************************************/
BEGIN
    _wildcardFilter := Trim(Coalesce(_wildcardFilter, ''));

    -- Add wildcards if _wildcardFilter doesn't contain a percent sign

    If _wildcardFilter <> '' And Position('%' in _wildcardFilter) = 0 Then
        _wildcardFilter := '%' || _wildcardFilter || '%';
    End If;

    RETURN _wildcardFilter;
END
$$;


ALTER FUNCTION public.validate_wildcard_filter(_wildcardfilter text) OWNER TO d3l243;

--
-- Name: FUNCTION validate_wildcard_filter(_wildcardfilter text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.validate_wildcard_filter(_wildcardfilter text) IS 'ValidateWildcardFilter';

