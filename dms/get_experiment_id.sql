--
-- Name: get_experiment_id(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_experiment_id(_experimentname text DEFAULT ''::text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Get experiment ID for given experiment name
**
**  Arguments:
**     _experimentName      Experiment name
**
**  Returns:
**      Experiment ID if found, otherwise 0
**
**  Auth:   grk
**  Date:   01/26/2001
**          08/03/2017 mem - Add Set NoCount On
**          10/24/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _experimentID int;
BEGIN
    SELECT exp_id
    INTO _experimentID
    FROM t_experiments
    WHERE experiment = _experimentName::citext;

    If FOUND Then
        RETURN _experimentID;
    Else
        RETURN 0;
    End If;
END
$$;


ALTER FUNCTION public.get_experiment_id(_experimentname text) OWNER TO d3l243;

--
-- Name: FUNCTION get_experiment_id(_experimentname text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_experiment_id(_experimentname text) IS 'GetExperimentID';

