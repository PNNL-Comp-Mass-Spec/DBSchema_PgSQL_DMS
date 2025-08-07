--
-- Name: add_job(text, timetable.cron, text, jsonb, timetable.command_kind, text, integer, boolean, boolean, boolean, boolean, text, boolean); Type: FUNCTION; Schema: timetable; Owner: d3l243
--

CREATE OR REPLACE FUNCTION timetable.add_job(job_name text, job_schedule timetable.cron, job_command text, job_parameters jsonb DEFAULT NULL::jsonb, job_kind timetable.command_kind DEFAULT 'SQL'::timetable.command_kind, job_client_name text DEFAULT NULL::text, job_max_instances integer DEFAULT NULL::integer, job_live boolean DEFAULT true, job_self_destruct boolean DEFAULT false, job_ignore_errors boolean DEFAULT false, job_exclusive boolean DEFAULT false, job_on_error text DEFAULT NULL::text, _infoonly boolean DEFAULT false) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Creates a new one-task chain (aka job)
**
**      This function is a PL/pgSQL version of the pg_timetable add_job() function, defined at
**      https://github.com/cybertec-postgresql/pg_timetable/blob/master/internal/pgengine/sql/job_functions.sql#L16
**
**  Arguments:
**    job_name              Job name
**    job_schedule          Cron-style schedule, or @every, @after, or @reboot
**    job_command           SQL query, procedure call, or built-in command name
**    job_parameters        Parameters for built-in commands; must be able to cast to JSON, e.g. '30' or '[30, 35, 40]'
**    job_kind              Command kind: 'SQL', 'PROGRAM', or 'BUILTIN'
**    job_client_name       Specifies which client should execute the chain; if Null, allow any client
**    job_max_instances     Maximum number of running instances
**    job_live boolean      True if the job is enabled, false if disabled
**    job_self_destruct     True if the job should delete itself after successful execution; failed chains will be executed according to the schedule one more time
**    job_ignore_errors     When true, ignore errors; if set to true, the worker process will report a success on execution even if the task within the chain fails
**    job_exclusive         When true, execute the chain exclusively while all other chains are paused
**    job_on_error          SQL to execute if an error occurs (ignored if the task that produced the error has ignore_error = true)
**    _infoOnly             When true, show the job that would be created
**
**  Job schedule options:
**      Schedules can either use @every, @after, or @reboot, or they can use a cron-style schedule
**      - @every tasks are repeated at equal intervals of time
**      - @after tasks repeat at an interval that starts after a chain finishes execution
**
**      Example expressions for @every or @after, where the time interval must be capable of being cast to a PostgreSQL interval (e.g. '2 hours'::interval)
**      - @every 2 hours
**      - @every 5 minutes
**      - @every 10 seconds
**      - @after 3 minutes
**      - @reboot means to run the chain when PostgreSQL first starts, e.g. to clear the timetable log table (timetable.log)
**
**      Useful website for creating cron schedules:
**      https://cron.help
**
**  Example usage:
**      SELECT timetable.add_job(
**                  job_name       => 'Check data integrity',
**                  job_schedule   => '19 17 * * *',
**                  job_command    => 'Sleep',
**                  job_parameters => '20',
**                  job_kind => 'BUILTIN'
**             );
**
**      SELECT timetable.add_job(
**                  job_name       => 'Retire stale LC columns',
**                  job_schedule   => '15 15 * * 4',
**                  job_command    => 'CALL retire_stale_lc_columns (_infoOnly => false);',
**                  job_kind => 'SQL'
**             );
**
**  Auth:   mem
**  Date:   03/18/2024 mem - Initial release
**
*****************************************************/
DECLARE
    _chainID int;
    _taskID int;
    _taskOrder int;
BEGIN
    RAISE INFO '';
    RAISE INFO '% a new chain named "%" with schedule "%"',
               CASE WHEN _infoOnly THEN 'Would create' ELSE 'Creating' END,
               job_name, job_schedule;

    If _infoOnly Then
        RAISE INFO 'Command: %', job_command;
        RETURN null;
    End If;

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
    SELECT v_chain_id
    INTO _chainID
    FROM cte_chain;

    SELECT task_id, task_order
    INTO _taskID, _taskOrder
    FROM timetable.task
    WHERE chain_id = _chainID;

    RAISE INFO '';

    If Not FOUND Then
        RAISE WARNING 'Task not found in table timetable.task for chain %', _chainID;
        RETURN null;
    End If;

    RAISE INFO 'Created task % for chain %, with type % and order %',
               _taskID, _chainID, job_kind, _taskOrder;

    RAISE INFO 'Command: %', job_command;

    RETURN _chainID;
END
$$;


ALTER FUNCTION timetable.add_job(job_name text, job_schedule timetable.cron, job_command text, job_parameters jsonb, job_kind timetable.command_kind, job_client_name text, job_max_instances integer, job_live boolean, job_self_destruct boolean, job_ignore_errors boolean, job_exclusive boolean, job_on_error text, _infoonly boolean) OWNER TO d3l243;

--
-- Name: FUNCTION add_job(job_name text, job_schedule timetable.cron, job_command text, job_parameters jsonb, job_kind timetable.command_kind, job_client_name text, job_max_instances integer, job_live boolean, job_self_destruct boolean, job_ignore_errors boolean, job_exclusive boolean, job_on_error text, _infoonly boolean); Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON FUNCTION timetable.add_job(job_name text, job_schedule timetable.cron, job_command text, job_parameters jsonb, job_kind timetable.command_kind, job_client_name text, job_max_instances integer, job_live boolean, job_self_destruct boolean, job_ignore_errors boolean, job_exclusive boolean, job_on_error text, _infoonly boolean) IS 'Add a new one-task chain (aka job) to the system';

