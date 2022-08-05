--
-- Name: trigfn_t_analysis_job_processor_group_membership_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_analysis_job_processor_group_membership_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates last_affected and entered_by if any of the
**      parameter fields are changed
**
**  Auth:   mem
**  Date:   02/24/2007
**          08/04/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Use <> since processor_id, group_id, and membership_enabled are never null
    If OLD.processor_id <> NEW.processor_id OR
       OLD.group_id <> NEW.group_id OR
       OLD.membership_enabled <> NEW.membership_enabled Then

        UPDATE t_analysis_job_processor_group_membership
        SET last_affected = CURRENT_TIMESTAMP,
            entered_by = SESSION_USER
        FROM NEW as N
        WHERE t_analysis_job_processor_group_membership.processor_id = N.processor_id AND
              t_analysis_job_processor_group_membership.Group_ID = N.Group_ID;

    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_analysis_job_processor_group_membership_after_update() OWNER TO d3l243;

