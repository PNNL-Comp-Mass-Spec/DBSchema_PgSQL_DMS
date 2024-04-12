--
-- Name: trigfn_v_jobs_instead_of_update(); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.trigfn_v_jobs_instead_of_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Allows for updating the following columns in view sw.v_jobs
**        priority
**        state
**        comment
**
**  Auth:   mem
**  Date:   06/21/2023 mem - Initial version
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    If TG_OP = 'UPDATE' Then
        UPDATE sw.t_jobs
        SET priority = NEW.priority,
            state    = NEW.state,
            comment  = NEW.comment
        WHERE job  = OLD.job;

        RETURN NEW;
    End If;

    RETURN NEW;
END;
$$;


ALTER FUNCTION sw.trigfn_v_jobs_instead_of_update() OWNER TO d3l243;

