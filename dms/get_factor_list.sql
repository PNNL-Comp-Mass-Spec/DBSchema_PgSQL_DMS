--
-- Name: get_factor_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_factor_list(_requestid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Builds a delimited list of factors (as name/value pairs)
**      for givenrequested run
**
**  Return value: comma separated list
**
**  Auth:   grk
**  Date:   05/17/2011
**          06/16/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    IF NOT _requestID IS NULL Then
        SELECT string_agg(name || ':' || value, ', ' ORDER BY name)
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

