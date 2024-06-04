--
-- Name: trigfn_t_job_steps_after_insert(); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.trigfn_t_job_steps_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add entries to t_job_step_events for each new job step
**
**  Auth:   mem
**  Date:   07/31/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    INSERT INTO sw.t_job_step_events (
        job,
        step,
        target_state,
        prev_target_state
    )
    SELECT inserted.job, inserted.step, inserted.State as New_State, 0 as Old_State
    FROM inserted
    ORDER BY inserted.job, inserted.step;

    RETURN null;
END
$$;


ALTER FUNCTION sw.trigfn_t_job_steps_after_insert() OWNER TO d3l243;

