--
-- Name: add_task(timetable.command_kind, text, bigint, double precision, boolean); Type: FUNCTION; Schema: timetable; Owner: d3l243
--

CREATE OR REPLACE FUNCTION timetable.add_task(kind timetable.command_kind, command text, parent_id bigint, order_delta double precision DEFAULT 10, _infoonly boolean DEFAULT false) RETURNS bigint
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Appends a task to an existing pg_timetable chain
**
**      This function is a PL/pgSQL version of the pg_timetable add_task() function, defined at
**      https://github.com/cybertec-postgresql/pg_timetable/blob/master/internal/pgengine/sql/job_functions.sql#L2
**
**  Arguments:
**    kind          Command kind: 'SQL', 'PROGRAM', or 'BUILTIN'
**    command       SQL query, procedure call, or built-in command name
**    parent_id     Parent task ID (not the chain ID)
**    order_delta   Value to add to task_order for the given parent task when determining the task_order for the new task
**    _infoOnly     When true, show the task that would be created
**
**  Example usage:
**      SELECT timetable.add_task(
**                  kind        => 'SQL',
**                  parent_id   => 8,               -- Parent Task ID
**                  command     => 'CALL auto_define_wps_for_eus_requested_runs (_mostRecentMonths => 6, _infoOnly => false);',
**                  order_delta => 10,              -- Order delta, not the actual Task Order
**                  _infoOnly   => true
**             );
**
**  Auth:   mem
**  Date:   03/16/2024 mem - Initial release
**          03/18/2024 mem - Use parameter names instead of $1, $2, etc.
**
*****************************************************/
DECLARE
    _chainID int;
    _taskOrder int;
    _taskID int;
    _taskKind timetable.command_kind;
    _taskCommand text;
BEGIN
    SELECT chain_id, task_order
    INTO _chainID, _taskOrder
    FROM timetable.task
    WHERE task_id = parent_id;

    RAISE INFO '';

    If Not FOUND Then
        RAISE WARNING 'Task_ID % not found in table timetable.task', parent_id;
        RETURN null;
    End If;

    RAISE INFO '% task of type % to chain %, with order %, following task_id %',
               CASE WHEN _infoOnly THEN 'Would add' ELSE 'Adding' END,
               kind, _chainID, _taskOrder + order_delta, parent_id;

    RAISE INFO 'Command: %', command;

    If _infoOnly Then
        RETURN null;
    End If;

    _taskKind    := kind;
    _taskCommand := command;

    INSERT INTO timetable.task (chain_id, task_order, kind, command)
    SELECT _chainID, T.task_order + order_delta, _taskKind, _taskCommand
    FROM timetable.task T
    WHERE T.task_id = parent_id
    RETURNING task_id
    INTO _taskID;

    RETURN _taskID;
END
$_$;


ALTER FUNCTION timetable.add_task(kind timetable.command_kind, command text, parent_id bigint, order_delta double precision, _infoonly boolean) OWNER TO d3l243;

--
-- Name: FUNCTION add_task(kind timetable.command_kind, command text, parent_id bigint, order_delta double precision, _infoonly boolean); Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON FUNCTION timetable.add_task(kind timetable.command_kind, command text, parent_id bigint, order_delta double precision, _infoonly boolean) IS 'Add a task to the same chain as the task with parent_id (where parent_id is the parent task_id)';

