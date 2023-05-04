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
**      Updates the job state to 8=Holding for jobs associated with purged dataset
**
**  Auth:   mem
**  Date:   05/15/2008 (Ticket #670)
**          05/22/2008 mem - Now updating comment for any jobs that are set to state 8 (Ticket #670)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _holdMessage text;
BEGIN
    _message := '';
    _returnCode:= '';

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
                             WHERE (target_type = 6) AND
                                   (target_state = 4) );

    If Not FOUND Then
        If _infoOnly Then
            RAISE INFO 'No jobs having purged datasets were found with state 1=New';
        End If;

        DROP TABLE Tmp_JobsToUpdate;
        RETURN;
    End If;

    If _infoOnly Then
        -- ToDo: Update this to use RAISE INFO

        SELECT AJ.job AS Job,
               AJ.created AS Created,
               AJ.analysis_tool_id AS AnalysisToolID,
               Coalesce(AJ.comment, '') + _holdMessage AS Comment,
               AJ.job_state_id AS StateID,
               DS.dataset AS Dataset,
               DS.created AS Dataset_Created,
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
    Else
        UPDATE t_analysis_job
        SET job_state_id = 8,
            comment = comment || _holdMessage
        FROM Tmp_JobsToUpdate JTU
        WHERE JTU.Job = AJ.job AND
               AJ.job_state_id = 1
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount > 0 Then
            _message := 'Placed ' || _myRowCount::text || ' jobs on hold since their associated dataset is purged';
        End If;
    End If;

    DROP TABLE Tmp_JobsToUpdate;
END
$$;

COMMENT ON PROCEDURE public.hold_jobs_for_purged_datasets IS 'HoldJobsForPurgedDatasets';