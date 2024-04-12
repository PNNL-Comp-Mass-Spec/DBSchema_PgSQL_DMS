--
-- Name: notify_chain_start(bigint, text, interval); Type: FUNCTION; Schema: timetable; Owner: d3l243
--

CREATE OR REPLACE FUNCTION timetable.notify_chain_start(chain_id bigint, worker_name text, start_delay interval DEFAULT NULL::interval) RETURNS void
    LANGUAGE sql
    AS $$
    SELECT pg_notify(
        worker_name,
        format('{"ConfigID": %s, "Command": "START", "Ts": %s, "Delay": %s}',
            chain_id,
            EXTRACT(epoch FROM clock_timestamp())::bigint,
            COALESCE(EXTRACT(epoch FROM start_delay)::bigint, 0)
        )
    )
$$;


ALTER FUNCTION timetable.notify_chain_start(chain_id bigint, worker_name text, start_delay interval) OWNER TO d3l243;

--
-- Name: FUNCTION notify_chain_start(chain_id bigint, worker_name text, start_delay interval); Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON FUNCTION timetable.notify_chain_start(chain_id bigint, worker_name text, start_delay interval) IS 'Send notification to the worker to start the chain';

