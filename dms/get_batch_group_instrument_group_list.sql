--
-- Name: get_batch_group_instrument_group_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_batch_group_instrument_group_list(_batchgroupid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build a delimited list of the instrument groups associated with a requested run batch group
**      These are based on instrument group names in t_requested_run
**
**  Return value: Comma-separated list
**
**  Auth:   mem
**  Date:   02/09/2023 mem - Initial version
**          01/19/2024 mem - Obtain instrument group names from t_requested_run
**
*****************************************************/
DECLARE
    _result text := '';
BEGIN
    SELECT string_agg(LookupQ.instrument_group, ', ' ORDER BY LookupQ.instrument_group)
    INTO _result
    FROM ( SELECT DISTINCT RR.instrument_group
           FROM t_requested_run_batches RRB
                LEFT OUTER JOIN t_requested_run RR
                  ON RRB.batch_id = RR.batch_id
           WHERE RRB.batch_group_id = _batchGroupID) As LookupQ;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_batch_group_instrument_group_list(_batchgroupid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_batch_group_instrument_group_list(_batchgroupid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_batch_group_instrument_group_list(_batchgroupid integer) IS 'GetBatchGroupInstrumentGroupList';

