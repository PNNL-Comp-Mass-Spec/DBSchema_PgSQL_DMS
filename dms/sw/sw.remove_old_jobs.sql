--
-- Name: remove_old_jobs(integer, integer, boolean, text, text, boolean, text, integer, boolean, boolean); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.remove_old_jobs(IN _intervaldaysforsuccess integer DEFAULT 45, IN _intervaldaysforfail integer DEFAULT 135, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _validatejobstepsuccess boolean DEFAULT false, IN _joblistoverride text DEFAULT ''::text, IN _maxjobstoprocess integer DEFAULT 25000, IN _logdeletions boolean DEFAULT false, IN _logtoconsoleonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete old jobs from sw.t_jobs, sw.t_job_steps, etc.
**
**  Arguments:
**    _intervalDaysForSuccess   Successful jobs must be this old to be deleted (0 -> no deletion)
**    _intervalDaysForFail      Failed jobs must be this old to be deleted (0 -> no deletion)
**    _infoOnly                 When true, preview deletes
**    _message                  Status message
**    _returnCode               Return code
**    _validateJobStepSuccess   When true, remove any jobs that have failed, in progress, or holding job steps
**    _jobListOverride          Comma-separated list of jobs to remove from T_Jobs, T_Job_Steps, and T_Job_Parameters
**    _maxJobsToProcess         Maximum number of jobs to process
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
**          08/08/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_integer_list for a comma-separated list
**          03/31/2024 mem - Assure that the newest 50 jobs with state Complete or 'No Intermediate Files Created' are not deleted
**
*****************************************************/
DECLARE
    _deleteCount int;
    _saveTime timestamp := CURRENT_TIMESTAMP;
    _cutoffDateTimeForSuccess timestamp;
    _cutoffDateTimeForFail timestamp;
    _jobInfo record;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    If Coalesce(_intervalDaysForSuccess, -1) < 0 Then
        _intervalDaysForSuccess := 0;
    End If;

    If Coalesce(_intervalDaysForFail, -1) < 0 Then
        _intervalDaysForFail := 0;
    End If;

    _jobListOverride        := Trim(Coalesce(_jobListOverride, ''));
    _maxJobsToProcess       := Coalesce(_maxJobsToProcess, 25000);
    _logDeletions           := Coalesce(_logDeletions, false);
    _logToConsoleOnly       := Coalesce(_logToConsoleOnly, false);
    _infoOnly               := Coalesce(_infoOnly, false);
    _validateJobStepSuccess := Coalesce(_validateJobStepSuccess, false);

    ---------------------------------------------------
    -- Create table to track the list of affected jobs
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Selected_Jobs (
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
    -- Make sure the job Start and Finish values are up-to-date
    ---------------------------------------------------

    CALL sw.synchronize_job_stats_with_job_steps (
                _infoOnly          => false,
                _completedJobsOnly => false,
                _message           => _message,         -- Output
                _returnCode        => _returnCode);     -- Output

    ---------------------------------------------------
    -- Add old successful jobs that should be deleted
    ---------------------------------------------------

    If _intervalDaysForSuccess > 0 Then

        _cutoffDateTimeForSuccess := CURRENT_TIMESTAMP - make_interval(days => _intervalDaysForSuccess);

        INSERT INTO Tmp_Selected_Jobs (job, state)
        SELECT job, state
        FROM sw.t_jobs
        WHERE state IN (4, 7) AND        -- 4=Complete, 7=No Intermediate Files Created
              Coalesce(finish, start) < _cutoffDateTimeForSuccess AND
              NOT job IN (SELECT T.job
                          FROM sw.t_jobs T
                          WHERE T.State IN (4, 7)
                          ORDER BY T.job DESC
                          LIMIT 50)
        ORDER BY finish
        LIMIT _maxJobsToProcess;

        If FOUND And _validateJobStepSuccess Then
            -- Remove any jobs that have failed, in progress, or holding job steps
            DELETE FROM Tmp_Selected_Jobs
            WHERE EXISTS (SELECT 1
                          FROM sw.t_job_steps JS
                          WHERE Tmp_Selected_Jobs.job = JS.job AND
                                NOT JS.state IN (3, 5));               -- 3=Skipped, 5=Complete
            --
            GET DIAGNOSTICS _deleteCount = ROW_COUNT;

            RAISE INFO '';

            If _deleteCount > 0 Then
                _message := format('Warning: Removed %s %s with one or more steps that are not skipped or complete',
                                    _deleteCount, public.check_plural(_deleteCount, 'job', 'jobs'));
                RAISE WARNING '%', _message;
            ElsIf _infoOnly Then
                RAISE INFO 'Successful jobs have been confirmed to all have successful (or skipped) steps';
            End If;
        End If;

    End If;

    ---------------------------------------------------
    -- Add old failed jobs that should be deleted
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
        WHERE job IN (SELECT DISTINCT Value
                      FROM public.parse_delimited_integer_list(_jobListOverride)) AND
              NOT job IN (SELECT job FROM Tmp_Selected_Jobs);
    End If;

    If Not Exists (SELECT job FROM Tmp_Selected_Jobs) Then
        If _infoOnly Then
            _message := 'Did not find any old jobs to delete';

            RAISE INFO '';
            RAISE INFO '%', _message;
        End If;

        DROP TABLE Tmp_Selected_Jobs;
        DROP TABLE Tmp_JobsNotInHistory;
        RETURN;
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

    If Exists (SELECT job FROM Tmp_JobsNotInHistory) Then

        UPDATE Tmp_JobsNotInHistory Target
        SET JobFinish = Coalesce(J.Finish, J.Start, CURRENT_TIMESTAMP)
        FROM sw.t_jobs J
        WHERE Target.job = J.job;

        If _infoOnly Then
            RAISE INFO '';
        End If;

        FOR _jobInfo IN
            SELECT Job AS JobToAdd,
                   State,
                   JobFinish AS SaveTimeOverride
            FROM Tmp_JobsNotInHistory
            WHERE Job > _jobToAdd
            ORDER BY Job
        LOOP
            If _infoOnly Then
                RAISE INFO 'Call sw.copy_job_to_history for job % with date %', _jobInfo.JobToAdd, public.timestamp_text(_jobInfo.SaveTimeOverride);
            Else
                CALL sw.copy_job_to_history (
                            _jobInfo.JobToAdd,
                            _jobInfo.State,
                            _overrideSaveTime => true,
                            _saveTimeOverride => _jobInfo.JobToAdd.SaveTimeOverride,
                            _message          => _message,          -- Output
                            _returnCode       => _returnCode);      -- Output
            End If;
        END LOOP;

    End If;

    ---------------------------------------------------
    -- Do actual deletion
    ---------------------------------------------------

    CALL sw.remove_selected_jobs (
                _infoOnly         => _infoOnly,
                _message          => _message,          -- Output
                _returncode       => _returncode,       -- Output
                _logDeletions     => _logDeletions,
                _logToConsoleOnly => _logToConsoleOnly);

    DROP TABLE Tmp_Selected_Jobs;
    DROP TABLE Tmp_JobsNotInHistory;
END
$$;


ALTER PROCEDURE sw.remove_old_jobs(IN _intervaldaysforsuccess integer, IN _intervaldaysforfail integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _validatejobstepsuccess boolean, IN _joblistoverride text, IN _maxjobstoprocess integer, IN _logdeletions boolean, IN _logtoconsoleonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE remove_old_jobs(IN _intervaldaysforsuccess integer, IN _intervaldaysforfail integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _validatejobstepsuccess boolean, IN _joblistoverride text, IN _maxjobstoprocess integer, IN _logdeletions boolean, IN _logtoconsoleonly boolean); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.remove_old_jobs(IN _intervaldaysforsuccess integer, IN _intervaldaysforfail integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _validatejobstepsuccess boolean, IN _joblistoverride text, IN _maxjobstoprocess integer, IN _logdeletions boolean, IN _logtoconsoleonly boolean) IS 'RemoveOldJobs';

