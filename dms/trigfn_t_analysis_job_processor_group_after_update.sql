--
-- Name: trigfn_t_analysis_job_processor_group_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_analysis_job_processor_group_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates last_affected and entered_by if group_name or group_enabled is changed
**
**  Auth:   mem
**  Date:   02/24/2007
**          02/15/2016 mem - Removed column Available_For_General_Processing since deprecated
**          08/04/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Use <> since group_name and group_enabled are never null
    If OLD.group_name <> NEW.group_name OR OLD.group_enabled <> NEW.group_enabled Then

        UPDATE t_analysis_job_processor_group
        SET last_affected = CURRENT_TIMESTAMP,
            entered_by = SESSION_USER
        FROM NEW as N
        WHERE t_analysis_job_processor_group.group_id = N.group_id;

    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_analysis_job_processor_group_after_update() OWNER TO d3l243;

