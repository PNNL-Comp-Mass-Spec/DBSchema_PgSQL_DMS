--
-- Name: retry_capture_for_dms_reset_tasks(text, text, boolean); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.retry_capture_for_dms_reset_tasks(INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Retry capture for datasets that failed capture
**      but for which the dataset state in public.t_dataset is 1=New
**
**  Auth:   mem
**  Date:   05/25/2011 mem - Initial version
**          08/16/2017 mem - For capture task jobs with error 'Error running OpenChrom', only reset the DatasetIntegrity step
**          06/20/2023 mem - Ported to PostgreSQL
**          06/21/2023 mem - Add missing Drop Table call
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _jobList text;
    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    CREATE TEMP TABLE Tmp_Selected_Jobs (
        Job int NOT NULL,
        ResetFailedStepsOnly boolean NOT NULL
    );

    ---------------------------------------------------
    -- Look for capture task jobs that are failed and have one or more failed step states
    -- but for which the dataset is present in cap.V_DMS_Get_New_Datasets (which queries public.t_dataset)
    --
    -- These are datasets that have been reset (either via the dataset detail report web page or manually)
    -- and we thus want to retry capture for these datasets
    ---------------------------------------------------

    INSERT INTO Tmp_Selected_Jobs (Job, ResetFailedStepsOnly)
    SELECT DISTINCT T.Job, false
    FROM cap.V_DMS_Get_New_Datasets NewDS
         INNER JOIN cap.t_tasks T
           ON NewDS.Dataset_ID = T.Dataset_ID
         INNER JOIN cap.t_task_steps TS
           ON T.Job = TS.Job
    WHERE T.Script IN ('IMSDatasetCapture', 'DatasetCapture') AND
          T.State = 5 AND
          TS.State = 6;

    If Not FOUND Then
        If _infoOnly Then
            RAISE INFO 'No datasets were found needing to retry capture';
        End If;

        DROP TABLE Tmp_Selected_Jobs;
        RETURN;
    End If;

    -- Construct a comma-separated list of capture task jobs

    SELECT string_agg(Job::text, ', ' ORDER BY Job)
    INTO _jobList
    FROM Tmp_Selected_Jobs;

    UPDATE Tmp_Selected_Jobs
    SET ResetFailedStepsOnly = true
    WHERE Job IN ( SELECT Job
                   FROM cap.t_task_steps
                   WHERE State = 6 AND
                         Tool = 'DatasetIntegrity' AND
                         Completion_Message = 'Error running OpenChrom' AND
                         Job IN ( SELECT Job FROM Tmp_Selected_Jobs ) );

    If _infoOnly Then

        RAISE INFO '';
        RAISE INFO 'JobList: %', _jobList;
        RAISE INFO '';

        _formatSpecifier := '%-23s %-10s %-10s %-5s %-20s %-10s %-5s %-20s %-80s';

        _infoHead := format(_formatSpecifier,
                            'Only_Reset_Failed_Steps',
                            'Job',
                            'Dataset_ID',
                            'Step',
                            'Tool',
                            'State_Name',
                            'State',
                            'Start',
                            'Dataset'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '-----------------------',
                                     '----------',
                                     '----------',
                                     '-----',
                                     '--------------------',
                                     '----------',
                                     '-----',
                                     '--------------------',
                                     '--------------------------------------------------------------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT CASE WHEN Tmp_Selected_Jobs.ResetFailedStepsOnly
                        THEN 'True'
                        ELSE 'False'
                   END AS only_reset_failed,
                   TS.job, TS.dataset_id, TS.step, TS.tool, TS.state_name, TS.state, timestamp_text(TS.start) As start, TS.dataset
            FROM cap.V_task_Steps TS INNER JOIN Tmp_Selected_Jobs ON TS.Job = Tmp_Selected_Jobs.Job
            ORDER BY TS.Job, TS.Step
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.only_reset_failed,
                                _previewData.job,
                                _previewData.dataset_id,
                                _previewData.step,
                                _previewData.tool,
                                _previewData.state_name,
                                _previewData.state,
                                _previewData.start,
                                _previewData.dataset
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        DROP TABLE Tmp_Selected_Jobs;
        RETURN;
    End If;

    -- Update the parameters for each capture task job
    CALL cap.update_parameters_for_task (_jobList, _message => _message, _returnCode => _returnCode);

    ------------------------------------------------------------------
    -- Reset the capture task job steps using RetrySelectedJobs
    -- Fail out any completed steps before performing the reset
    ------------------------------------------------------------------

    -- First reset job steps for capture task jobs in Tmp_Selected_Jobs with ResetFailedStepsOnly = true
    --
    UPDATE cap.t_task_steps
    SET State = 2
    WHERE State = 6 AND
          Tool = 'DatasetIntegrity' AND
          Completion_Message = 'Error running OpenChrom' AND
          Job IN ( SELECT Job
                   FROM Tmp_Selected_Jobs
                   WHERE ResetFailedStepsOnly );

    DELETE FROM Tmp_Selected_Jobs
    WHERE ResetFailedStepsOnly;

    If Exists (SELECT * FROM Tmp_Selected_Jobs) Then
        -- Reset entirely any capture task jobs remaining in Tmp_Selected_Jobs

        -- First set the job steps to 6 (failed)
        UPDATE cap.t_task_steps Target
        SET State = 6
        FROM Tmp_Selected_Jobs T
        WHERE Target.Job = T.Job AND
              Target.State = 5;

        -- Next call retry_selected_tasks
        CALL cap.retry_selected_tasks (_message => _message, _returnCode => _returnCode);

    End If;

    -- Post a log entry that the capture task job(s) have been reset
    If _jobList Like '%,%' Then
        _message := format('Reset dataset capture for capture task jobs %s', _jobList);
    Else
        _message := format('Reset dataset capture for capture task job %s', _jobList);
    End If;

    CALL public.post_log_entry ('Normal', _message, 'Retry_Capture_For_DMS_Reset_Tasks', 'cap');

    DROP TABLE Tmp_Selected_Jobs;
END
$$;


ALTER PROCEDURE cap.retry_capture_for_dms_reset_tasks(INOUT _message text, INOUT _returncode text, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE retry_capture_for_dms_reset_tasks(INOUT _message text, INOUT _returncode text, IN _infoonly boolean); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.retry_capture_for_dms_reset_tasks(INOUT _message text, INOUT _returncode text, IN _infoonly boolean) IS 'RetryCaptureForDMSResetTasks or RetryCaptureForDMSResetJobs';

