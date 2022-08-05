--
-- Name: trigfn_t_analysis_job_after_insert(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_analysis_job_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_event_log for the new analysis job
**
**  Auth:   grk
**  Date:   01/01/2003
**          08/15/2007 mem - Updated to use an Insert query (Ticket #519)
**          10/31/2007 mem - Added Set NoCount statement (Ticket #569)
**          12/12/2007 mem - Now updating state_name_cached (Ticket #585)
**          04/03/2014 mem - Now updating analysis_tool_cached
**          08/04/2022 mem - Ported to PostgreSQL
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    INSERT INTO t_event_log (target_type, target_id, target_state, prev_target_state, entered)
    SELECT 5, inserted.job, inserted.job_state_id, 0, CURRENT_TIMESTAMP
    FROM inserted
    ORDER BY inserted.job;

    UPDATE t_analysis_job
    SET state_name_cached = COALESCE(AJDAS.job_State, ''),
        analysis_tool_cached = COALESCE(Tool.analysis_tool, '')
    FROM inserted INNER JOIN
         V_Analysis_Job_and_Dataset_Archive_State AJDAS ON inserted.job = AJDAS.job INNER JOIN
         t_analysis_tool Tool ON inserted.analysis_tool_id = Tool.analysis_tool_id
    WHERE t_analysis_job.job = inserted.job;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_analysis_job_after_insert() OWNER TO d3l243;

