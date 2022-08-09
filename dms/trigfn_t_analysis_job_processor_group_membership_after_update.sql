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
**          08/07/2022 mem - Move value comparison to WHEN condition of trigger
**                         - Reference the NEW variable directly instead of using transition tables (which contain every updated row, not just the current row)
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    UPDATE t_analysis_job_processor_group_membership
    SET last_affected = CURRENT_TIMESTAMP,
        entered_by = SESSION_USER
    WHERE t_analysis_job_processor_group_membership.processor_id = NEW.processor_id AND
          t_analysis_job_processor_group_membership.Group_ID = NEW.group_id;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_analysis_job_processor_group_membership_after_update() OWNER TO d3l243;

