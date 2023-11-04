--
-- Name: update_task_state(boolean, text, text, integer, integer, boolean); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.update_task_state(IN _bypassdms boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _maxjobstoprocess integer DEFAULT 0, IN _loopingupdateinterval integer DEFAULT 5, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Based on step state, look for capture task jobs that have been completed, or have entered the 'in progress' state.
**      For each, update state of the capture task job locally and the dataset in public.t_dataset accordingly
**
**      Evaluates state of steps for capture task jobs that have state New, In Progress, Failed, or Resuming,
**      and determines what the new capture task job state should be
**
**      Current                    Current                                     New
**      Capture Task Job           Capture Task Step                           Capture Task Job
**      State                      States                                      State
**      -----                      -------                                     ---------
**      New/In Progress/Resuming   One or more steps failed                    Failed
**
**      New/In Progress/Resuming   All steps skipped                           Skipped
**
**      New/In Progress/Resuming   All steps complete (or skipped)             Complete
**
**      New/In Progress/Resuming   One or more steps waiting/enabled/running   In Progress
**
**      Failed                     All steps complete (or skipped)             Complete
**
**      Failed                     All steps waiting/enabled/running           In Progress
**
**  Arguments:
**    _bypassDMS                When true, do not update states in tables in the public schema
**    _message text             Output message
**    _returnCode text          Output return code
**    _maxJobsToProcess         Maximum number of jobs to process
**    _loopingUpdateInterval    Seconds between detailed logging while looping through the dependencies
**    _infoOnly                 When true, preview changes
**
**  Auth:   grk
**  Date:   12/15/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          01/14/2010 grk - Removed path ID fields
**          05/04/2010 grk - Bypass DMS if dataset ID = 0
**          05/08/2010 grk - Update DMS sample prep if dataset ID = 0
**          05/05/2011 mem - Now updating capture task job state from Failed to Complete if all task steps are now complete and at least one of the task steps finished later than the Finish time in t_tasks
**          11/14/2011 mem - Now using >= instead of > when looking for capture task jobs to change from Failed to Complete because all task steps are now complete or skipped
**          01/16/2012 mem - Added overflow checks when using DateDiff to compute _processingTimeMinutes
**          11/05/2014 mem - Now looking for failed capture task jobs that should be changed to state 2 in t_tasks
**          11/11/2014 mem - Now looking for capture task jobs that are in progress, yet public.t_dataset_archive lists the archive or archive update operation as failed
**          11/04/2016 mem - Now looking for capture task jobs that are failed, yet should be listed as in progress
**                         - Only call copy_task_to_history if the new capture task job state is 3 or 5 and if not changing the state from 5 to 2
**                         - Add parameter _infoOnly
**                         - No longer computing _processingTimeMinutes since not stored in any table
**          01/23/2017 mem - Fix logic bug involving call to copy_task_to_history
**          06/13/2018 mem - Add comments regarding update_dms_file_info_xml and T_Dataset_Info
**          06/01/2020 mem - Add support for step state 13 (Inactive)
**          06/13/2023 mem - No longer call update_dms_prep_state
**          06/17/2023 mem - Update if statement to remove conditions that are always true
**                         - Ported to PostgreSQL
**          07/11/2023 mem - Use COUNT(TS.step) instead of COUNT(*)
**          09/07/2023 mem - Align assignment statements
**          11/01/2023 mem - If all steps for a capture task job have state 'skipped', set the task state to 'Skipped' (bcg)
**          11/04/2023 mem - When _infoOnly is true, update Finish_New for capture task jobs with state 15 (Skipped)
**
*****************************************************/
DECLARE
    _matchCount int := 0;
    _curJob int := 0;
    _done boolean;
    _jobInfo record;
    _jobCountToProcess int;
    _jobsProcessed int;
    _script text;
    _startMin timestamp;
    _finishMax timestamp;
    _updateCode int;
    _startTime timestamp;
    _lastLogTime timestamp;
    _statusMessage text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _bypassDMS             := Coalesce(_bypassDMS, false);
    _maxJobsToProcess      := Coalesce(_maxJobsToProcess, 0);
    _loopingUpdateInterval := Coalesce(_loopingUpdateInterval, 5);
    _infoOnly              := Coalesce(_infoOnly, false);

    If _loopingUpdateInterval < 2 Then
        _loopingUpdateInterval := 2;
    End If;

    _startTime := CURRENT_TIMESTAMP;

    If _infoOnly Then
        RAISE INFO '';
    End If;

    ---------------------------------------------------
    -- Table to hold state changes
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_ChangedJobs (
        Job int,
        OldState int,
        NewState int,
        Results_Folder_Name citext,
        Dataset_Name citext,
        Dataset_ID int,
        Script citext,
        Storage_Server citext,
        Start_New timestamp null,
        Finish_New timestamp null
    );

    CREATE INDEX IX_Tmp_ChangedJobs_Job ON Tmp_ChangedJobs (Job);

    ---------------------------------------------------
    -- Determine what current state of active capture task jobs should be
    -- and get list of the ones that need be changed
    ---------------------------------------------------

    INSERT INTO Tmp_ChangedJobs (
        Job,
        OldState,
        NewState,
        Results_Folder_Name,
        Dataset_Name,
        Dataset_ID,
        Script,
        Storage_Server
    )
    SELECT
        Job,
        OldState,
        NewState,
        Results_Folder_Name,
        Dataset,
        Dataset_ID,
        Script,
        Storage_Server
    FROM
    (
        -- Look at the state of steps for active or failed capture task jobs
        -- and determine what the new state of each capture task job should be
        SELECT
            T.Job,
            T.Dataset_ID,
            T.State As OldState,
            T.Results_Folder_Name,
            T.Storage_Server,
            CASE WHEN JS_Stats.Failed > 0 THEN 5                     -- New capture task job state: Failed
                 WHEN JS_Stats.Skipped = Total THEN 15               -- New capture task job state: Skipped
                 WHEN JS_Stats.FinishedOrSkipped = Total THEN 3      -- New capture task job state: Complete
                 WHEN JS_Stats.StartedFinishedOrSkipped > 0 THEN 2   -- New capture task job state: In Progress
                 ELSE T.State
            END AS NewState,
            T.Dataset,
            T.Script
        FROM
           (   -- Count the number of steps for each capture task job that are in specific states
               -- (for capture task jobs with state new, in progress, failed, or resuming)
               SELECT
                   TS.Job,
                   COUNT(TS.step) AS Total,
                   SUM(CASE WHEN TS.State IN (3, 4, 5, 13) THEN 1       -- Step state is 3=Skipped, 4=Running, 5=Completed, or 13=Inactive
                            ELSE 0
                       END) AS StartedFinishedOrSkipped,
                   SUM(CASE WHEN TS.State IN (6) THEN 1                 -- Step state is 6=Failed
                            ELSE 0
                       END) AS Failed,
                   SUM(CASE WHEN TS.State IN (3, 5, 13) THEN 1          -- Step state is 3=Skipped, 5=Completed, or 13=Inactive
                            ELSE 0
                       END) AS FinishedOrSkipped,
                   SUM(CASE WHEN TS.State IN (3, 13) THEN 1             -- Step state is 3=Skipped or 13=Inactive
                            ELSE 0
                       END) AS Skipped
               FROM cap.t_task_steps TS
                    INNER JOIN cap.t_tasks T
                      ON TS.Job = T.Job
               WHERE T.State IN (1, 2, 5, 20)     -- Current capture task job state: 1=New, 2=In Progress, 5=Failed, or 20=Resuming
               GROUP BY TS.Job, T.State
           ) AS JS_Stats
           INNER JOIN cap.t_tasks AS T
             ON JS_Stats.Job = T.Job
    ) UpdateQ
    WHERE UpdateQ.OldState <> UpdateQ.NewState;
    --
    GET DIAGNOSTICS _matchCount = ROW_COUNT;

    _jobCountToProcess := _matchCount;

    ---------------------------------------------------
    -- Find DatasetArchive and ArchiveUpdate tasks that are in progress,
    -- but for which DMS thinks that the operation has failed
    ---------------------------------------------------

    INSERT INTO Tmp_ChangedJobs (
        Job,
        OldState,
        NewState,
        Results_Folder_Name,
        Dataset_Name,
        Dataset_ID,
        Script,
        Storage_Server
    )
    SELECT T.Job,
           T.State As OldState,
           T.State As NewState,
           T.Results_Folder_Name,
           T.Dataset,
           T.Dataset_ID,
           T.Script,
           T.Storage_Server
    FROM cap.t_tasks T
         INNER JOIN V_DMS_Dataset_Archive_Status DAS
           ON T.Dataset_ID = DAS.Dataset_ID
         LEFT OUTER JOIN Tmp_ChangedJobs TargetTable
           ON T.Job = TargetTable.Job
    WHERE TargetTable.Job Is Null AND
          ( (T.Script = 'DatasetArchive' AND T.State = 2 AND DAS.Archive_State_ID = 6) OR
            (T.Script = 'ArchiveUpdate'  AND T.State = 2 AND DAS.Archive_Update_State_ID = 5) );
    --
    GET DIAGNOSTICS _matchCount = ROW_COUNT;

    _jobCountToProcess := _jobCountToProcess + _matchCount;

    ---------------------------------------------------
    -- Find failed capture task jobs that do not have any failed steps
    ---------------------------------------------------

    INSERT INTO Tmp_ChangedJobs(
        Job,
        OldState,
        NewState,
        Results_Folder_Name,
        Dataset_Name,
        Dataset_ID,
        Script,
        Storage_Server )

    SELECT Job,
           State AS OldState,
           2 AS NewState,
           Results_Folder_Name,
           Dataset,
           Dataset_ID,
           Script,
           Storage_Server
    FROM cap.t_tasks
    WHERE State = 5 AND
          Job IN ( SELECT Job FROM cap.t_task_steps WHERE state IN (2, 3, 4, 5, 13)) AND
          NOT Job IN (SELECT Job FROM cap.t_task_steps WHERE state = 6) AND
          NOT Job In (SELECT Job FROM Tmp_ChangedJobs);
    --
    GET DIAGNOSTICS _matchCount = ROW_COUNT;

    _jobCountToProcess := _jobCountToProcess + _matchCount;

    ---------------------------------------------------
    -- Loop through capture task jobs whose state has changed
    -- and update local state and DMS state
    ---------------------------------------------------

    _curJob := 0;
    _done := false;
    _jobsProcessed := 0;
    _lastLogTime := clock_timestamp();
    _script := '';

    WHILE _done = false
    LOOP
        SELECT Job,
               OldState,
               NewState,
               Results_Folder_Name,
               Script,
               Dataset_Name,
               Dataset_ID,
               Storage_Server
        INTO _jobInfo
        FROM Tmp_ChangedJobs
        WHERE Job > _curJob
        ORDER BY Job
        LIMIT 1;

        If Not FOUND Then
            -- Break out of the while loop
            EXIT;
        End If;

        _curJob := _jobInfo.Job;

        ---------------------------------------------------
        -- Examine the steps for this capture task job to determine actual start/end times
        ---------------------------------------------------

        _startMin := Null;
        _finishMax := Null;

        SELECT MIN(Start),
               MAX(Finish)
        INTO _startMin, _finishMax
        FROM cap.t_task_steps
        WHERE Job = _jobInfo.Job;

        ---------------------------------------------------
        -- Deprecated:
        -- Examine the steps for this capture task job to determine total processing time
        -- Steps with the same Step Tool name are assumed to be steps that can run in parallel;
        --   therefore, we use MAX(ProcessingTime) on steps with the same Step Tool name
        -- We use ABS(DATEDIFF(HOUR, start, xx)) to avoid overflows produced with
        --   DATEDIFF(SECOND, Start, xx) when Start and Finish are widely different
        ---------------------------------------------------
        /*
        SELECT SUM(SecondsElapsedMax) / 60.0
        INTO _processingTimeMinutes
        FROM ( SELECT Tool,
                      MAX(Coalesce(SecondsElapsed1, 0) + Coalesce(SecondsElapsed2, 0)) AS SecondsElapsedMax
               FROM ( SELECT Tool,
                             CASE
                                 WHEN ABS(DATEDIFF(HOUR, start, finish)) > 100000 THEN 360000000
                                 ELSE DATEDIFF(SECOND, Start, Finish)
                             END AS SecondsElapsed1,
                             CASE
                                 WHEN (NOT Start IS NULL) AND
                                      Finish IS NULL THEN
                                        CASE
                                            WHEN ABS(DATEDIFF(HOUR, start, CURRENT_TIMESTAMP)) > 100000 THEN 360000000
                                            ELSE DATEDIFF(SECOND, Start, CURRENT_TIMESTAMP)
                                        END
                                 ELSE NULL
                             END AS SecondsElapsed2
                      FROM cap.t_task_steps
                      WHERE Job = _jobInfo.Job
                      ) StatsQ
               GROUP BY Tool
               ) StepToolQ;

        _processingTimeMinutes := Coalesce(_processingTimeMinutes, 0);
        */

        If _infoOnly Then
            UPDATE Tmp_ChangedJobs Target
            SET Start_New =  CASE WHEN _jobInfo.NewState >= 2                   -- Capture task job state is 2 or higher
                                  THEN Coalesce(_startMin, CURRENT_TIMESTAMP)
                                  ELSE Src.Start
                             END,
                Finish_New = CASE WHEN _jobInfo.NewState IN (3, 5, 15)          -- Capture task job state is 3=Complete, 5=Failed, or 15=Skipped
                                  THEN _finishMax
                                  ELSE Src.Finish
                             END
            FROM cap.t_tasks Src
            WHERE Target.Job = _jobInfo.Job AND
                  Target.Job = Src.Job;

        Else
            ---------------------------------------------------
            -- Update local capture task job state and timestamp (if appropriate)
            ---------------------------------------------------

            UPDATE cap.t_tasks
            SET State  = _jobInfo.NewState,
                Start  = CASE WHEN _jobInfo.NewState >= 2                   -- Capture task job state is 2 or higher
                              THEN Coalesce(_startMin, CURRENT_TIMESTAMP)
                              ELSE Start
                         END,
                Finish = CASE WHEN _jobInfo.NewState IN (3, 5, 15)          -- Capture task job state is 3=Complete, 5=Failed, or 15=Skipped
                              THEN _finishMax
                              ELSE Finish
                         END
            WHERE Job = _jobInfo.Job;
        End If;

        ---------------------------------------------------
        -- Make changes to public.t_dataset and/or public.t_dataset_archive if we are enabled to do so
        -- Procedure update_dms_dataset_state will also call cap.update_dms_file_info_xml to push the data into public.t_dataset_info
        -- If a duplicate dataset is found, update_dms_dataset_state will change this capture task job's state to 14 in t_tasks
        ---------------------------------------------------

        If Not _bypassDMS And _jobInfo.Dataset_ID <> 0 Then

            If _infoOnly Then
                RAISE INFO 'Call update_dms_dataset_state Job=%, NewJobState=%', _jobInfo.Job, _jobInfo.NewState;
            Else
                CALL cap.update_dms_dataset_state(
                            _jobInfo.Job,
                            _jobInfo.Dataset_Name,
                            _jobInfo.Dataset_ID,
                            _jobInfo.Script,
                            _jobInfo.Storage_Server,
                            _jobInfo.NewState,
                            _message    => _message,      -- Output
                            _returnCode => _returnCode);  -- Output

                If _returnCode <> '' Then
                    CALL public.post_log_entry ('Error', _message, 'Update_Task_State', 'cap');
                End If;
            End If;

        End If;

        -- Deprecated in June 2023 since update_dms_prep_state only applies to script 'HPLCSequenceCapture', which was never implemented
        --
        -- If Not _bypassDMS And _jobInfo.DatasetID = 0 Then
        --     If _infoOnly Then
        --         RAISE INFO 'Call update_dms_prep_state Job=%, NewJobState=%', _jobInfo.Job, _jobInfo.NewState;
        --     Else
        --         CALL cap.update_dms_prep_state (
        --                     _jobInfo.Job,
        --                     _jobInfo.Script,
        --                     _jobInfo.NewState,
        --                     _message    => _message,
        --                     _returnCode => _returnCode);
        --
        --         If _returnCode <> '' Then
        --             CALL public.post_log_entry ('Error', _message, 'Update_Task_State', 'cap');
        --         End If;
        --     End If;
        -- End If;

        ---------------------------------------------------
        -- Save capture task job in the history tables
        ---------------------------------------------------

        If _jobInfo.NewState In (3, 5) Then

            If _infoOnly Then
                RAISE INFO 'Call copy_task_to_history     Job=%, NewState=%', _jobInfo.Job, _jobInfo.NewState;
            Else
                CALL cap.copy_task_to_history (
                            _jobInfo.Job,
                            _jobInfo.NewState,
                            _message    => _message,            -- Output
                            _returnCode => _returnCode);        -- Output

                If Coalesce(_returnCode, '') = '' Then
                    _message := '';
                Else
                    CALL public.post_log_entry ('Error', _message, 'Update_Task_State', 'cap');
                End If;
            End If;
        End If;

        _jobsProcessed := _jobsProcessed + 1;

        If extract(epoch FROM clock_timestamp() - _lastLogTime) >= _loopingUpdateInterval Then
            _statusMessage := format('... Updating capture task job state: %s / %s', _jobsProcessed, _jobCountToProcess);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Update_Task_State', 'cap');

            _lastLogTime := clock_timestamp();
        End If;

        If _maxJobsToProcess > 0 And _jobsProcessed >= _maxJobsToProcess Then
            _done := true;
        End If;

    END LOOP;

    If _infoOnly Then

        RAISE INFO '';

        _formatSpecifier := '%-9s %-9s %-9s %-20s %-10s %-20s %-20s %-80s';

        _infoHead := format(_formatSpecifier,
                            'Job',
                            'Old_State',
                            'New_State',
                            'Script',
                            'Dataset_ID',
                            'Start_New',
                            'Finish_New',
                            'Dataset_Name'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---------',
                                     '---------',
                                     '---------',
                                     '--------------------',
                                     '----------',
                                     '--------------------',
                                     '--------------------',
                                     '--------------------------------------------------------------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Job,
                   OldState,
                   NewState,
                   Script,
                   Dataset_ID,
                   timestamp_text(Start_New) AS Start_New,
                   timestamp_text(Finish_New) As Finish_New,
                   Dataset_Name
            FROM Tmp_ChangedJobs
            ORDER BY Job
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Job,
                                _previewData.OldState,
                                _previewData.NewState,
                                _previewData.Script,
                                _previewData.Dataset_ID,
                                _previewData.Start_New,
                                _previewData.Finish_New,
                                _previewData.Dataset_Name
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    End If;

    DROP TABLE Tmp_ChangedJobs;
END
$$;


ALTER PROCEDURE cap.update_task_state(IN _bypassdms boolean, INOUT _message text, INOUT _returncode text, IN _maxjobstoprocess integer, IN _loopingupdateinterval integer, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE update_task_state(IN _bypassdms boolean, INOUT _message text, INOUT _returncode text, IN _maxjobstoprocess integer, IN _loopingupdateinterval integer, IN _infoonly boolean); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.update_task_state(IN _bypassdms boolean, INOUT _message text, INOUT _returncode text, IN _maxjobstoprocess integer, IN _loopingupdateinterval integer, IN _infoonly boolean) IS 'UpdateTaskState Or UpdateJobState';

