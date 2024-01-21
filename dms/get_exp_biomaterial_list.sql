--
-- Name: get_exp_biomaterial_list(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_exp_biomaterial_list(_experimentname text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build delimited list of biomaterial items for given experiment
**
**  Return value: semicolon delimited list
**
**  Auth:   grk
**  Date:   02/04/2005
**          11/29/2017 mem - Expand the return value to varchar(2048) and use Coalesce
**          06/21/2022 mem - Ported to PostgreSQL
**          01/20/2024 mem - Ignore case when filtering by experiment name
**
*****************************************************/
DECLARE
    _result text := null;
BEGIN
    SELECT string_agg(B.biomaterial_name, ', ' ORDER BY B.biomaterial_name)
    INTO _result
    FROM t_experiment_biomaterial EB
         INNER JOIN t_experiments E
           ON EB.exp_id = E.exp_id
         INNER JOIN t_biomaterial B
           ON EB.biomaterial_id = B.biomaterial_id
    WHERE E.experiment = _experimentName::citext;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_exp_biomaterial_list(_experimentname text) OWNER TO d3l243;

--
-- Name: FUNCTION get_exp_biomaterial_list(_experimentname text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_exp_biomaterial_list(_experimentname text) IS 'GetExpBiomaterialList or GetExpCellCultureList';

