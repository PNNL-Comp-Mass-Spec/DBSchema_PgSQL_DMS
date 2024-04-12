--
-- Name: add_job_original(text, timetable.cron, text, jsonb, timetable.command_kind, text, integer, boolean, boolean, boolean, boolean, text); Type: FUNCTION; Schema: timetable; Owner: d3l243
--

CREATE OR REPLACE FUNCTION timetable.add_job_original(job_name text, job_schedule timetable.cron, job_command text, job_parameters jsonb DEFAULT NULL::jsonb, job_kind timetable.command_kind DEFAULT 'SQL'::timetable.command_kind, job_client_name text DEFAULT NULL::text, job_max_instances integer DEFAULT NULL::integer, job_live boolean DEFAULT true, job_self_destruct boolean DEFAULT false, job_ignore_errors boolean DEFAULT true, job_exclusive boolean DEFAULT false, job_on_error text DEFAULT NULL::text) RETURNS bigint
    LANGUAGE sql
    AS $$
    WITH
        cte_chain (v_chain_id) AS (
            INSERT INTO timetable.chain (chain_name, run_at, max_instances, live, self_destruct, client_name, exclusive_execution, on_error)
            VALUES (job_name, job_schedule,job_max_instances, job_live, job_self_destruct, job_client_name, job_exclusive, job_on_error)
            RETURNING chain_id
        ),
        cte_task(v_task_id) AS (
            INSERT INTO timetable.task (chain_id, task_order, kind, command, ignore_error, autonomous)
            SELECT v_chain_id, 10, job_kind, job_command, job_ignore_errors, TRUE
            FROM cte_chain
            RETURNING task_id
        ),
        cte_param AS (
            INSERT INTO timetable.parameter (task_id, order_id, value)
            SELECT v_task_id, 1, job_parameters FROM cte_task, cte_chain
        )
        SELECT v_chain_id FROM cte_chain
$$;


ALTER FUNCTION timetable.add_job_original(job_name text, job_schedule timetable.cron, job_command text, job_parameters jsonb, job_kind timetable.command_kind, job_client_name text, job_max_instances integer, job_live boolean, job_self_destruct boolean, job_ignore_errors boolean, job_exclusive boolean, job_on_error text) OWNER TO d3l243;

--
-- Name: FUNCTION add_job_original(job_name text, job_schedule timetable.cron, job_command text, job_parameters jsonb, job_kind timetable.command_kind, job_client_name text, job_max_instances integer, job_live boolean, job_self_destruct boolean, job_ignore_errors boolean, job_exclusive boolean, job_on_error text); Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON FUNCTION timetable.add_job_original(job_name text, job_schedule timetable.cron, job_command text, job_parameters jsonb, job_kind timetable.command_kind, job_client_name text, job_max_instances integer, job_live boolean, job_self_destruct boolean, job_ignore_errors boolean, job_exclusive boolean, job_on_error text) IS 'Add one-task chain (aka job) to the system';

