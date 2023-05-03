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
**      Updates column Progress in table T_Analysis_Job
**      Note that a progress of -1 is used for failed jobs
**      Jobs in state 1=New or 8=Holding will have a progress of 0
**
**      Set _mostRecentDays and _job to zero to update all jobs
**
**  Arguments:
**    _mostRecentDays   Used to select jobs to update; matches jobs created or changed within the given number of days
**    _job              Specific job number to update; when non-zero, _mostRecentDays is ignored
**    _infoOnly         True to preview changes as a summary
**    _verbose          When _infoOnly is true, set this to true to see details on updated jobs
**
**  Auth:   mem
**  Date:   09/01/2016 mem - Initial version
**          10/30/2017 mem - Consider long-running job steps when computing Runtime_Predicted_Minutes
**                         - Set progress to 0 for inactive jobs (state 13)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _dateThreshold timestamp;
BEGIN
    -----------------------------------------
    -- Validate the input parameters
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
        StepsCompleted int null,
        CurrentRuntime_Minutes real null,
        Runtime_Predicted_Minutes real null,
        ETA_Minutes real null
    )

    CREATE UNIQUE INDEX IX_Tmp_JobsToUpdate_Job ON Tmp_JobsToUpdate (Job);
    CREATE INDEX IX_Tmp_JobsToUpdate_State ON Tmp_JobsToUpdate (State);

    -----------------------------------------
    -- Find the jobs to update
    -----------------------------------------

    If Coalesce(_job, 0) <> 0 Then
        If Not Exists (SELECT * FROM t_analysis_job WHERE job = _job) Then
            RAISE INFO '%', 'job not found ' || Cast(_job as text);
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
    --
    UPDATE Tmp_JobsToUpdate
    SET Progress_New = -1,
        ETA_Minutes = Null
    WHERE State = 5
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    -----------------------------------------
    -- Update progress and ETA for new, holding, inactive, or Special Proc. Waiting jobs
    -- This logic is also used by trigger trig_u_AnalysisJob
    -----------------------------------------
    --
    UPDATE Tmp_JobsToUpdate
    SET Progress_New = 0,
        ETA_Minutes = Null
    WHERE State In (1, 8, 13, 19)
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    -----------------------------------------
    -- Update progress and ETA for completed jobs
    -- This logic is also used by trigger trig_u_AnalysisJob
    -----------------------------------------
    --
    UPDATE Tmp_JobsToUpdate
    SET Progress_New = 100,
        ETA_Minutes = 0
    WHERE State In (4, 7, 14)
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    -----------------------------------------
    -- Determine the incremental progress for running jobs
    -----------------------------------------
    --
    UPDATE Tmp_JobsToUpdate
    SET Progress_New = Source.Progress_Overall,
        Steps = Source.Steps,
        StepsCompleted = Source.StepsCompleted,
        CurrentRuntime_Minutes = Source.TotalRuntime_Minutes
    FROM Tmp_JobsToUpdate Target

    /********************************************************************************
    ** This UPDATE query includes the target table name in the FROM clause
    ** The WHERE clause needs to have a self join to the target table, for example:
    **   UPDATE Tmp_JobsToUpdate
    **   SET ...
    **   FROM source
    **   WHERE source.id = Tmp_JobsToUpdate.id;
    ********************************************************************************/

                           ToDo: Fix this query

         INNER JOIN ( SELECT ProgressQ.Job,
                             ProgressQ.Steps,
                             ProgressQ.StepsCompleted,
                             ProgressQ.WeightedProgressSum / WeightSumQ.WeightSum AS Progress_Overall,
                             ProgressQ.TotalRuntime_Minutes
                      FROM ( SELECT JS.Job,
                                    COUNT(*) AS Steps,
                                    SUM(CASE WHEN JS.State IN (3, 5) THEN 1 ELSE 0 END) AS StepsCompleted,
                                    SUM(CASE WHEN JS.State = 3 THEN 0
                                             ELSE JS.Job_Progress * Tools.AvgRuntime_Minutes
                                        END) AS WeightedProgressSum,
                                    SUM(RunTime_Minutes) AS TotalRuntime_Minutes
                             FROM S_V_Pipeline_Job_Steps JS
                                  INNER JOIN S_T_Pipeline_Step_Tools Tools
                                    ON JS.Tool = Tools.Name
                                  INNER JOIN ( SELECT Job
                                               FROM Tmp_JobsToUpdate

                                               /********************************************************************************
                                               ** This UPDATE query includes the target table name in the FROM clause
                                               ** The WHERE clause needs to have a self join to the target table, for example:
                                               **   UPDATE Tmp_JobsToUpdate
                                               **   SET ...
                                               **   FROM source
                                               **   WHERE source.id = Tmp_JobsToUpdate.id;
                                               ********************************************************************************/

                                                                      ToDo: Fix this query

                                               WHERE State = 2
                                             ) JTU ON JS.Job = JTU.Job
                             GROUP BY JS.Job
                           ) ProgressQ
                           INNER JOIN ( SELECT JS.Job,
                                               SUM(Tools.AvgRuntime_Minutes) AS WeightSum
                                        FROM S_V_Pipeline_Job_Steps JS
                                             INNER JOIN S_T_Pipeline_Step_Tools Tools
                                               ON JS.Tool = Tools.Name
                                             INNER JOIN ( SELECT Job
                                                          FROM Tmp_JobsToUpdate

                                                          /********************************************************************************
                                                          ** This UPDATE query includes the target table name in the FROM clause
                                                          ** The WHERE clause needs to have a self join to the target table, for example:
                                                          **   UPDATE Tmp_JobsToUpdate
                                                          **   SET ...
                                                          **   FROM source
                                                          **   WHERE source.id = Tmp_JobsToUpdate.id;
                                                          ********************************************************************************/

                                                                                 ToDo: Fix this query

                                                          WHERE State = 2
                                                        ) JTU ON JS.Job = JTU.Job
                                        WHERE JS.State <> 3
                                        GROUP BY JS.Job
                                      ) WeightSumQ
                             ON ProgressQ.Job = WeightSumQ.Job AND
                                WeightSumQ.WeightSum > 0
                           ) Source
           ON Source.Job = Target.Job
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    -----------------------------------------
    -- Compute Runtime_Predicted_Minutes
    -----------------------------------------
    --
    UPDATE Tmp_JobsToUpdate
    SET Runtime_Predicted_Minutes = CurrentRuntime_Minutes / (Progress_New / 100.0)
    WHERE Progress_New > 0 AND
          CurrentRuntime_Minutes > 0
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    -----------------------------------------
    -- Look for jobs with an active job step that has been running for over 30 minutes
    -- and has a longer Runtime_Predicted_Minutes value than the one estimated using all of the job steps
    --
    -- The estimated value was computed by weighting on AvgRuntime_Minutes, but if a single step
    -- is taking a long time, there is no way the overall job will finish earlier than that step will finish;
    --
    -- If this is the case, we update Runtime_Predicted_Minutes to match the predicted runtime of that job step
    -- and compute a new overall job progress
    -----------------------------------------
    --
    UPDATE Tmp_JobsToUpdate
    SET Runtime_Predicted_Minutes = RunningStepsQ.RunTime_Predicted_Minutes,
        Progress_New = CASE WHEN RunningStepsQ.Runtime_Predicted_Minutes > 0
                            THEN CurrentRuntime_Minutes * 100.0 / RunningStepsQ.Runtime_Predicted_Minutes
                            ELSE Progress_New
                       END
    FROM Tmp_JobsToUpdate Target

    /********************************************************************************
    ** This UPDATE query includes the target table name in the FROM clause
    ** The WHERE clause needs to have a self join to the target table, for example:
    **   UPDATE Tmp_JobsToUpdate
    **   SET ...
    **   FROM source
    **   WHERE source.id = Tmp_JobsToUpdate.id;
    ********************************************************************************/

                           ToDo: Fix this query

         INNER JOIN ( SELECT JS.Job,
                             MAX(JS.RunTime_Predicted_Hours * 60) AS RunTime_Predicted_Minutes
                      FROM S_V_Pipeline_Job_Steps JS
                           INNER JOIN ( SELECT Job
                                        FROM Tmp_JobsToUpdate

                                        /********************************************************************************
                                        ** This UPDATE query includes the target table name in the FROM clause
                                        ** The WHERE clause needs to have a self join to the target table, for example:
                                        **   UPDATE Tmp_JobsToUpdate
                                        **   SET ...
                                        **   FROM source
                                        **   WHERE source.id = Tmp_JobsToUpdate.id;
                                        ********************************************************************************/

                                                               ToDo: Fix this query

                                        WHERE State = 2 ) JTU
                             ON JS.Job = JTU.Job
                      WHERE JS.RunTime_Minutes > 30 AND
                            JS.State IN (4, 9)        -- Running or Running_Remote
                      GROUP BY JS.Job
                    ) RunningStepsQ
           ON Target.Job = RunningStepsQ.Job
    WHERE RunningStepsQ.RunTime_Predicted_Minutes > Target.Runtime_Predicted_Minutes
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    -----------------------------------------
    -- Compute the approximate time remaining for the job to finish
    -- We tack on 0.5 minutes for each uncompleted step, to account for the state machine aspect of the DMS_Pipeline database
    -----------------------------------------
    --
    UPDATE Tmp_JobsToUpdate
    SET ETA_Minutes = Runtime_Predicted_Minutes - CurrentRuntime_Minutes + (Steps - StepsCompleted) * 0.5
    FROM Tmp_JobsToUpdate Target

    /********************************************************************************
    ** This UPDATE query includes the target table name in the FROM clause
    ** The WHERE clause needs to have a self join to the target table, for example:
    **   UPDATE Tmp_JobsToUpdate
    **   SET ...
    **   FROM source
    **   WHERE source.id = Tmp_JobsToUpdate.id;
    ********************************************************************************/

                           ToDo: Fix this query

    WHERE Progress_New > 0
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _infoOnly Then
        -----------------------------------------
        -- Preview updated progress
        -----------------------------------------

        If Not _verbose Then
            -- Summarize the changes

            -- ToDo: Show this data using RAISE INFO

            SELECT State,
                   COUNT(*) AS Jobs,
                   Sum(CASE
                           WHEN Coalesce(Progress_Old, -10) <> Coalesce(Progress_New, -5) THEN 1
                           ELSE 0
                       End If;) AS Changed_Jobs,
                   MIN(Progress_New) AS Min_NewProgress,
                   MAX(Progress_New) AS Max_NewProgress
            FROM Tmp_JobsToUpdate
            GROUP BY State
            ORDER BY State
        Else
            -- Show all rows in Tmp_JobsToUpdate
            --
            SELECT *,
                   CASE
                       WHEN Coalesce(Progress_Old, 0) <> Coalesce(Progress_New, 0) THEN 1
                       ELSE 0
                   END AS Progress_Changed
            FROM Tmp_JobsToUpdate
            ORDER BY Job

        End If;

    Else

        -----------------------------------------
        -- Update the progress
        -----------------------------------------
        --
        UPDATE t_analysis_job
        SET progress = Src.Progress_New,
            eta_minutes = Src.eta_minutes
        FROM t_analysis_job Target

        /********************************************************************************
        ** This UPDATE query includes the target table name in the FROM clause
        ** The WHERE clause needs to have a self join to the target table, for example:
        **   UPDATE t_analysis_job
        **   SET ...
        **   FROM source
        **   WHERE source.id = t_analysis_job.id;
        ********************************************************************************/

                               ToDo: Fix this query

             INNER JOIN Tmp_JobsToUpdate Src
               ON Target.job = Src.Job
        WHERE Target.Progress IS NULL AND NOT Src.Progress_New IS NULL OR
              Coalesce(Target.Progress, 0) <> Coalesce(Src.Progress_New, 0) OR
              Target.job_state_id IN (4,7,14) AND (Target.Progress IS NULL Or Target.ETA_Minutes IS NULL)

    End If;

    DROP TABLE Tmp_JobsToUpdate;
END
$$;

COMMENT ON PROCEDURE public.update_job_progress IS 'UpdateJobProgress';
