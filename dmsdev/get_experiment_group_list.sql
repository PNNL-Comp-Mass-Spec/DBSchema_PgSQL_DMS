--
-- Name: get_experiment_group_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_experiment_group_list(_experimentid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build delimited list of experiment group IDs for a given experiment
**
**  Return value: comma-separated list
**
**  Auth:   mem
**  Date:   12/16/2011 mem
**          06/21/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(group_id::text, ', ' ORDER BY group_id)
    INTO _result
    FROM t_experiment_group_members
    WHERE exp_id = _experimentID;

    If Coalesce(_result, '') = ''  Then
        _result := '(none)';
    End If;

    RETURN _result;
END
$$;


ALTER FUNCTION public.get_experiment_group_list(_experimentid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_experiment_group_list(_experimentid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_experiment_group_list(_experimentid integer) IS 'GetExperimentGroupList';

