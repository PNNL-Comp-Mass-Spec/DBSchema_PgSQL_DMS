--
CREATE OR REPLACE PROCEDURE public.hold_jobs_for_purged_datasets
(
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the job state to 8=Holding for jobs associated with purged datasets
**
**  Arguments:
**    _infoOnly     When true, preview updates
**    _message      Output message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   05/15/2008 (Ticket #670)
**          05/22/2008 mem - Now updating comment for any jobs that are set to state 8 (Ticket #670)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _updateCount int := 0;
    _holdMessage text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    _holdMessage := '; holding since dataset purged';

    CREATE TEMP TABLE Tmp_JobsToUpdate (
        Job int NOT NULL
    );

    INSERT INTO Tmp_JobsToUpdate (job)
    SELECT job
    FROM t_analysis_job
    WHERE job_state_id = 1 AND
          dataset_id IN ( SELECT DISTINCT target_id
                             FROM t_event_log
                             WHERE target_type = 6 AND
                                   target_state = 4 );

    If Not FOUND Then
        If _infoOnly Then
            RAISE INFO 'No jobs having purged datasets were found with state 1=New';
        End If;

        DROP TABLE Tmp_JobsToUpdate;
        RETURN;
    End If;

    If _infoOnly Then

        RAISE INFO '';

        _formatSpecifier := '%-10s %-20s %-16s %-20s %-15s %-80s %-20s %-80s %-80s';

        _infoHead := format(_formatSpecifier,
                            'Job',
                            'Created',
                            'Analysis_Tool_ID',
                            'Comment',
                            'StateID',
                            'Dataset',
                            'Dataset_Created',
                            'Dataset_Folder_Path',
                            'Archive_Folder_Path'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '--------------------',
                                     '----------------',
                                     '--------------------',
                                     '---------------',
                                     '--------------------------------------------------------------------------------',
                                     '--------------------',
                                     '--------------------------------------------------------------------------------',
                                     '--------------------------------------------------------------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT AJ.job AS Job,
                   public.timestamp_text(AJ.created) AS Created,
                   AJ.analysis_tool_id AS AnalysisToolID,
                   Coalesce(AJ.comment, '') || _holdMessage AS Comment,
                   AJ.job_state_id AS StateID,
                   DS.dataset AS Dataset,
                   public.timestamp_text(DS.created) AS Dataset_Created,
                   DFP.Dataset_Folder_Path,
                   DFP.Archive_Folder_Path
            FROM Tmp_JobsToUpdate JTU
                 INNER JOIN t_analysis_job AJ
                   ON JTU.job = AJ.job AND
                      AJ.job_state_id = 1
                 INNER JOIN t_dataset DS
                   ON AJ.dataset_id = DS.dataset_id
                 INNER JOIN V_Dataset_Folder_Paths DFP
                   ON DS.dataset_id = DFP.dataset_id
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Job,
                                _previewData.Created,
                                _previewData.AnalysisToolID,
                                _previewData.Comment,
                                _previewData.StateID,
                                _previewData.Dataset,
                                _previewData.Dataset_Created,
                                _previewData.Dataset_Folder_Path,
                                _previewData.Archive_Folder_Path
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    Else
        UPDATE t_analysis_job
        SET job_state_id = 8,
            comment = format('%s%s', comment, _holdMessage)
        FROM Tmp_JobsToUpdate JTU
        WHERE JTU.Job = AJ.job AND
              AJ.job_state_id = 1;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        If _updateCount > 0 Then
            _message := format('Placed %s %s on hold since %s associated dataset %s purged',
                                _updateCount,
                                public.check_plural(_updateCount, 'job', 'jobs'),
                                public.check_plural(_updateCount, 'its', 'their'),
                                public.check_plural(_updateCount, 'is',  'are'));
        End If;
    End If;

    DROP TABLE Tmp_JobsToUpdate;
END
$$;

COMMENT ON PROCEDURE public.hold_jobs_for_purged_datasets IS 'HoldJobsForPurgedDatasets';
