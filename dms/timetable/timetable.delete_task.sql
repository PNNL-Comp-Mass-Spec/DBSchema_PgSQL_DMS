--
-- Name: delete_task(bigint); Type: FUNCTION; Schema: timetable; Owner: d3l243
--

CREATE OR REPLACE FUNCTION timetable.delete_task(task_id bigint) RETURNS boolean
    LANGUAGE sql
    AS $_$
    WITH del_task AS (DELETE FROM timetable.task WHERE task_id = $1 RETURNING task_id)
    SELECT EXISTS(SELECT 1 FROM del_task)
$_$;


ALTER FUNCTION timetable.delete_task(task_id bigint) OWNER TO d3l243;

--
-- Name: FUNCTION delete_task(task_id bigint); Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON FUNCTION timetable.delete_task(task_id bigint) IS 'Delete the task from a chain';

