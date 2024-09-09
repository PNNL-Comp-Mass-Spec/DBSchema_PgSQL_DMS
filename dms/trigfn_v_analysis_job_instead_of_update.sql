--
-- Name: trigfn_v_analysis_job_instead_of_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_v_analysis_job_instead_of_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Allows for updating the following columns in view public.v_analysis_job
**        priority
**        state_id
**        comment
**
**  Auth:   mem
**  Date:   09/09/2024 mem - Initial version
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL;

    If TG_OP = 'UPDATE' Then
        UPDATE public.t_analysis_job
        SET priority     = NEW.priority,
            job_state_id = NEW.state_id,
            comment      = NEW.comment
        WHERE job = OLD.job;

        RETURN NEW;
    End If;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.trigfn_v_analysis_job_instead_of_update() OWNER TO d3l243;

