--
-- Name: trigfn_t_jobs_after_update(); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.trigfn_t_jobs_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes entry in t_job_events
**
**  Auth:   mem
**  Date:   08/11/2008 mem - Initial version
**          01/19/2012 mem - Now verifying that the State actually changed
**          07/31/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    If NEW.State = OLD.State Then
        RETURN null;
    End If;

    INSERT INTO sw.t_job_events
        (job, target_state, prev_target_state)
    SELECT N.job,
           N.State AS New_State,
           O.State AS Old_State
    FROM OLD O
         INNER JOIN NEW N
           ON O.job = N.job
    ORDER BY N.job;

    RETURN null;
END
$$;


ALTER FUNCTION sw.trigfn_t_jobs_after_update() OWNER TO d3l243;

