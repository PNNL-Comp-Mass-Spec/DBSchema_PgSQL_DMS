--
-- Name: get_batch_group_instrument_group_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_batch_group_instrument_group_list(_batchgroupid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Builds a delimited list of the instrument groups associated with a requested run batch group
**      These are based on instrument group names in t_requested_run_batches
**
**  Return value: Comma-separated list
**
**  Auth:   mem
**  Date:   02/09/2023 mem - Initial version
**
*****************************************************/
DECLARE
    _result text := '';
BEGIN
    SELECT string_agg(LookupQ.requested_instrument_group, ', ' ORDER BY LookupQ.requested_instrument_group)
    INTO _result
    FROM ( SELECT DISTINCT RRB.requested_instrument_group
           FROM t_requested_run_batches RRB
           WHERE RRB.batch_group_id = _batchGroupID) As LookupQ;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_batch_group_instrument_group_list(_batchgroupid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_batch_group_instrument_group_list(_batchgroupid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_batch_group_instrument_group_list(_batchgroupid integer) IS 'GetBatchGroupInstrumentGroupList';

