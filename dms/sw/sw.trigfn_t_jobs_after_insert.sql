--
-- Name: trigfn_t_jobs_after_insert(); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.trigfn_t_jobs_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add entries to t_job_events for each new job, but only if the new state is non-zero
**
**  Auth:   mem
**  Date:   07/31/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    INSERT INTO sw.t_job_events (
        job,
        target_state,
        prev_target_state
    )
    SELECT inserted.job, inserted.State as New_State, 0 as Old_State
    FROM inserted
    WHERE inserted.State <> 0
    ORDER BY inserted.job;

    RETURN null;
END
$$;


ALTER FUNCTION sw.trigfn_t_jobs_after_insert() OWNER TO d3l243;

