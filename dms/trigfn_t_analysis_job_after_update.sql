--
-- Name: trigfn_t_analysis_job_after_update(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_analysis_job_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_event_log for the updated analysis job
**      Also updates last_affected, state_name_cached, progress, eta_minutes, and analysis_tool_cached
**
**  Auth:   grk
**  Date:   01/01/2003
**          05/16/2007 mem - Now updating last_affected when dataset_state_id changes (Ticket #478)
**          08/15/2007 mem - Updated to use an Insert query (Ticket #519)
**          11/01/2007 mem - Added Set NoCount statement (Ticket #569)
**          12/12/2007 mem - Now updating state_name_cached (Ticket #585)
**          04/03/2014 mem - Now updating analysis_tool_cached
**          09/01/2016 mem - Now updating Progress and ETA_Minutes
**          10/30/2017 mem - Set progress to 0 for inactive jobs (state 13)
**                         - Fix StateID bug, switching from 17 to 14
**          09/13/2018 mem - When Started and Finished are non-null, use the larger of Started and Finished for last_affected
**          08/04/2022 mem - Ported to PostgreSQL
**          08/06/2022 mem - Convert to statement-level trigger
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    If Not Exists (Select * From inserted) Then
        RETURN Null;
    End If;

    INSERT INTO t_event_log (target_type, target_id, target_state, prev_target_state, entered)
    SELECT 5, inserted.job, inserted.job_state_id, deleted.job_state_id, CURRENT_TIMESTAMP
    FROM deleted INNER JOIN
         inserted ON deleted.job = inserted.job
    WHERE deleted.job_state_id <> inserted.job_state_id;    -- Use <> since job_state_id is never null

    UPDATE t_analysis_job
    SET last_affected = CASE WHEN NOT inserted.finish Is Null AND inserted.finish >= inserted.start THEN inserted.finish
                             WHEN NOT inserted.start Is Null  AND inserted.start >= inserted.finish THEN inserted.start
                             ELSE CURRENT_TIMESTAMP
                        END,
        state_name_cached = COALESCE(AJDAS.job_State, ''),
        progress = CASE
                       WHEN inserted.job_state_id = 5 THEN -1
                       WHEN inserted.job_state_id IN (1, 8, 13, 19) THEN 0
                       WHEN inserted.job_state_id IN (4, 7, 14) THEN 100
                       ELSE inserted.progress
                   END,
        eta_minutes = CASE
                          WHEN inserted.job_state_id IN (1, 5, 8, 13, 19) THEN NULL
                          WHEN inserted.job_state_id IN (4, 7, 14) THEN 0
                          ELSE inserted.eta_minutes
                      END
    FROM inserted
         INNER JOIN deleted
           ON inserted.job = deleted.job
         INNER JOIN V_Analysis_Job_and_Dataset_Archive_State AJDAS
           ON inserted.job = AJDAS.job
    WHERE deleted.job_state_id <> inserted.job_state_id AND
          t_analysis_job.job = inserted.job;

    UPDATE t_analysis_job
    SET analysis_tool_cached = COALESCE(Tool.analysis_tool, '')
    FROM inserted
         INNER JOIN deleted
           ON inserted.job = deleted.job
         INNER JOIN t_analysis_tool Tool
           ON inserted.analysis_tool_id = Tool.analysis_tool_id
    WHERE deleted.analysis_tool_id <> inserted.analysis_tool_id AND     -- Use <> since analysis_tool_id is never null
          t_analysis_job.job = inserted.job;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_analysis_job_after_update() OWNER TO d3l243;

