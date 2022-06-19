--
-- Name: get_batch_requested_run_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_batch_requested_run_list(_batchid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Builds delimited list of requested runs
**      associated with the given batch
**
**  Return value: Comma separated list
**
**  Auth:   grk
**  Date:   01/11/2006 grk - Initial version
**          03/29/2019 mem - Return an empty string when _batchID is 0 (meaning "unassigned", no batch)
**          06/02/2021 mem - Expand the return value to varchar(max)
**          06/16/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result text := '';
BEGIN
    SELECT string_agg(request_id::text, ', ' ORDER BY request_id)
    INTO _result
    FROM t_requested_run
    WHERE batch_id = _batchID AND batch_id <> 0;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_batch_requested_run_list(_batchid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_batch_requested_run_list(_batchid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_batch_requested_run_list(_batchid integer) IS 'GetBatchRequestedRunList';

