--
-- Name: get_prep_lc_experiment_groups_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_prep_lc_experiment_groups_list(_preplcrunid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Builds delimited list of experiment groups
**      for given prep LC run
**
**  Return value: comma-separated list
**
**  Auth:   grk
**  Date:   04/30/2010
**          06/22/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(EG.group_id::text, ', ' ORDER BY EG.group_id)
    INTO _result
    FROM t_experiment_groups EG
         INNER JOIN t_prep_lc_run PrepLC
           ON EG.prep_lc_run_id = PrepLC.prep_run_id
    WHERE PrepLC.prep_run_id = _prepLCRunID;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_prep_lc_experiment_groups_list(_preplcrunid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_prep_lc_experiment_groups_list(_preplcrunid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_prep_lc_experiment_groups_list(_preplcrunid integer) IS 'GetPrepLCExperimentGroupsList';

