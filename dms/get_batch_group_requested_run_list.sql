--
-- Name: get_batch_group_requested_run_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_batch_group_requested_run_list(_batchgroupid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build a delimited list of the requested run IDs in a requested run batch group
**
**  Arguments:
**    _batchGroupID      Batch Group ID
**
**  Returns:
**      Comma-separated list
**
**  Auth:   mem
**  Date:   02/09/2023 mem - Initial version
**
*****************************************************/
DECLARE
    _result text := '';
BEGIN
    SELECT string_agg(RR.request_id::text, ', ' ORDER BY request_id)
    INTO _result
    FROM t_requested_run_batches RRB
         INNER JOIN t_requested_run RR
           ON RR.batch_id = RRB.batch_id
    WHERE RRB.batch_group_id = _batchGroupID;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_batch_group_requested_run_list(_batchgroupid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_batch_group_requested_run_list(_batchgroupid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_batch_group_requested_run_list(_batchgroupid integer) IS 'GetBatchGroupRequestedRunList';

