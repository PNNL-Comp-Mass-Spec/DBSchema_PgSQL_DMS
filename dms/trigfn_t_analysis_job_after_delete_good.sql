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
**      Assumes that this function is called via a trigger using FOR EACH ROW EXECUTE FUNCTION
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
**
*****************************************************/
DECLARE
    _deletedRowCount int;
    _bestJobByDataset int;
BEGIN
    -- RAISE NOTICE '% trigger, % %, depth=%, level=%; %', TG_TABLE_NAME, TG_WHEN, TG_OP, pg_trigger_depth(), TG_LEVEL, to_char(CURRENT_TIMESTAMP, 'hh24:mi:ss');

    SELECT Count(*)
    INTO _deletedRowCount
    FROM deleted;

    If _deletedRowCount > 1 Then
        RAISE EXCEPTION 'The "deleted" transition table for t_analysis_job has more than one row'
              USING HINT = 'Assure that trigfn_t_analysis_job_after_delete is called via a FOR EACH ROW trigger';

        return null;
    End If;

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
           deleted.job AS target_id,
           0 AS target_state,
           deleted.job_state_id AS prev_target_state,
           CURRENT_TIMESTAMP,
           SESSION_USER || '; ' || COALESCE(Tool.analysis_tool, 'Unknown Tool') || ' on '
                                || COALESCE(DS.dataset, 'Unknown Dataset')
    FROM deleted
         LEFT OUTER JOIN t_dataset DS
           ON deleted.dataset_id = DS.dataset_id
         LEFT OUTER JOIN t_analysis_tool Tool
           ON deleted.analysis_tool_id = Tool.analysis_tool_id;

    SELECT SourceQ.dataset_id, SourceQ.job
    INTO _bestJobByDataset
    FROM ( SELECT DS.dataset_id,
                  J.job AS Job,
                  Row_number() OVER ( PARTITION BY J.dataset_id ORDER BY J.job DESC ) AS JobRank
           FROM t_dataset DS
                INNER JOIN t_analysis_job J
                  ON J.dataset_id = DS.dataset_id
                INNER JOIN t_analysis_tool Tool
                  ON Tool.analysis_tool_id = J.analysis_tool_id AND
                     Tool.tool_base_name = 'Decon2LS'
                INNER JOIN deleted
                  ON J.dataset_id = deleted.dataset_id
           WHERE J.job_state_id IN (2, 4)
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

