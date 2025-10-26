--
-- Name: remove_old_tasks(integer, integer, boolean, integer, boolean, boolean, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.remove_old_tasks(IN _intervaldaysforsuccess integer DEFAULT 60, IN _intervaldaysforfail integer DEFAULT 135, IN _logdeletions boolean DEFAULT false, IN _maxtaskstoremove integer DEFAULT 0, IN _validatejobstepsuccess boolean DEFAULT false, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete capture task jobs past their expiration date from tables t_tasks, t_task_steps, t_task_parameters, and t_task_step_dependencies
**
**      Assures that the capture task jobs are in the history tables before deleting
**
**  Arguments:
**    _intervalDaysForSuccess   Successful capture task jobs must be this old to be deleted (0 -> no deletion)
**    _intervalDaysForFail      Failed capture task jobs must be this old to be deleted (0 -> no deletion)
**    _logDeletions             When true, logs each deleted job number in cap.t_log_entries
**    _maxTasksToRemove         When non-zero, limit the number of tasks deleted to this value (order by job)
**    _validateJobStepSuccess   When true, do not delete tasks with any Failed, In Progress, or Holding task steps
**    _infoOnly                 When true, preview the tasks that would be deleted
**    _message                  Status message
**    _returnCode               Return code
**
**  Example usage:
**      CALL remove_old_tasks (
**               _intervalDaysForSuccess => 60,    _intervalDaysForFail => 135,
**               _logDeletions => false,           _maxTasksToRemove => 5,
**               _validateJobStepSuccess => false, _infoOnly => true);
**
**      CALL remove_old_tasks (
**               _intervalDaysForSuccess => 60,    _intervalDaysForFail => 135,
**               _logDeletions => false,           _maxTasksToRemove => 5,
**               _validateJobStepSuccess => false, _infoOnly => false);
**
**  Auth:   grk
**  Date:   09/12/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          06/21/2010 mem - Increased retention to 60 days for successful capture task jobs
**                         - Now removing capture task jobs with state Complete, Inactive, or Ignore
**          03/10/2014 mem - Added call to synchronize_task_stats_with_task_steps
**          01/23/2017 mem - Assure that capture task jobs exist in the history before deleting from t_tasks
**          08/17/2021 mem - When looking for completed or inactive capture task jobs, use Start time if Finish is null
**                         - Also look for capture task jobs with state 14 = Failed, Ignore Job Step States
**          06/22/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**          11/02/2023 mem - Also remove capture task jobs with state 15 = Skipped
**                         - Add argument _returnCode when calling copy_task_to_history
**          03/31/2024 mem - Assure that the newest 50 capture tasks with state Complete, Inactive, Skipped, or Ignore are not deleted
**          05/16/2025 mem - When finding old tasks, use the Imported date if Start and Finish are null
**
*****************************************************/
DECLARE
    _cutoffDateTimeForSuccess timestamp;
    _cutoffDateTimeForFail timestamp;
    _deleteCount int;
    _entryIdThreshold int;
    _jobInfo record;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Create table to track the list of affected capture task jobs
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Selected_Jobs (
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Job int NOT NULL,
        State int
    );

    CREATE INDEX IX_Tmp_Selected_Jobs_Job ON Tmp_Selected_Jobs (Job);

    CREATE TEMP TABLE Tmp_JobsNotInHistory (
        Job int NOT NULL,
        State int,
        JobFinish timestamp
    );

    CREATE INDEX IX_Tmp_JobsNotInHistory ON Tmp_JobsNotInHistory (Job);

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    If Coalesce(_intervalDaysForSuccess, -1) < 0 Then
        _intervalDaysForSuccess := 0;
    End If;

    If Coalesce(_intervalDaysForFail, -1) < 0 Then
        _intervalDaysForFail := 0;
    End If;

    _logDeletions           := Coalesce(_logDeletions, false);
    _maxTasksToRemove       := Coalesce(_maxTasksToRemove, 0);
    _validateJobStepSuccess := Coalesce(_validateJobStepSuccess, false);
    _infoOnly               := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Make sure the capture task job Start and Finish values are up-to-date
    ---------------------------------------------------

    CALL cap.synchronize_task_stats_with_task_steps (
                _infoOnly          => false,
                _completedjobsonly => false,
                _message           => _message);    -- Output

    ---------------------------------------------------
    -- Add old, successful, inactive, skipped, or ignored capture task jobs to the temp table
    ---------------------------------------------------

    If _intervalDaysForSuccess > 0 Then
        _cutoffDateTimeForSuccess := CURRENT_TIMESTAMP - make_interval(days => _intervalDaysForSuccess);

        If _infoOnly Then
            RAISE INFO '';
            RAISE INFO 'Finding capture task jobs with state 3, 4, 15, or 101 and Finish < %', public.timestamp_text(_cutoffDateTimeForSuccess);
        End If;

        INSERT INTO Tmp_Selected_Jobs (Job, State)
        SELECT Job, State
        FROM cap.t_tasks
        WHERE State IN (3, 4, 15, 101) AND    -- Complete, Inactive, Skipped, or Ignore
              Coalesce(Finish, Start, Imported) < _cutoffDateTimeForSuccess AND
              NOT job IN (SELECT T.job
                          FROM cap.t_tasks T
                          WHERE T.State IN (3, 4, 15, 101)
                          ORDER BY T.job DESC
                          LIMIT 50)
        ORDER BY job;

        If _validateJobStepSuccess Then
            -- Remove any capture task jobs that have Running, Failed, or Holding job steps
            DELETE FROM Tmp_Selected_Jobs
            WHERE Job IN (SELECT TS.Job
                          FROM cap.t_task_steps TS
                          WHERE TS.State IN (4, 6, 7) AND
                                TS.Job = Tmp_Selected_Jobs.Job);
            --
            GET DIAGNOSTICS _deleteCount = ROW_COUNT;

            If FOUND Then
                RAISE INFO 'Warning: Removed % capture task % with one or more steps that were not skipped or complete', _deleteCount, public.check_plural(_deleteCount, 'job', 'jobs');
            Else
                RAISE INFO 'Successful capture task jobs have been confirmed to all have successful (or skipped) steps';
            End If;
        End If;
    End If;

    ---------------------------------------------------
    -- Add old, failed capture task jobs to the temp table
    ---------------------------------------------------

    If _intervalDaysForFail > 0 Then
        _cutoffDateTimeForFail := CURRENT_TIMESTAMP - make_interval(days => _intervalDaysForFail);

        If _infoOnly Then
            RAISE INFO '';
            RAISE INFO 'Finding capture task jobs with state 5 or 14          and Finish < %', public.timestamp_text(_cutoffDateTimeForFail);
        End If;

        INSERT INTO Tmp_Selected_Jobs (Job, State)
        SELECT Job, State
        FROM cap.t_tasks
        WHERE State IN (5, 14) AND            -- 'Failed' or 'Failed, Ignore Job Step States'
              Coalesce(Finish, Start) < _cutoffDateTimeForFail
        ORDER BY job;
    End If;

    If _maxTasksToRemove > 0 Then
        SELECT MAX(Entry_ID)
        INTO _entryIdThreshold
        FROM (SELECT Entry_ID
              FROM Tmp_Selected_Jobs
              ORDER BY job
              LIMIT _maxTasksToRemove) FilterQ;

        DELETE FROM Tmp_Selected_Jobs
        WHERE Entry_ID > _entryIdThreshold;
    End If;

    ---------------------------------------------------
    -- Make sure the capture task jobs to be deleted exist
    -- in t_tasks_history and t_task_steps_history
    ---------------------------------------------------

    INSERT INTO Tmp_JobsNotInHistory (Job, State)
    SELECT Tmp_Selected_Jobs.Job,
           Tmp_Selected_Jobs.State
    FROM Tmp_Selected_Jobs
         LEFT OUTER JOIN cap.t_tasks_history JH
           ON Tmp_Selected_Jobs.Job = JH.Job
    WHERE JH.Job IS NULL;

    If Exists (SELECT Job FROM Tmp_JobsNotInHistory) Then
        If _infoOnly Then
            RAISE INFO '';
        End If;

        UPDATE Tmp_JobsNotInHistory Target
        SET JobFinish = Coalesce(T.Finish, T.Start, T.Imported, CURRENT_TIMESTAMP)
        FROM cap.t_tasks T
        WHERE Target.Job = T.Job;

        FOR _jobInfo IN
            SELECT Job AS JobToAdd,
                   State,
                   JobFinish AS SaveTimeOverride
            FROM Tmp_JobsNotInHistory
            ORDER BY Job
        LOOP
            If _infoOnly Then
                RAISE INFO 'Call copy_task_to_history for capture task job % with state % and date %', _jobInfo.JobToAdd, _jobInfo.State, _jobInfo.SaveTimeOverride;
            Else
                CALL cap.copy_task_to_history (
                            _jobInfo.JobToAdd,
                            _jobInfo.State,
                            _overrideSaveTime => true,
                            _saveTimeOverride => _jobInfo.SaveTimeOverride,
                            _message          => _message,          -- Output
                            _returnCode       => _returnCode);      -- Output

                If Coalesce(_returnCode, '') = '' Then
                    _message := '';
                Else
                    CALL public.post_log_entry ('Error', _message, 'Remove_Old_Tasks', 'cap');
                End If;

            End If;
        END LOOP;
    End If;

    ---------------------------------------------------
    -- Do actual deletion
    ---------------------------------------------------

    CALL cap.remove_selected_tasks (
                _infoOnly,
                _logDeletions => _logDeletions,
                _message      => _message,      -- Output
                _returnCode   => _returnCode);  -- Output

    DROP TABLE Tmp_Selected_Jobs;
    DROP TABLE Tmp_JobsNotInHistory;
END
$$;


ALTER PROCEDURE cap.remove_old_tasks(IN _intervaldaysforsuccess integer, IN _intervaldaysforfail integer, IN _logdeletions boolean, IN _maxtaskstoremove integer, IN _validatejobstepsuccess boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE remove_old_tasks(IN _intervaldaysforsuccess integer, IN _intervaldaysforfail integer, IN _logdeletions boolean, IN _maxtaskstoremove integer, IN _validatejobstepsuccess boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.remove_old_tasks(IN _intervaldaysforsuccess integer, IN _intervaldaysforfail integer, IN _logdeletions boolean, IN _maxtaskstoremove integer, IN _validatejobstepsuccess boolean, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'RemoveOldTasks or RemoveOldJobs';

