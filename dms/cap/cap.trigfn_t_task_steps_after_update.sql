--
-- Name: trigfn_t_task_steps_after_update(); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.trigfn_t_task_steps_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add entries to t_task_step_events for each updated capture task step
**
**  Auth:   mem
**  Date:   07/31/2022 mem - Ported to PostgreSQL
**          08/08/2022 mem - Move value comparison to WHEN condition of trigger
**                         - Reference the OLD and NEW variables directly instead of using transition tables (which contain every updated row, not just the current row)
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    INSERT INTO cap.t_task_step_events (
        job,
        step,
        target_state,
        prev_target_state
    )
    SELECT NEW.job,
           NEW.step AS Step,
           NEW.State AS New_State,
           OLD.State AS Old_State;

    RETURN null;
END
$$;


ALTER FUNCTION cap.trigfn_t_task_steps_after_update() OWNER TO d3l243;

