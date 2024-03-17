--
-- Name: add_task_original(timetable.command_kind, text, bigint, double precision); Type: FUNCTION; Schema: timetable; Owner: d3l243
--

CREATE OR REPLACE FUNCTION timetable.add_task_original(kind timetable.command_kind, command text, parent_id bigint, order_delta double precision DEFAULT 10) RETURNS bigint
    LANGUAGE sql
    AS $_$
    INSERT INTO timetable.task (chain_id, task_order, kind, command)
    SELECT chain_id, task_order + $4, $1, $2 FROM timetable.task WHERE task_id = $3
    RETURNING task_id
$_$;


ALTER FUNCTION timetable.add_task_original(kind timetable.command_kind, command text, parent_id bigint, order_delta double precision) OWNER TO d3l243;

--
-- Name: FUNCTION add_task_original(kind timetable.command_kind, command text, parent_id bigint, order_delta double precision); Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON FUNCTION timetable.add_task_original(kind timetable.command_kind, command text, parent_id bigint, order_delta double precision) IS 'Add a task to the same chain as the task with parent_id';

