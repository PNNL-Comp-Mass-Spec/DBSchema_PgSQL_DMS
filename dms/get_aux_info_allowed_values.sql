--
-- Name: get_aux_info_allowed_values(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_aux_info_allowed_values(_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build delimited list of allowed values for given aux info item
**
**  Arguments:
**    _id       Aux info ID
**
**  Returns:
**      List delimited by ' | '
**
**  Auth:   grk
**  Date:   08/24/2010
**          06/18/2022 mem - Ported to PostgreSQL
**          08/15/2022 mem - Use new column name
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(Value, ' | ' ORDER BY Value)
    INTO _result
    FROM t_aux_info_allowed_values
    WHERE aux_description_id = _id;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_aux_info_allowed_values(_id integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_aux_info_allowed_values(_id integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_aux_info_allowed_values(_id integer) IS 'GetAuxInfoAllowedValues';

