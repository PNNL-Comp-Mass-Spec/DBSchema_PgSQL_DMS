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
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    If NEW.State = OLD.State Then
        RETURN null;
    End If;

    INSERT INTO cap.t_task_step_events
        (job, step, target_state, prev_target_state)
    SELECT N.job,
           N.step AS Step,
           N.State AS New_State,
           O.State AS Old_State
    FROM OLD O
         INNER JOIN NEW N
           ON O.job = N.job AND
              O.step = N.step
    ORDER BY N.job, N.step;

    RETURN null;
END
$$;


ALTER FUNCTION cap.trigfn_t_task_steps_after_update() OWNER TO d3l243;

