--
-- Name: move_task_up(bigint); Type: FUNCTION; Schema: timetable; Owner: d3l243
--

CREATE OR REPLACE FUNCTION timetable.move_task_up(task_id bigint) RETURNS boolean
    LANGUAGE sql
    AS $_$
	WITH current_task (ct_chain_id, ct_id, ct_order) AS (
		SELECT chain_id, task_id, task_order FROM timetable.task WHERE task_id = $1
	),
	tasks(t_id, t_new_order) AS (
		SELECT task_id, COALESCE(LAG(task_order) OVER w, LEAD(task_order) OVER w)
		FROM timetable.task t, current_task ct
		WHERE chain_id = ct_chain_id AND (task_order < ct_order OR task_id = ct_id)
		WINDOW w AS (PARTITION BY chain_id ORDER BY ABS(task_order - ct_order))
		LIMIT 2
	),
	upd AS (
		UPDATE timetable.task t SET task_order = t_new_order
		FROM tasks WHERE tasks.t_id = t.task_id AND tasks.t_new_order IS NOT NULL
		RETURNING true
	)
	SELECT COUNT(*) > 0 FROM upd
$_$;


ALTER FUNCTION timetable.move_task_up(task_id bigint) OWNER TO d3l243;

--
-- Name: FUNCTION move_task_up(task_id bigint); Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON FUNCTION timetable.move_task_up(task_id bigint) IS 'Switch the order of the task execution with a previous task within the chain';

