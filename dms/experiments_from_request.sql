--
-- Name: experiments_from_request(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.experiments_from_request(_requestid integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return count of number of experiments made from the given sample prep request
**
**  Arguments:
**    _requestID    Sample prep request ID
**
**  Auth:   grk
**  Date:   06/10/2005
**          06/15/2022 mem - Ported to PostgreSQL
**          07/11/2023 mem - Use COUNT(exp_id) instead of COUNT(*)
**
*****************************************************/
DECLARE
    _count int;
BEGIN
    SELECT COUNT(exp_id)
    INTO _count
    FROM t_experiments
    WHERE sample_prep_request_id = _requestID;

    RETURN Coalesce(_count, 0);
END
$$;


ALTER FUNCTION public.experiments_from_request(_requestid integer) OWNER TO d3l243;

--
-- Name: FUNCTION experiments_from_request(_requestid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.experiments_from_request(_requestid integer) IS 'ExperimentsFromRequest';

