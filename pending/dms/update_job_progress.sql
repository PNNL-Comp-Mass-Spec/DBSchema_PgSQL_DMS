--
CREATE OR REPLACE PROCEDURE public.update_job_progress
(
    _mostRecentDays int = 32,
    _job int = 0,
    _infoOnly boolean = false
    _verbose boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Update the progress column in table t_analysis_job
**
**      Note that a progress value of -1 is used for failed jobs
**      Jobs in state 1=New or 8=Holding will have a progress of 0
**
**      Set _mostRecentDays and _job to zero to update all jobs
**
**  Arguments:
**    _mostRecentDays   Used to select jobs to update; matches jobs created or changed within the given number of days
**    _job              Specific job number to update; when non-zero, _mostRecentDays is ignored
**    _infoOnly         When true, preview changes as a summary
**    _verbose          When _infoOnly is true, set this to true to see details on updated jobs
**
**  Auth:   mem
**  Date:   09/01/2016 mem - Initial version
**          10/30/2017 mem - Consider long-running job steps when computing Runtime_Predicted_Minutes
**                         - Set progress to 0 for inactive jobs (state 13)
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _dateThreshold timestamp;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    -----------------------------------------
    -- Validate the inputs
    -----------------------------------------

    _job := Coalesce(_job, 0);
    _mostRecentDays := Coalesce(_mostRecentDays, 0);
    _infoOnly := Coalesce(_infoOnly, false);
    _verbose := Coalesce(_verbose, false);

    _dateThreshold = CURRENT_TIMESTAMP - make_interval(days => _mostRecentDays);

    -----------------------------------------
    -- Create some temporary tables
    -----------------------------------------

    CREATE TEMP TABLE Tmp_JobsToUpdate (
        Job int not null,
        State int not null,
        Progress_Old real null,     -- Value between 0 and 100
        Progress_New real null,     -- Value between 0 and 100
        Steps int null,
        Steps_Completed int null,
        Current_Runtime_Minutes real null,
        Runtime_Predicted_Minutes real null,
        ETA_Minutes real null
    )

    CREATE UNIQUE INDEX IX_Tmp_JobsToUpdate_Job ON Tmp_JobsToUpdate (Job);
    CREATE INDEX IX_Tmp_JobsToUpdate_State ON Tmp_JobsToUpdate (State);

    -----------------------------------------
    -- Find the jobs to update
    -----------------------------------------

    If Coalesce(_job, 0) <> 0 Then
        If Not Exists (SELECT job FROM t_analysis_job WHERE job = _job) Then
            RAISE INFO 'Job not found: %', _job;
            RETURN;
        End If;

        INSERT INTO Tmp_JobsToUpdate (job, State, Progress_Old)
        SELECT job, job_state_id, progress
        FROM t_analysis_job
        WHERE job = _job
    Else
        If _mostRecentDays <= 0 Then
            INSERT INTO Tmp_JobsToUpdate (job, State, Progress_Old)
            SELECT job, job_state_id, progress
            FROM t_analysis_job
        Else

            INSERT INTO Tmp_JobsToUpdate (job, State, Progress_Old)
            SELECT job, job_state_id, progress
            FROM t_analysis_job
            WHERE created >= _dateThreshold OR
                  start >= _dateThreshold
        End If;
    End If;

    -----------------------------------------
    -- Update progress and ETA for failed jobs
    -- This logic is also used by trigger trig_u_AnalysisJob
    -----------------------------------------

    UPDATE Tmp_JobsToUpdate
    SET Progress_New = -1,
        ETA_Minutes = Null
    WHERE State = 5;

    -----------------------------------------
    -- Update progress and ETA for new, holding, inactive, or Special Proc. Waiting jobs
    -- This logic is also used by trigger trig_u_AnalysisJob
    -----------------------------------------

    UPDATE Tmp_JobsToUpdate
    SET Progress_New = 0,
        ETA_Minutes = null
    WHERE State IN (1, 8, 13, 19);

    -----------------------------------------
    -- Update progress and ETA for completed jobs
    -- This logic is also used by trigger trig_u_AnalysisJob
    -----------------------------------------

    UPDATE Tmp_JobsToUpdate
    SET Progress_New = 100,
        ETA_Minutes = 0
    WHERE State IN (4, 7, 14);

    -----------------------------------------
    -- Determine the incremental progress for running jobs
    -----------------------------------------

    UPDATE Tmp_JobsToUpdate Target
    SET Progress_New = Source.Progress_Overall,
        Steps = Source.Steps,
        Steps_Completed = Source.Steps_Completed,
        Current_Runtime_Minutes = Source.Total_Runtime_Minutes
    FROM ( SELECT ProgressQ.Job,
                  ProgressQ.Steps,
                  ProgressQ.Steps_Completed,
                  ProgressQ.WeightedProgressSum / WeightSumQ.WeightSum AS Progress_Overall,
                  ProgressQ.Total_Runtime_Minutes
           FROM ( SELECT JS.Job,
                         COUNT(JS.step) AS Steps,
                         SUM(CASE WHEN JS.State IN (3, 5) THEN 1 ELSE 0 END) AS Steps_Completed,
                         SUM(CASE WHEN JS.State = 3 THEN 0
                                  ELSE JS.Job_Progress * Tools.Avg_Runtime_Minutes
                             END) AS WeightedProgressSum,
                         SUM(RunTime_Minutes) AS Total_Runtime_Minutes
                  FROM sw.V_Job_Steps JS
                       INNER JOIN sw.t_step_tools Tools
                         ON JS.Tool = Tools.step_tool
                       INNER JOIN ( SELECT Job
                                    FROM Tmp_JobsToUpdate
                                    WHERE State = 2
                                  ) JTU ON JS.Job = JTU.Job
                  GROUP BY JS.Job
                ) ProgressQ
                INNER JOIN ( SELECT JS.Job,
                                    SUM(Tools.Avg_Runtime_Minutes) AS WeightSum
                             FROM sw.V_Job_Steps JS
                                  INNER JOIN sw.t_step_tools Tools
                                    ON JS.Tool = Tools.step_tool
                                  INNER JOIN ( SELECT Job
                                               FROM Tmp_JobsToUpdate
                                               WHERE State = 2
                                             ) JTU ON JS.Job = JTU.Job
                             WHERE JS.State <> 3
                             GROUP BY JS.Job
                           ) WeightSumQ
                  ON ProgressQ.Job = WeightSumQ.Job AND
                     WeightSumQ.WeightSum > 0
         ) Source
    WHERE Source.Job = Target.Job;

    -----------------------------------------
    -- Compute Runtime_Predicted_Minutes
    -----------------------------------------

    UPDATE Tmp_JobsToUpdate
    SET Runtime_Predicted_Minutes = Current_Runtime_Minutes / (Progress_New / 100.0)
    WHERE Progress_New > 0 AND
          Current_Runtime_Minutes > 0;

    -----------------------------------------
    -- Look for jobs with an active job step that has been running for over 30 minutes
    -- and has a longer Runtime_Predicted_Minutes value than the one estimated using all of the job steps
    --
    -- The estimated value was computed by weighting on Avg_Runtime_Minutes, but if a single step
    -- is taking a long time, there is no way the overall job will finish earlier than that step will finish;
    --
    -- If this is the case, we update Runtime_Predicted_Minutes to match the predicted runtime of that job step
    -- and compute a new overall job progress
    -----------------------------------------

    UPDATE Tmp_JobsToUpdate Target
    SET Runtime_Predicted_Minutes = RunningStepsQ.RunTime_Predicted_Minutes,
        Progress_New = CASE WHEN RunningStepsQ.Runtime_Predicted_Minutes > 0
                            THEN Current_Runtime_Minutes * 100.0 / RunningStepsQ.Runtime_Predicted_Minutes
                            ELSE Progress_New
                       END
    FROM ( SELECT JS.Job,
                  MAX(JS.RunTime_Predicted_Hours * 60) AS RunTime_Predicted_Minutes
           FROM sw.V_Job_Steps JS
                INNER JOIN ( SELECT Job
                             FROM Tmp_JobsToUpdate
                             WHERE State = 2 ) JTU
                  ON JS.Job = JTU.Job
           WHERE JS.RunTime_Minutes > 30 AND
                 JS.State IN (4, 9)        -- Running or Running_Remote
           GROUP BY JS.Job
         ) RunningStepsQ
    WHERE Target.Job = RunningStepsQ.Job AND
          RunningStepsQ.RunTime_Predicted_Minutes > Target.Runtime_Predicted_Minutes;

    -----------------------------------------
    -- Compute the approximate time remaining for the job to finish
    -- We tack on 0.5 minutes for each uncompleted step, to account for the state machine aspect of sw.t_jobs and sw.t_job_steps
    -----------------------------------------

    UPDATE Tmp_JobsToUpdate
    SET ETA_Minutes = Runtime_Predicted_Minutes - Current_Runtime_Minutes + (Steps - Steps_Completed) * 0.5
    WHERE Progress_New > 0;

    If _infoOnly Then

        -----------------------------------------
        -- Preview updated progress
        -----------------------------------------

        RAISE INFO '';

        If Not _verbose Then

            -- Summarize the changes

            _formatSpecifier := '%-5s %-5s %-12s %-15s %-15s';

            _infoHead := format(_formatSpecifier,
                                'State',
                                'Jobs',
                                'Changed_Jobs',
                                'Min_NewProgress',
                                'Max_NewProgress'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '-----',
                                         '-----',
                                         '------------',
                                         '---------------',
                                         '---------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT State,
                       COUNT(job) AS Jobs,
                       SUM(CASE
                               WHEN Coalesce(Progress_Old, -10) <> Coalesce(Progress_New, -5) THEN 1
                               ELSE 0
                           END) AS Changed_Jobs,
                       MIN(Progress_New) AS Min_NewProgress,
                       MAX(Progress_New) AS Max_NewProgress
                FROM Tmp_JobsToUpdate
                GROUP BY State
                ORDER BY State
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.State,
                                    _previewData.Jobs,
                                    _previewData.Changed_Jobs,
                                    _previewData.Min_NewProgress,
                                    _previewData.Max_NewProgress
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        Else

            -- Show all rows in Tmp_JobsToUpdate

            _formatSpecifier := '%-9s %-5s %-12s %-15s %-5s %-15s %-23s %-25s %-11s %-16s';

            _infoHead := format(_formatSpecifier,
                                'Job',
                                'State',
                                'Progress_Old',
                                'Progress_New',
                                'Steps',
                                'Steps_Completed',
                                'Current_Runtime_Minutes',
                                'Runtime_Predicted_Minutes',
                                'ETA_Minutes',
                                'Progress_Changed'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '---------',
                                         '-----',
                                         '------------',
                                         '---------------',
                                         '-----',
                                         '---------------',
                                         '-----------------------',
                                         '-------------------------',
                                         '-----------',
                                         '----------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Job,
                       State,
                       Progress_Old,
                       Progress_New,
                       Steps,
                       Steps_Completed,
                       Current_Runtime_Minutes,
                       Runtime_Predicted_Minutes,
                       ETA_Minutes,
                       CASE
                           WHEN Coalesce(Progress_Old, 0) <> Coalesce(Progress_New, 0) THEN 'Yes'
                           ELSE 'No'
                       END AS Progress_Changed
                FROM Tmp_JobsToUpdate
                ORDER BY Job
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Job,
                                    _previewData.State,
                                    _previewData.Progress_Old,
                                    _previewData.Progress_New,
                                    _previewData.Steps,
                                    _previewData.Steps_Completed,
                                    _previewData.Current_Runtime_Minutes,
                                    _previewData.Runtime_Predicted_Minutes,
                                    _previewData.ETA_Minutes,
                                    _previewData.Progress_Changed
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

        DROP TABLE Tmp_JobsToUpdate;
        RETURN;
    End If;

    -----------------------------------------
    -- Update the progress
    -----------------------------------------

    UPDATE t_analysis_job Target
    SET progress = Src.Progress_New,
        eta_minutes = Src.eta_minutes
    FROM Tmp_JobsToUpdate Src

    WHERE Target.job = Src.Job AND
          (Target.Progress IS NULL AND NOT Src.Progress_New IS NULL OR
           Coalesce(Target.Progress, 0) <> Coalesce(Src.Progress_New, 0) OR
           Target.job_state_id IN (4,7,14) AND (Target.Progress IS NULL Or Target.ETA_Minutes IS NULL));

    DROP TABLE Tmp_JobsToUpdate;
END
$$;

COMMENT ON PROCEDURE public.update_job_progress IS 'UpdateJobProgress';
