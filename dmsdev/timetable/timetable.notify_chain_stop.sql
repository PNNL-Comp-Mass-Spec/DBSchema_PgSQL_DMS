--
-- Name: notify_chain_stop(bigint, text); Type: FUNCTION; Schema: timetable; Owner: d3l243
--

CREATE OR REPLACE FUNCTION timetable.notify_chain_stop(chain_id bigint, worker_name text) RETURNS void
    LANGUAGE sql
    AS $$
    SELECT pg_notify(
        worker_name,
        format('{"ConfigID": %s, "Command": "STOP", "Ts": %s}',
            chain_id,
            EXTRACT(epoch FROM clock_timestamp())::bigint)
        )
$$;


ALTER FUNCTION timetable.notify_chain_stop(chain_id bigint, worker_name text) OWNER TO d3l243;

--
-- Name: FUNCTION notify_chain_stop(chain_id bigint, worker_name text); Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON FUNCTION timetable.notify_chain_stop(chain_id bigint, worker_name text) IS 'Send notification to the worker to stop the chain';

