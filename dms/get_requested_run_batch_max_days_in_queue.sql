--
-- Name: get_requested_run_batch_max_days_in_queue(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_requested_run_batch_max_days_in_queue(_batchid integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Returns the largest value for v_requested_run_queue_times.days_in_queue
**      for the requested runs in the given batch
**
**  Return value: Maximum days in queue
**
**  Auth:   mem
**  Date:   02/10/2023 mem - Initial version
**
*****************************************************/
DECLARE
    _result numeric := 0;
BEGIN
    SELECT MAX(QT.days_in_queue)
    INTO _result
    FROM t_requested_run RR
         INNER JOIN v_requested_run_queue_times QT
           ON QT.requested_run_id = RR.request_id
    WHERE RR.batch_id = _batchid AND NOT RR.dataset_id IS NULL
    GROUP BY RR.batch_id;

    RETURN _result;
END
$$;


ALTER FUNCTION public.get_requested_run_batch_max_days_in_queue(_batchid integer) OWNER TO d3l243;

