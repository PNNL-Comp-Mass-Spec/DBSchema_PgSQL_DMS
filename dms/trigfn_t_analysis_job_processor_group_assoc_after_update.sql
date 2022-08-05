--
-- Name: trigfn_t_analysis_job_processor_group_assoc_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_analysis_job_processor_group_assoc_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates entered and entered_by if Group_ID is changed
**
**  Auth:   mem
**  Date:   04/27/2008
**          08/04/2022 mem - Ported to PostgreSQL
**
*****************************************************/
Begin
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Use <> since group_id is never null
    If OLD.group_id <> NEW.group_id Then

        UPDATE t_analysis_job_processor_group_associations
        SET entered = CURRENT_TIMESTAMP,
            entered_by = SESSION_USER
        FROM NEW as N
        WHERE N.job = t_analysis_job_processor_group_associations.job;

    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_analysis_job_processor_group_assoc_after_update() OWNER TO d3l243;

