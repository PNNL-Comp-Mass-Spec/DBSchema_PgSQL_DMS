--
-- Name: get_batch_group_member_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_batch_group_member_list(_batchgroupid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Builds a delimited list of batch IDs in a requested run batch group
**      Batch IDs are sorted by batch_group_order
**
**  Return value: Comma separated list
**
**  Auth:   mem
**  Date:   02/09/2023 mem - Initial version
**
*****************************************************/
DECLARE
    _result text := '';
BEGIN
    SELECT string_agg(batch_id::text, ', ' ORDER BY Coalesce(batch_group_order, 0), batch_id)
    INTO _result
    FROM t_requested_run_batches
    WHERE batch_group_id = _batchGroupID;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_batch_group_member_list(_batchgroupid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_batch_group_member_list(_batchgroupid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_batch_group_member_list(_batchgroupid integer) IS 'GetBatchGroupMemberList';

