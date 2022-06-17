--
-- Name: get_exp_group_experiment_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_exp_group_experiment_list(_groupid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Builds delimited list of experiments for given Experiment Group
**
**  Auth:   grk
**  Date:   07/11/2006
**          06/16/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(E.experiment, ', ' ORDER BY E.experiment)
    INTO _result
    FROM t_experiments E INNER JOIN
         t_experiment_group_members G
           ON E.exp_id = G.exp_id
    WHERE G.group_id = _groupID;

    RETURN _result;
END
$$;


ALTER FUNCTION public.get_exp_group_experiment_list(_groupid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_exp_group_experiment_list(_groupid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_exp_group_experiment_list(_groupid integer) IS 'GetExpGroupExperimentList';

