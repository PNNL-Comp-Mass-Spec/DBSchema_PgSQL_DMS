--
-- Name: trigfn_t_analysis_job_after_delete(); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.trigfn_t_analysis_job_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Makes an entry in t_event_log for the deleted analysis job
**      Also updates decontools_job_for_qc in t_dataset
**
**  Auth:   grk
**  Date:   01/01/2003
**          08/15/2007 mem - Updated to use an Insert query (Ticket #519)
**          10/02/2007 mem - Updated to append the analysis tool name and
**                           dataset name for the deleted job to the entered_by field (Ticket #543)
**          10/31/2007 mem - Added Set NoCount statement (Ticket #569)
**          11/25/2013 mem - Now updating decontools_job_for_qc in t_dataset
**          08/01/2022 mem - Initial version
**          08/04/2022 mem - Ported to PostgreSQL
**          08/07/2022 mem - Reference the NEW and OLD variables directly instead of using transition tables (which contain every deleted row, not just the current row)
**          08/11/2022 mem - Convert _bestJobByDataset from an int to a record
**          05/30/2023 mem - Use format() for string concatenation
**
*****************************************************/
DECLARE
    _analysisTool text;
    _datasetName text;
    _bestJobByDataset record;
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    -- Lookup the tool name dataset name for the deleted job

    SELECT analysis_tool
    INTO _analysisTool
    FROM t_analysis_tool
    WHERE OLD.analysis_tool_id = analysis_tool_id;

    SELECT dataset
    INTO _datasetName
    FROM t_dataset
    WHERE OLD.dataset_id = dataset_id;

    -- Add an entry to t_event_log for the deleted job
    INSERT INTO t_event_log
        (
            target_type,
            target_id,
            target_state,
            prev_target_state,
            entered,
            entered_by
        )
    SELECT 5 AS target_type,
           OLD.job AS target_id,
           0 AS target_state,
           OLD.job_state_id AS prev_target_state,
           CURRENT_TIMESTAMP,
           format('%s; %s on %s',
                    SESSION_USER,
                    COALESCE(_analysisTool, 'Unknown Tool'),
                    COALESCE(_datasetName, 'Unknown Dataset'));

    SELECT SourceQ.dataset_id, SourceQ.job
    INTO _bestJobByDataset
    FROM ( SELECT DS.dataset_id,
                  J.job AS Job,
                  Row_Number() OVER (PARTITION BY J.dataset_id ORDER BY J.job DESC) AS JobRank
           FROM t_dataset DS
                INNER JOIN t_analysis_job J
                  ON J.dataset_id = DS.dataset_id
                INNER JOIN t_analysis_tool Tool
                  ON Tool.analysis_tool_id = J.analysis_tool_id AND
                     Tool.tool_base_name = 'Decon2LS'
           WHERE J.dataset_id = OLD.dataset_id AND
                 J.job_state_id IN (2, 4)
         ) SourceQ
    WHERE SourceQ.jobRank = 1;

    If FOUND Then
        UPDATE t_dataset
        SET decontools_job_for_qc = _bestJobByDataset.job
        WHERE t_dataset.dataset_id = _bestJobByDataset.dataset_id AND
              t_dataset.decontools_job_for_qc IS DISTINCT FROM _bestJobByDataset.job;
    End If;

    RETURN null;
END
$$;


ALTER FUNCTION public.trigfn_t_analysis_job_after_delete() OWNER TO d3l243;

