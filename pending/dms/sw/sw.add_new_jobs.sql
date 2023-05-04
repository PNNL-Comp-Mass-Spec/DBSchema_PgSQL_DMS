--
CREATE OR REPLACE PROCEDURE sw.add_new_jobs
(
    _bypassDMS boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _maxJobsToProcess int = 0,
    _logIntervalThreshold int = 15,
    _loggingEnabled boolean = false,
    _loopingUpdateInterval int = 5,
    _infoOnly boolean = false,
    _infoLevel int = 0,
    _debugMode boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Add jobs from DMS that are in 'New' state that aren't
**      already in table.  Choose script for DMS analysis tool.
**
**      Suspend running jobs that now have state 'Holding' in DMS
**
**      Finally, reset failed or holding jobs that are now state 'New' in DMS
**
**  DMS       Broker           Action by broker
**  Job       Job
**  State     State
**  -----     ------           ---------------------------------------
**  New       (job not         Import job:
**             in broker)      - Add it to local job table
**                             - Set local job state to freshly imported
**                               (CreateJobSteps will set local state to New)
**
**  New       failed           Resume job:
**            holding          - Reset any failed/holding job steps to waiting
**                             - Reset Evaluated and Triggered to 0 in T_Job_Step_Dependencies for the affected steps
**                             - Set local job state to 'resuming'
**                               (UpdateJobState will handle final job state update)
**                               (UpdateDependentSteps will handle final job step state updates)
**
**  New       complete         Reset job:
**                             - Delete entries from job, steps, parameters, and dependencies tables
**                             - Set local job state to freshly imported (see import job above)
**
**  New       holding          Resume job: (see description above)
**
**  holding   (any state)      Suspend Job:
**                            - Set local job state to holding
**
**
**  Arguments:
**    _bypassDMS                If true, the logic in this procedure is completely bypassed
**    _logIntervalThreshold     If this procedure runs longer than this threshold, status messages will be posted to the log
**    _loggingEnabled           Set to true to immediately enable progress logging; if false, logging will auto-enable if _logIntervalThreshold seconds elapse
**    _loopingUpdateInterval    Seconds between detailed logging while looping through the dependencies
**    _infoOnly                 True to preview changes that would be made
**    _infoLevel                When _infoOnly is true, 1 to preview changes, 2 to add new jobs but do not create job steps
**    _debugMode                False for no debugging; true to see debug messages
**
**  Auth:   grk
**  Date:   08/25/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          09/25/2008 grk - Added filtering to only add new jobs that match currently active scripts
**          12/05/2008 mem - Now populating Transfer_Folder_Path in T_Jobs
**          12/09/2008 grk - Clarified comment description of how DMS state affects broker
**          01/07/2009 mem - Updated job resume logic to match steps with state of 6 or 7 in T_Job_Steps; also updated to match jobs with state of 5 or 8 in T_Jobs
**          01/17/2009 mem - Moved updating of T_Jobs.Archive_Busy to SyncJobInfo (Ticket #716, http://prismtrac.pnl.gov/trac/ticket/716)
**          02/12/2009 mem - Updated job resume logic to change step states from 6 or 7 to 1=waiting (instead of 2=enabled) and to reset Evaluated and Triggered to 0 in T_Job_Step_Dependencies for the affected steps
**                         - Added parameter _debugMode
**          03/02/2009 grk - added code to update job parameters when jobs are resumed (from hold or fail)
**          03/11/2009 mem - Now also resetting jobs if they are running or failed, but do not have any running or completed job steps (Ticket #725, http://prismtrac.pnl.gov/trac/ticket/725)
**          06/01/2009 mem - Moved the job resuming updates to occur outside the transaction (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**                         - Added parameter _maxJobsToProcess
**          06/03/2009 mem - Now updating Transfer_Folder_Path when resuming a job
**          06/04/2009 mem - Added parameters _logIntervalThreshold, _loggingEnabled, and _loopingUpdateInterval
**          07/29/2009 mem - Now populating Comment in T_Jobs
**          03/03/2010 mem - Now populating Storage_Server in T_Jobs
**          03/21/2011 mem - Added parameter _infoOnly and moved position of parameter _debugMode
**                         - Now calling UpdateInputFolderUsingSourceJobComment if needed when resuming jobs
**          04/04/2011 mem - Now populating Special_Processing in T_Jobs
**                         - Removed call to UpdateInputFolderUsingSourceJobComment
**                         - Now using function GetJobParamTableLocal() to lookup a value in T_Job_Parameters
**          07/05/2011 mem - Now updating Tool_Version_ID when resetting job steps
**          07/12/2011 mem - Now calling ValidateJobServerInfo
**          01/09/2012 mem - Now populating Owner in T_Jobs
**          01/12/2012 mem - Now only auto-adding jobs for scripts with Backfill_to_DMS = 0
**          01/19/2012 mem - Now populating DataPkgID in T_Jobs
**          04/28/2014 mem - Bumped up _maxJobsToAddResetOrResume from 1 million to 1 billion
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          11/07/2014 mem - No longer performing a full job reset for ICR2LS or LTQ_FTPek jobs where the job state is failed but the DMS state is new
**          01/04/2016 mem - Truncate the job comment at the first semicolon for failed jobs being reset
**          05/12/2017 mem - Update Next_Try and Remote_Info_ID
**`         03/30/2018 mem - Add support for job step states 9=Running_Remote, 10=Holding_Staging, and 16=Failed_Remote
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _job int;
    _jobsProcessed int;
    _jobCountToResume int;
    _jobCountToReset int;
    _resumeUpdatesRequired boolean;
    _maxJobsToAddResetOrResume int;
    _startTime timestamp;
    _lastLogTime timestamp;
    _statusMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    _resumeUpdatesRequired := false;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --
    _infoOnly := Coalesce(_infoOnly, false);
    _infoLevel := Coalesce(_infoLevel, 0);

    _bypassDMS := Coalesce(_bypassDMS, false);
    _debugMode := Coalesce(_debugMode, false);

    _maxJobsToProcess := Coalesce(_maxJobsToProcess, 0);

    _message := '';
    _returnCode:= '';

    If _bypassDMS Then
        RETURN;
    End If;

    If _maxJobsToProcess <= 0 Then
        _maxJobsToAddResetOrResume := 1000000000;
    Else
        _maxJobsToAddResetOrResume := _maxJobsToProcess;
    End If;

    _startTime := CURRENT_TIMESTAMP;
    _loggingEnabled := Coalesce(_loggingEnabled, false);
    _logIntervalThreshold := Coalesce(_logIntervalThreshold, 15);
    _loopingUpdateInterval := Coalesce(_loopingUpdateInterval, 5);

    If _logIntervalThreshold = 0 Then
        _loggingEnabled := true;
    End If;

    If _loopingUpdateInterval < 2 Then
        _loopingUpdateInterval := 2;
    End If;

    ---------------------------------------------------
    -- Temp table to hold jobs from DMS to process
    ---------------------------------------------------
    --
    CREATE TEMP TABLE Tmp_DMSJobs (
        Job int,
        Priority int,
        Script citext,
        Dataset citext,
        Dataset_ID int,
        Results_Directory_Name citext,
        State int,
        Transfer_Folder_Path citext,
        Comment citext,
        Special_Processing citext,
        Owner_Username citext
    );

    CREATE INDEX IX_Tmp_DMSJobs_Job ON Tmp_DMSJobs (Job);

    ---------------------------------------------------
    -- Get list of new or held jobs from DMS
    --
    -- Data comes from view V_Get_Pipeline_Jobs,
    -- which shows new jobs in state 1 or 8 but it
    -- excludes jobs that have recently been archived
    ---------------------------------------------------
    --
    INSERT INTO Tmp_DMSJobs( Job,
                             Priority,
                             script,
                             Dataset,
                             Dataset_ID,
                             State,
                             Transfer_Folder_Path,
                             Comment,
                             Special_Processing,
                             Owner_Username )
    SELECT Job,
           Priority,
           Tool,
           Dataset,
           Dataset_ID,
           State,
           Transfer_Folder_Path,
           Comment,
           Special_Processing,
           Owner
    FROM V_Get_Pipeline_Jobs AS VGP
    WHERE Tool IN ( SELECT script
                    FROM sw.t_scripts
                    WHERE enabled = 'Y' );

    If NOT FOUND Then
        -- No new or held jobs were found in DMS

        If _debugMode Then
            RAISE INFO 'No New or held jobs found in DMS';
        End If;

        -- Exit this procedure
        DROP TABLE Tmp_DMSJobs;
        RETURN;
    End If;

    -- New or held jobs are available
    If _debugMode Then
        INSERT INTO Tmp_JobDebugMessages (Message, Job, Script, DMS_State, PipelineState);
        SELECT 'New or Held Jobs', J.job, J.script, J.state, T.state
        FROM Tmp_DMSJobs J
             LEFT OUTER JOIN sw.t_jobs T
               ON J.job = T.job
        ORDER BY job;
    End If;

    ---------------------------------------------------
    -- Find jobs to reset
    ---------------------------------------------------
    --
    If _loggingEnabled Or extract(epoch FROM (clock_timestamp() - _startTime)) >= _logIntervalThreshold Then
        _loggingEnabled := true;
        _statusMessage := 'Finding jobs to reset';
        Call public.post_log_entry ('Progress', _statusMessage, 'Add_New_Jobs', 'sw');
    End If;

    -- Additional temp tables
    CREATE TEMP TABLE Tmp_ResetJobs (
        Job int
    )

    CREATE INDEX IX_Tmp_ResetJobs_Job ON Tmp_ResetJobs (Job);

    CREATE TEMP TABLE Tmp_JobsToResumeOrReset (
        Job int,
        Dataset text,
        FailedJob int
    )

    CREATE INDEX IX_Tmp_ResumedJobs_Job ON Tmp_JobsToResumeOrReset (Job);

    CREATE TEMP TABLE Tmp_JobDebugMessages (
        Message text,
        Job int,
        Script text,
        DMS_State int,
        PipelineState int,
        EntryID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY
    )

    CREATE INDEX IX_Tmp_JobDebugMessages_Job ON Tmp_JobDebugMessages (Job);

    -- Start transaction #1
    --
    BEGIN

        ---------------------------------------------------
        -- Reset job:
        -- delete existing job info from database
        ---------------------------------------------------
        --
        -- Find jobs that are complete in the broker, but in state 1=New in DMS
        --
        --
        INSERT INTO Tmp_ResetJobs (job)
        SELECT T.job
        FROM Tmp_DMSJobs T
             INNER JOIN sw.t_jobs
               ON T.job = sw.t_jobs.job
        WHERE sw.t_jobs.state = 4 AND            -- Complete in the broker
              T.state = 1                        -- New in DMS
        --
        GET DIAGNOSTICS _jobCountToReset = ROW_COUNT;

        If _jobCountToReset > 0 Then
            _statusMessage := 'Resetting %s completed %s', _jobCountToReset, public.check_plural(_jobCountToReset, 'job', 'jobs');

            Call public.post_log_entry ('Progress', _statusMessage, 'Add_New_Jobs', 'sw');
        End If;

        -- Also look for jobs where the DMS state is 'New', the broker state is 2, 5, or 8 (In Progress, Failed, or Holding),
        -- and none of the jobs Steps have completed or are running

        -- It is typically safer to perform a full reset on these jobs (rather than a resume) in case an admin changed the settings file for the job
        -- Exception: LTQ_FTPek and ICR2LS jobs because ICR-2LS runs as the first step and we create checkpoint copies of the .PEK files to allow for a resume
        --
        INSERT INTO Tmp_ResetJobs (job)
        SELECT T.job
        FROM Tmp_DMSJobs T
             INNER JOIN sw.t_jobs
               ON T.job = sw.t_jobs.job
             LEFT OUTER JOIN ( SELECT J.job
                               FROM sw.t_jobs J
                                    INNER JOIN sw.t_job_steps JS
                                      ON J.job = JS.job
                               WHERE (J.state IN (2, 5, 8)) AND   -- Jobs that are running, failed, or holding
                                     (JS.state IN (4, 5, 9))      -- Steps that are running or finished (but not failed or holding)
                              ) LookupQ
         ON sw.t_jobs.job = LookupQ.job
        WHERE (sw.t_jobs.state IN (2, 5, 8)) AND
              (NOT T.script IN ('LTQ_FTPek','ICR2LS')) AND
              (LookupQ.job IS NULL)                       -- Assure there are no running or finished steps
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount > 0 Then
            _jobCountToReset := _jobCountToReset + _myRowCount;

            _statusMessage := 'Resetting ' || _myRowCount::text || ' job';
            If _myRowCount <> 1 Then
                _statusMessage := _statusMessage || 's that are In Progress, Failed, or Holding and have no completed or running job steps';
            Else
                _statusMessage := _statusMessage || ' that is In Progress, Failed, or Holding and has no completed or running job steps';
            End If;

            Call public.post_log_entry ('Progress', _statusMessage, 'Add_New_Jobs', 'sw');
        End If;

        If _jobCountToReset = 0 Then
            If _debugMode Then
                INSERT INTO Tmp_JobDebugMessages (Message, Job);
                VALUES ('No Jobs to Reset', 0);
            End If;
        Else
        --<Reset>

            If _maxJobsToProcess > 0 Then
                -- Limit the number of jobs to reset
                DELETE FROM Tmp_ResetJobs
                WHERE NOT Job IN ( SELECT TOP ( _maxJobsToProcess ) Job
                                FROM Tmp_ResetJobs
                                ORDER BY Job )
            End If;

            If _debugMode Then
                INSERT INTO Tmp_JobDebugMessages (Message, job, script, DMS_State, PipelineState)
                SELECT 'Jobs to Reset', J.job, J.script, J.state, T.state
                FROM Tmp_ResetJobs R INNER JOIN Tmp_DMSJobs J ON R.job = J.job
                     INNER JOIN sw.t_jobs T ON J.job = T.job
                ORDER BY job
            Else
            -- <ResetDeletes>

                ---------------------------------------------------
                -- Set up and populate temp table and call sproc
                -- to delete jobs listed in it
                ---------------------------------------------------
                --
                CREATE TEMP TABLE Tmp_SJL (Job int);

                CREATE INDEX IX_Tmp_SJL_Job ON Tmp_SJL (Job);
                --
                INSERT INTO SJL (Job)
                SELECT Job FROM Tmp_ResetJobs
                --
                Call sw.remove_selected_jobs (
                        _infoOnly,
                        _message => _message,
                        _logDeletions => false);

            End If; -- </ResetDeletes>
        End If; --</Reset>

        If Not _infoOnly Or _infoOnly And _infoLevel = 2 Then
            -- <ImportNewJobs>

            If _loggingEnabled Or extract(epoch FROM (clock_timestamp() - _startTime)) >= _logIntervalThreshold Then
                _loggingEnabled := true;
                _statusMessage := 'Adding new jobs to sw.t_jobs';
                Call public.post_log_entry ('Progress', _statusMessage, 'Add_New_Jobs', 'sw');
            End If;

            ---------------------------------------------------
            -- Import job:
            -- Copy new jobs from DMS that are not already in table
            -- (only take jobs that have script that is currently active)
            ---------------------------------------------------
            --
            INSERT INTO sw.t_jobs
                (job, priority, script, State, Dataset, Dataset_ID, Transfer_Folder_Path,
                comment, special_processing, storage_server, owner_username, DataPkgID)
            SELECT TOP (_maxJobsToAddResetOrResume)
                DJ.job, DJ.priority, DJ.script, 0 as State, DJ.Dataset, DJ.Dataset_ID, DJ.Transfer_Folder_Path,
                DJ.comment, DJ.special_processing, sw.extract_server_name(DJ.transfer_folder_path) AS Storage_Server, DJ.Owner_Username, 0 AS DataPkgID
            FROM Tmp_DMSJobs DJ
                 INNER JOIN sw.t_scripts S
                   ON DJ.script = S.script
            WHERE state = 1 AND
                  job NOT IN ( SELECT job FROM sw.t_jobs ) AND
                  S.enabled = 'Y' AND
                  S.backfill_to_dms = 0
            ORDER BY job
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;
        End If; -- </ImportNewJobs>

        ---------------------------------------------------
        -- Find jobs to Resume or Reset
        --
        -- Jobs that are reset in DMS will be in 'new' state, but
        -- there will be a entry for the job in the local
        -- table that is in the 'failed' or 'holding' state.
        -- For all such jobs, set all steps that are in 'failed'
        -- state to the 'waiting' state and set the job
        -- state to 'resuming'.
        ---------------------------------------------------
        --
        If _loggingEnabled Or extract(epoch FROM (clock_timestamp() - _startTime)) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := 'Finding jobs to Resume';
            Call public.post_log_entry ('Progress', _statusMessage, 'Add_New_Jobs', 'sw');
        End If;

        INSERT INTO Tmp_JobsToResumeOrReset (job, dataset, FailedJob)
        SELECT TOP ( _maxJobsToAddResetOrResume )
               J.job,
               J.dataset,
               CASE WHEN J.state = 5 THEN 1 ELSE 0 END AS FailedJob
        FROM sw.t_jobs J
        WHERE (J.state IN (5, 8)) AND                    -- 5=Failed, 8=Holding
              (J.job IN (SELECT job FROM Tmp_DMSJobs WHERE state = 1))
        --
        GET DIAGNOSTICS _jobCountToResume = ROW_COUNT;

        If _jobCountToResume = 0 Then
            If _debugMode Then
                INSERT INTO Tmp_JobDebugMessages (Message, Job);
                VALUES ('No Jobs to Resume', 0);
            End If;
        Else
        --<ResumeOrReset>

            If _debugMode Then
                INSERT INTO Tmp_JobDebugMessages (Message, job, script, DMS_State, PipelineState)
                SELECT 'Jobs to Resume', J.job, J.script, J.state, T.state
                FROM Tmp_JobsToResumeOrReset R
                     INNER JOIN Tmp_DMSJobs J
                       ON R.job = J.job
                     INNER JOIN sw.t_jobs T
                       ON J.job = T.job
                ORDER BY job;
            Else
                _resumeUpdatesRequired := true;
            End If;
        End If; -- </ResumeOrReset>

        If _debugMode Then
            INSERT INTO Tmp_JobDebugMessages (Message, job, script, DMS_State, PipelineState)
            SELECT 'Jobs to Suspend', J.job, J.script, J.state, T.state
            FROM sw.t_jobs T
                 INNER JOIN Tmp_DMSJobs J
                   ON T.job = J.job
            WHERE
                (T.state <> 8) AND                    -- 8=Holding
                (T.job IN (SELECT job FROM Tmp_DMSJobs WHERE state = 8));

            If Not FOUND Then
                INSERT INTO Tmp_JobDebugMessages (Message, Job);
                VALUES ('No Jobs to Suspend', 0);
            End If;
        Else
        -- <SuspendUpdates>

            ---------------------------------------------------
            -- Find jobs to suspend
            ---------------------------------------------------

            If _loggingEnabled Or extract(epoch FROM (clock_timestamp() - _startTime)) >= _logIntervalThreshold Then
                _loggingEnabled := true;
                _statusMessage := 'Finding jobs to Suspend (Hold)';
                Call public.post_log_entry ('Progress', _statusMessage, 'Add_New_Jobs', 'sw');
            End If;

            -- Set local job state to holding for jobs
            -- that are in holding state in DMS
            --
            UPDATE sw.t_jobs
            SET state = 8                            -- 8=Holding
            WHERE (sw.t_jobs.state <> 8) AND
                  (sw.t_jobs.job IN ( SELECT job
                                   FROM Tmp_DMSJobs
                                   WHERE state = 8 ))
               --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _myRowCount > 0 Then
                _statusMessage := 'Suspended ' || _myRowCount::text || ' job';
                If _myRowCount <> 1 Then
                    _statusMessage := _statusMessage || 's';
                End If;
                Call public.post_log_entry ('Progress', _statusMessage, 'Add_New_Jobs', 'sw');
            End If;
        End If; -- </SuspendUpdates>

        -- Commit the changes for Transaction #1
        COMMIT;
    END;

    If _resumeUpdatesRequired Then
    -- <ResumeUpdates>

        ---------------------------------------------------
        -- Process the jobs that need to be resumed
        ---------------------------------------------------
        --
        _statusMessage := 'Resuming ' || _jobCountToResume::text || ' job';
        If _jobCountToResume <> 1 Then
            _statusMessage := _statusMessage || 's';
        End If;
        Call public.post_log_entry ('Progress', _statusMessage, 'Add_New_Jobs', 'sw');

        If _loggingEnabled Or extract(epoch FROM (clock_timestamp() - _startTime)) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := 'Updating parameters for resumed jobs';
            Call public.post_log_entry ('Progress', _statusMessage, 'Add_New_Jobs', 'sw');
        End If;

        -- Update parameters for jobs being resumed or reset (jobs in Tmp_JobsToResumeOrReset)
        --
        _jobsProcessed := 0;
        _lastLogTime := clock_timestamp();

        FOR _job IN
            SELECT Job
            FROM Tmp_JobsToResumeOrReset
            ORDER BY Job
        LOOP
            Call sw.update_job_parameters (
                    _job,
                    _infoOnly => _infoOnly,
                    _message => _message,           -- Output
                    _returnCode => _returnCode);    -- Output

            If _returnCode <> '' Then
                _message := 'Error updating parameters for job ' || _job::text;
                Call public.post_log_entry ('Error', _message, 'Add_New_Jobs', 'sw');

                DROP TABLE Tmp_JobsToResumeOrReset;
                RETURN;
            End If;

            ---------------------------------------------------
            -- Make sure transfer_folder_path and storage_server are up-to-date in sw.t_jobs
            ---------------------------------------------------
            --
            Call sw.validate_job_server_info (_job, _useJobParameters => true, _debugMode => _debugMode);

            _jobsProcessed := _jobsProcessed + 1;

            If extract(epoch FROM (clock_timestamp() - _lastLogTime)) >= _loopingUpdateInterval Then
                -- Make sure _loggingEnabled is true
                _loggingEnabled := true;

                _statusMessage := format('... Updating parameters for resumed jobs: %s / %s', _jobsProcessed, _jobCountToResume);
                Call public.post_log_entry ('Progress', _statusMessage, 'Add_New_Jobs', 'sw');
                _lastLogTime := clock_timestamp();
            End If;

        END LOOP;

        -- For failed jobs being reset, truncate the comment at the first semi-colon
        --
        UPDATE Tmp_DMSJobs
        SET Comment = RTrim(SubString(Target.Comment, 1, FilterQ.Matchindex - 1))
        FROM ( SELECT DJ.Job,
                      Position(';' In DJ.Comment) AS MatchIndex
               FROM Tmp_DMSJobs DJ
                       INNER JOIN Tmp_JobsToResumeOrReset RJ
                         ON DJ.Job = RJ.Job AND
                            RJ.FailedJob > 0
             ) FilterQ
        WHERE Target.Job = FilterQ.Job AND
              FilterQ.MatchIndex > 0;

        -- Make sure the job comment and special_processing fields are up-to-date in sw.t_jobs
        --
        UPDATE sw.t_jobs J
        SET comment = DJ.comment,
            special_processing = DJ.special_processing
        FROM Tmp_DMSJobs DJ
             INNER JOIN Tmp_JobsToResumeOrReset RJ
               ON DJ.Job = RJ.Job
        WHERE J.Job = DJ.Job AND
              ( Coalesce(J.Comment, '') <> Coalesce(DJ.Comment,'') OR
                Coalesce(J.Special_Processing, '') <> Coalesce(DJ.Special_Processing, '')
              );
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount > 0 Then
            _statusMessage := format('... Updated the job comment or special_processing data in sw.t_jobs for %s resumed %s',
                                        _myRowCount, public.check_plural(_myRowCount, 'row', 'rows')

            Call public.post_log_entry ('Progress', _statusMessage, 'Add_New_Jobs', 'sw');
        End If;

        If _loggingEnabled Or extract(epoch FROM (clock_timestamp() - _startTime)) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := 'Updating sw.t_job_steps, sw.t_job_step_dependencies, and sw.t_jobs for resumed jobs';
            Call public.post_log_entry ('Progress', _statusMessage, 'Add_New_Jobs', 'sw');
        End If;

        -- Start transaction #2
        --
        BEGIN

            ---------------------------------------------------
            -- Set any failed or holding job steps to waiting
            ---------------------------------------------------
            --
            UPDATE sw.t_job_steps
            SET state = 1,                  -- 1=waiting
                tool_version_id = 1,        -- 1=Unknown
                next_try = CURRENT_TIMESTAMP,
                retry_count = 0,
                remote_info_id = 1,         -- 1=Unknown
                remote_timestamp = Null,
                remote_start = Null,
                remote_finish = Null,
                remote_progress = Null
            WHERE
                state IN (6, 7, 10, 16) AND          -- 6=Failed, 7=Holding, 10=Holding_Staging, 16=Failed_Remote
                job IN (SELECT job From Tmp_JobsToResumeOrReset);

            ---------------------------------------------------
            -- Reset the entries in sw.t_job_step_dependencies for any steps with state 1
            ---------------------------------------------------
            --
            UPDATE sw.t_job_step_dependencies JSD
            SET evaluated = 0,
                triggered = 0
            FROM sw.t_job_steps JS
            WHERE JSD.job = JS.job AND
                JSD.step = JS.step AND
                JS.state = 1 AND            -- 1=Waiting
                JS.job IN (SELECT job From Tmp_JobsToResumeOrReset);

            ---------------------------------------------------
            -- Set job state to 'resuming'
            ---------------------------------------------------
            --
            UPDATE sw.t_jobs
            SET state = 20                        -- 20=resuming
            WHERE job IN (SELECT job From Tmp_JobsToResumeOrReset);

            -- Commit the changes for Transaction #2
            COMMIT;
        END;

    End If; -- </ResumeUpdates>

    If _loggingEnabled Or extract(epoch FROM (clock_timestamp() - _startTime)) >= _logIntervalThreshold Then
        _loggingEnabled := true;
        _statusMessage := 'AddNewJobs Complete';
        Call public.post_log_entry ('Progress', _statusMessage, 'Add_New_Jobs', 'sw');
    End If;

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
    If _debugMode Then
        -- ToDo: Update this to use Raise Info
        SELECT *
        FROM Tmp_JobDebugMessages
        ORDER BY EntryID;
    End If;

                DROP TABLE Tmp_DMSJobs;
                DROP TABLE Tmp_ResetJobs;
                DROP TABLE Tmp_JobsToResumeOrReset;
                DROP TABLE Tmp_JobDebugMessages;


    DROP TABLE Tmp_DMSJobs;
    DROP TABLE Tmp_ResetJobs;
    DROP TABLE Tmp_JobsToResumeOrReset;
    DROP TABLE Tmp_JobDebugMessages;

    If _jobCountToReset > 0 And Not _debugMode Then
        DROP TABLE Tmp_SJL;
    End If;
END
$$;

COMMENT ON PROCEDURE sw.add_new_jobs IS 'AddNewJobs';