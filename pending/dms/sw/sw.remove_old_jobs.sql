--
CREATE OR REPLACE PROCEDURE sw.remove_old_jobs
(
    _intervalDaysForSuccess real = 45,
    _intervalDaysForFail int = 135,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _validateJobStepSuccess boolean = false,
    _jobListOverride text = '',
    _maxJobsToProcess int = 25000,
    _logDeletions boolean = false,
    _logToConsoleOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Delete jobs past their expiration date
**  from the main tables in the database
**
**  Arguments:
**    _intervalDaysForSuccess   Successful jobs must be this old to be deleted (0 -> no deletion)
**    _intervalDaysForFail      Failed jobs must be this old to be deleted (0 -> no deletion)
**    _validateJobStepSuccess   When true, remove any jobs that have failed, in progress, or holding job steps
**    _jobListOverride          Comma-separated list of jobs to remove from T_Jobs, T_Job_Steps, and T_Job_Parameters
**    _logDeletions             When true, logs each deleted job number in sw.T_Log_Entries
**    _logToConsoleOnly         When _logDeletions is true, optionally set this to true to only show deleted job info in the output console (via RAISE INFO messages)
**
**  Auth:   grk
**  Date:   12/18/2008 grk - Initial release
**          12/29/2008 mem - Updated to use Start time if Finish time is null and the Job has failed (State=5)
**          02/19/2009 grk - Added call to Remove_Selected_Jobs (Ticket #723)
**          02/26/2009 mem - Now passing _logDeletions = false to Remove_Selected_Jobs
**          05/31/2009 mem - Updated _intervalDaysForSuccess to support partial days (e.g. 0.5)
**          02/24/2012 mem - Added parameter _maxJobsToProcess with a default of 25000
**          08/20/2013 mem - Added parameter _logDeletions
**          03/10/2014 mem - Added call to Synchronize_Job_Stats_With_Job_Steps
**          01/18/2017 mem - Now counting job state 7 (No Intermediate Files Created) as Success
**          08/17/2021 mem - When looking for completed or inactive jobs, use the Start time if Finish is null
**                         - Also look for jobs with state 14 = Failed, Ignore Job Step States
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
    -- Create table to track the list of affected jobs
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Selected_Jobs (
        Job int not null,
        State int
    );

    CREATE INDEX IX_Tmp_Selected_Jobs_Job ON Tmp_Selected_Jobs (Job);

    CREATE TEMP TABLE Tmp_JobsNotInHistory (
        Job int not null,
        State int,
        JobFinish timestamp
    )

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

    _jobListOverride := Coalesce(_jobListOverride, '');

    _maxJobsToProcess := Coalesce(_maxJobsToProcess, 25000);
    _logDeletions := Coalesce(_logDeletions, false);
    _logToConsoleOnly := Coalesce(_logToConsoleOnly, false);

    _infoOnly := Coalesce(_infoOnly, false);
    _validateJobStepSuccess := Coalesce(_validateJobStepSuccess, false);

    ---------------------------------------------------
    -- Make sure the job Start and Finish values are up-to-date
    ---------------------------------------------------

    CALL sw.synchronize_job_stats_with_job_steps (_infoOnly => false);

    ---------------------------------------------------
    -- Add old successful jobs to be removed to list
    ---------------------------------------------------

    If _intervalDaysForSuccess > 0 Then

        _cutoffDateTimeForSuccess := CURRENT_TIMESTAMP - make_interval(days => _intervalDaysForSuccess);

        INSERT INTO Tmp_Selected_Jobs (job, state)
        SELECT TOP ( _maxJobsToProcess ) job, state
        FROM sw.t_jobs
        WHERE state IN (4, 7) AND        -- 4=Complete, 7=No Intermediate Files Created
              Coalesce(finish, start) < _cutoffDateTimeForSuccess
        ORDER BY finish;

        If _validateJobStepSuccess Then
            -- Remove any jobs that have failed, in progress, or holding job steps
            DELETE Tmp_Selected_Jobs
            FROM sw.t_job_steps JS
            WHERE Tmp_Selected_Jobs.job = JS.job AND
                  NOT JS.state IN (3, 5);
            --
            GET DIAGNOSTICS _deleteCount = ROW_COUNT;

            If _deleteCount > 0 Then
                _message := format('Warning: Removed %s %s with one or more steps that was not skipped or complete',
                                    _deleteCount, public.check_plural(_deleteCount, 'job', 'jobs'));
                RAISE WARNING '%', _message;
            Else
                RAISE INFO 'Successful jobs have been confirmed to all have successful (or skipped) steps';
            End If;
        End If;

    End If;

    ---------------------------------------------------
    -- Add old failed jobs to be removed to list
    ---------------------------------------------------

    If _intervalDaysForFail > 0 Then

        _cutoffDateTimeForFail := CURRENT_TIMESTAMP - make_interval(days => _intervalDaysForFail);

        INSERT INTO Tmp_Selected_Jobs (job, state)
        SELECT job,
               state
        FROM sw.t_jobs
        WHERE state IN (5, 14) AND            -- 5=Failed, 14=No Export
              Coalesce(finish, start) < _cutoffDateTimeForFail;

    End If;

    ---------------------------------------------------
    -- Add any jobs defined in _jobListOverride
    ---------------------------------------------------

    If _jobListOverride <> '' Then
        INSERT INTO Tmp_Selected_Jobs (job, state)
        SELECT job,
               state
        FROM sw.t_jobs
        WHERE job IN ( SELECT DISTINCT VALUE
                       FROM public.parse_delimited_integer_list ( _jobListOverride, ',' ) ) AND
              NOT job IN ( SELECT job FROM Tmp_Selected_Jobs )
    End If;

    ---------------------------------------------------
    -- Make sure the jobs to be deleted exist
    -- in sw.t_jobs_history and sw.t_job_steps_history
    ---------------------------------------------------

    INSERT INTO Tmp_JobsNotInHistory (job, state)
    SELECT Tmp_Selected_Jobs.job,
           Tmp_Selected_Jobs.state
    FROM Tmp_Selected_Jobs
         LEFT OUTER JOIN sw.t_jobs_history JH
           ON Tmp_Selected_Jobs.job = JH.job
    WHERE JH.job IS NULL;

    If Exists (Select * from Tmp_JobsNotInHistory) Then

        UPDATE Tmp_JobsNotInHistory Target
        SET JobFinish = Coalesce(J.Finish, J.Start, CURRENT_TIMESTAMP)
        FROM sw.t_jobs J
        WHERE Target.job = J.job;

        FOR _jobInfo IN
            SELECT Job As JobToAdd
                   State,
                   JobFinish Aa SaveTimeOverride
            FROM Tmp_JobsNotInHistory
            WHERE Job > _jobToAdd
            ORDER BY Job
        LOOP
            If _infoOnly Then
                RAISE INFO 'Call copy_job_to_history for job % with date %', _jobInfo.JobToAdd, public.timestamp_text(_jobInfo.SaveTimeOverride);
            Else
                CALL sw.copy_job_to_history (_jobInfo.JobToAdd, _jobInfo.State, _message => _message, _overrideSaveTime => true, _saveTimeOverride => _jobInfo.JobToAdd.SaveTimeOverride);
            End If;
        END LOOP;

    End If;

    ---------------------------------------------------
    -- Do actual deletion
    ---------------------------------------------------

    CALL sw.remove_selected_jobs (
            _infoOnly,
            _message => _message,
            _logDeletions => _logDeletions,
            _logToConsoleOnly => _logToConsoleOnly);

    DROP TABLE Tmp_Selected_Jobs;
    DROP TABLE Tmp_JobsNotInHistory;
END
$$;

COMMENT ON PROCEDURE sw.remove_old_jobs IS 'RemoveOldJobs';
