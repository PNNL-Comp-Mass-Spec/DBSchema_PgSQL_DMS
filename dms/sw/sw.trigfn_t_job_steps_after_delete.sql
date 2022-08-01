--
-- Name: trigfn_t_job_steps_after_delete(); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.trigfn_t_job_steps_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add entries to t_job_step_events for each deleted job step
**
**  Auth:   mem
**  Date:   07/31/2022 mem - Ported to PostgreSQL
**          08/01/2022 mem - Prevent deleting all rows in the table
**
*****************************************************/
DECLARE
    _newRowCount int;
    _deletedRowCount int;
    _message text;
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    SELECT COUNT(*)
    INTO _newRowCount
    FROM sw.t_job_steps;

    SELECT COUNT(*)
    INTO _deletedRowCount
    FROM deleted;

    -- RAISE NOTICE 'New row count: %, deleted rows: %', _newRowCount, _deletedRowCount;

    If _deletedRowCount > 0 And _newRowCount = 0 Then
        _message := format('Cannot delete all %s rows in %s; use a WHERE clause to limit the affected rows (see trigger function %s)',
                           _deletedRowCount, 't_job_steps', 'trigfn_t_job_steps_after_delete');

        RAISE EXCEPTION '%', _message;
        RETURN null;
    End If;

    INSERT INTO sw.t_job_step_events
        (job, step, target_state, prev_target_state)
    SELECT deleted.Job, deleted.Step, 0 as New_State, deleted.State as Old_State
    FROM deleted
    ORDER BY deleted.Job, deleted.Step;

    RETURN null;
END
$$;


ALTER FUNCTION sw.trigfn_t_job_steps_after_delete() OWNER TO d3l243;

