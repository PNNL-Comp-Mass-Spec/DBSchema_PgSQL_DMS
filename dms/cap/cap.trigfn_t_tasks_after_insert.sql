--
-- Name: trigfn_t_tasks_after_insert(); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.trigfn_t_tasks_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add entries to t_task_events for each new capture task, but only if the new state is non-zero
**
**  Auth:   mem
**  Date:   07/30/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    INSERT INTO cap.t_task_events (
        job,
        target_state,
        prev_target_state
    )
    SELECT inserted.job, inserted.State AS New_State, 0 AS Old_State
    FROM inserted
    WHERE inserted.State <> 0
    ORDER BY inserted.job;

    RETURN null;
END
$$;


ALTER FUNCTION cap.trigfn_t_tasks_after_insert() OWNER TO d3l243;

