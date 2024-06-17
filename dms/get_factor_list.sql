--
-- Name: get_factor_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_factor_list(_requestid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build a delimited list of factors (as name/value pairs) for given requested run
**
**  Arguments:
**     _requestID   Requested run ID
**
**  Returns:
**      Comma-separated list
**
**  Auth:   grk
**  Date:   05/17/2011
**          06/16/2022 mem - Ported to PostgreSQL
**          05/30/2023 mem - Use format() for string concatenation
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    IF Not _requestID Is Null Then
        SELECT string_agg(format('%s:%s', name, value), ', ' ORDER BY name)
        INTO _result
        FROM t_factor
        WHERE type = 'Run_Request' AND
              target_id = _requestID;
    End If;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_factor_list(_requestid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_factor_list(_requestid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_factor_list(_requestid integer) IS 'GetFactorList';

