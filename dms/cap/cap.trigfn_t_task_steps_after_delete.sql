--
-- Name: trigfn_t_task_steps_after_delete(); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.trigfn_t_task_steps_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add entries to t_task_step_events for each deleted capture task step
**
**  Auth:   mem
**  Date:   07/30/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    INSERT INTO cap.t_task_step_events
        (job, step, target_state, prev_target_state)
    SELECT deleted.Job, deleted.Step, 0 as New_State, deleted.State as Old_State
    FROM deleted
    ORDER BY deleted.Job, deleted.Step;

    RETURN null;
END
$$;


ALTER FUNCTION cap.trigfn_t_task_steps_after_delete() OWNER TO d3l243;

