--
-- Name: get_exp_ref_compound_list(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_exp_ref_compound_list(_experimentname text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build delimited list of reference compounds for given experiment
**
**  Return value: semicolon delimited list
**
**  Auth:   mem
**  Date:   11/29/2017
**          01/04/2018 mem - Now caching reference compounds using the ID_Name field (which is of the form Compound_ID:Compound_Name)
**          06/16/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result text := null;
BEGIN
    SELECT string_agg(RC.id_name, '; ' ORDER BY RC.id_name)
    INTO _result
    FROM t_experiment_reference_compounds ERC
         INNER JOIN t_experiments E
           ON ERC.exp_id = E.exp_id
         INNER JOIN t_reference_compound RC
           ON ERC.compound_id = RC.compound_id
    WHERE E.experiment = _experimentName;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_exp_ref_compound_list(_experimentname text) OWNER TO d3l243;

--
-- Name: FUNCTION get_exp_ref_compound_list(_experimentname text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_exp_ref_compound_list(_experimentname text) IS 'GetExpRefCompoundList';

