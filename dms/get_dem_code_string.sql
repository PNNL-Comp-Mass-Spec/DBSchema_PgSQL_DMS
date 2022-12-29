--
-- Name: get_dem_code_string(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_dem_code_string(_code integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns sting for data extraction manager completion code
**
**  Auth:   grk
**  Date:   07/27/2006
**          06/14/2022 mem - Ported to PostgreSQL
**          12/24/2022 mem - Use format()
**
*****************************************************/
DECLARE
    _description text;
BEGIN
    _description := case _code
                        when 0 then 'Success'
                        when 1 then 'Failed'
                        when 2 then 'No Param File'
                        when 3 then 'No Settings File'
                        when 5 then 'No Moddefs File'
                        when 6 then 'No MassCorrTag File'
                        when 10 then 'No Data'
                        else 'Undefined'
                    end;

    RETURN format('%s (%s)',  _description, _code);
END
$$;


ALTER FUNCTION public.get_dem_code_string(_code integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_dem_code_string(_code integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_dem_code_string(_code integer) IS 'GetDEMCodeString';

