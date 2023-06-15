--
CREATE OR REPLACE PROCEDURE cap.remove_old_tasks
(
    _intervalDaysForSuccess numeric = 60,
    _intervalDaysForFail int = 135,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _validateJobStepSuccess boolean
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Delete capture task jobs past their expiration date
**  from the main tables in the database
**
**  Arguments:
**    _intervalDaysForSuccess   Successful capture task jobs must be this old to be deleted (0 -> no deletion)
**    _intervalDaysForFail      Failed capture task jobs must be this old to be deleted (0 -> no deletion)
**
**  Auth:   grk
**  Date:   09/12/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          06/21/2010 mem - Increased retention to 60 days for successful capture task jobs
**                         - Now removing capture task jobs with state Complete, Inactive, or Ignore
**          03/10/2014 mem - Added call to synchronize_task_stats_with_task_steps
**          01/23/2017 mem - Assure that capture task jobs exist in the history before deleting from t_tasks
**          08/17/2021 mem - When looking for completed or inactive capture task jobs, use the Start time if Finish is null
**                         - Also look for capture task jobs with state 14 = Failed, Ignore Job Step States
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _deleteCount int;
    _saveTime timestamp := CURRENT_TIMESTAMP;
    _cutoffDateTimeForSuccess timestamp;
    _cutoffDateTimeForFail timestamp;
    _jobInfo record
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Create table to track the list of affected capture task jobs
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Selected_Jobs (
        Job int not null,
        State int
    )

    CREATE INDEX IX_Tmp_Selected_Jobs_Job ON Tmp_Selected_Jobs (Job)

    CREATE TEMP TABLE Tmp_JobsNotInHistory (
        Job int not null,
        State int,
        JobFinish timestamp
    )

    CREATE INDEX IX_Tmp_JobsNotInHistory ON Tmp_JobsNotInHistory (Job)

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    If Coalesce(_intervalDaysForSuccess, -1) < 0 Then
        _intervalDaysForSuccess := 0;
    End If;

    If Coalesce(_intervalDaysForFail, -1) < 0 Then
        _intervalDaysForFail := 0;
    End If;

    _infoOnly := Coalesce(_infoOnly, false);
    _validateJobStepSuccess := Coalesce(_validateJobStepSuccess, false);

    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Make sure the capture task job Start and Finish values are up-to-date
    ---------------------------------------------------

    CALL cap.synchronize_task_stats_with_task_steps (_infoOnly => false);

    ---------------------------------------------------
    -- Add old successful capture task jobs to be removed to list
    ---------------------------------------------------

    If _intervalDaysForSuccess > 0 Then

        _cutoffDateTimeForSuccess := CURRENT_TIMESTAMP - make_interval(days => _intervalDaysForSuccess);

        INSERT INTO Tmp_Selected_Jobs (Job, State)
        SELECT Job, State
        FROM cap.t_tasks
        WHERE State IN (3, 4, 101) And    -- Complete, Inactive, or Ignore
              Coalesce(Finish, Start) < _cutoffDateTimeForSuccess;

        If _validateJobStepSuccess Then
            -- Remove any capture task jobs that have failed, in progress, or holding job steps
            DELETE FROM Tmp_Selected_Jobs
            WHERE Job In (SELECT Job
                          FROM cap.t_task_steps TS
                          WHERE NOT TS.State IN (4, 6, 7) AND
                                TS.Job = Tmp_Selected_Jobs.Job);
            --
            GET DIAGNOSTICS _deleteCount = ROW_COUNT;

            If FOUND Then
                RAISE INFO 'Warning: Removed % capture task job(s) with one or more steps that were not skipped or complete', _deleteCount;
            Else
                RAISE INFO 'Successful capture task jobs have been confirmed to all have successful (or skipped) steps';
            End If;
        End If;

    End If;

    ---------------------------------------------------
    -- Add old failed capture task jobs to be removed to list
    ---------------------------------------------------

    If _intervalDaysForFail > 0 Then
        _cutoffDateTimeForFail := CURRENT_TIMESTAMP - make_interval(days => _intervalDaysForFail);

        INSERT INTO Tmp_Selected_Jobs (Job, State)
        SELECT Job, State
        FROM cap.t_tasks
        WHERE State In (5, 14) AND            -- 'Failed' or 'Failed, Ignore Job Step States'
              Coalesce(Finish, Start) < _cutoffDateTimeForFail;
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

    If Exists (Select * from Tmp_JobsNotInHistory) Then

        UPDATE Tmp_JobsNotInHistory Target
        SET JobFinish = Coalesce(T.Finish, T.Start, CURRENT_TIMESTAMP)
        FROM cap.t_tasks T
        WHERE Target.Job = T.Job;

        FOR _jobInfo IN
            SELECT Job As JobToAdd,
                   State,
                   JobFinish AS SaveTimeOverride
            FROM Tmp_JobsNotInHistory
            ORDER BY Job
        LOOP
            If _infoOnly Then
                RAISE INFO 'Call copy_task_to_history for capture task job % with date %', _jobInfo.JobToAdd, _jobInfo.SaveTimeOverride;
            Else
                CALL cap.copy_task_to_history (_jobInfo.JobToAdd,
                                               _jobInfo.State,
                                               _message => _message,
                                               _overrideSaveTime => true,
                                               _saveTimeOverride => _jobInfo.SaveTimeOverride);
            End If;
        END LOOP;
    End If;

    ---------------------------------------------------
    -- Do actual deletion
    ---------------------------------------------------

    CALL cap.remove_selected_tasks (_infoOnly, _message => _message, _logDeletions => false);

    DROP TABLE Tmp_Selected_Jobs;
    DROP TABLE Tmp_JobsNotInHistory;
END
$$;

COMMENT ON PROCEDURE cap.remove_old_tasks IS 'RemoveOldJobs';
