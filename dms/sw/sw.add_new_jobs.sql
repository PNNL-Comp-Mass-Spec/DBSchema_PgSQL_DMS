--
-- Name: add_new_jobs(boolean, text, text, integer, integer, boolean, integer, boolean, integer, boolean); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.add_new_jobs(IN _bypassdms boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _maxjobstoprocess integer DEFAULT 0, IN _logintervalthreshold integer DEFAULT 15, IN _loggingenabled boolean DEFAULT false, IN _loopingupdateinterval integer DEFAULT 5, IN _infoonly boolean DEFAULT false, IN _infolevel integer DEFAULT 0, IN _debugmode boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add jobs from DMS that are in 'New' state in public.t_analysis_job, but aren't already in sw.t_jobs
**      The DMS analysis tool tool determines the pipeline script to use
**
**      Suspend running jobs that now have state 'Holding' in public.t_analysis_job
**
**      Finally, reset failed or holding jobs that are now state 'New' in public.t_analysis_job
**
**  DMS       Broker           Action by broker
**  Job       Job
**  State     State
**  -----     ------           ---------------------------------------
**  New       (job not         Import job:
**             in broker)      - Add it to local job table
**                             - Set local job state to freshly imported
**                               (Create_Job_Steps will set local state to New)
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
**    _bypassDMS                If true, the logic in this procedure is completely bypassed (and thus new jobs are not imported from public.t_analysis_job)
**    _message                  Output: status message
**    _returnCode               Output: return code
**    _maxJobsToProcess         Maximum number of jobs to process
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
**          01/17/2009 mem - Moved updating of T_Jobs.Archive_Busy to Sync_Job_Info (Ticket #716, http://prismtrac.pnl.gov/trac/ticket/716)
**          02/12/2009 mem - Updated job resume logic to change step states from 6 or 7 to 1=waiting (instead of 2=enabled) and to reset Evaluated and Triggered to 0 in T_Job_Step_Dependencies for the affected steps
**                         - Added parameter _debugMode
**          03/02/2009 grk - Added code to update job parameters when jobs are resumed (from hold or fail)
**          03/11/2009 mem - Now also resetting jobs if they are running or failed, but do not have any running or completed job steps (Ticket #725, http://prismtrac.pnl.gov/trac/ticket/725)
**          06/01/2009 mem - Moved the job resuming updates to occur outside the transaction (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**                         - Added parameter _maxJobsToProcess
**          06/03/2009 mem - Now updating Transfer_Folder_Path when resuming a job
**          06/04/2009 mem - Added parameters _logIntervalThreshold, _loggingEnabled, and _loopingUpdateInterval
**          07/29/2009 mem - Now populating Comment in T_Jobs
**          03/03/2010 mem - Now populating Storage_Server in T_Jobs
**          03/21/2011 mem - Added parameter _infoOnly and moved position of parameter _debugMode
**                         - Now calling Update_Input_Folder_Using_Source_Job_Comment if needed when resuming jobs
**          04/04/2011 mem - Now populating Special_Processing in T_Jobs
**                         - Removed call to Update_Input_Folder_Using_Source_Job_Comment
**                         - Now using function Get_Job_Param_Table_Local() to lookup a value in T_Job_Parameters
**          07/05/2011 mem - Now updating Tool_Version_ID when resetting job steps
**          07/12/2011 mem - Now calling Validate_Job_Server_Info
**          01/09/2012 mem - Now populating Owner in T_Jobs
**          01/12/2012 mem - Now only auto-adding jobs for scripts with Backfill_to_DMS = 0
**          01/19/2012 mem - Now populating Data_Pkg_ID in T_Jobs
**          04/28/2014 mem - Bumped up _maxJobsToAddResetOrResume from 1 million to 1 billion
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          11/07/2014 mem - No longer performing a full job reset for ICR2LS or LTQ_FTPek jobs where the job state is failed but the DMS state is new
**          01/04/2016 mem - Truncate the job comment at the first semicolon for failed jobs being reset
**          05/12/2017 mem - Update Next_Try and Remote_Info_ID
**`         03/30/2018 mem - Add support for job step states 9=Running_Remote, 10=Holding_Staging, and 16=Failed_Remote
**          07/25/2023 mem - Ported to PostgreSQL
**          07/26/2023 mem - Move "Not" keyword to before the field name
**          09/07/2023 mem - Align assignment statements
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _matchCount int;
    _updateCount int;
    _job int;
    _jobsProcessed int;
    _jobCountToResume int;
    _jobCountToReset int;
    _resumeUpdatesRequired boolean;
    _maxJobsToAddResetOrResume int;
    _startTime timestamp;
    _lastLogTime timestamp;
    _statusMessage text;
    _createdSelectedJobsTable boolean := false;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    _resumeUpdatesRequired := false;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly         := Coalesce(_infoOnly, false);
    _infoLevel        := Coalesce(_infoLevel, 0);
    _bypassDMS        := Coalesce(_bypassDMS, false);
    _debugMode        := Coalesce(_debugMode, false);
    _maxJobsToProcess := Coalesce(_maxJobsToProcess, 0);

    If _bypassDMS Then
        RETURN;
    End If;

    If _maxJobsToProcess <= 0 Then
        _maxJobsToAddResetOrResume := 1000000000;
    Else
        _maxJobsToAddResetOrResume := _maxJobsToProcess;
    End If;

    _startTime             := CURRENT_TIMESTAMP;
    _loggingEnabled        := Coalesce(_loggingEnabled, false);
    _logIntervalThreshold  := Coalesce(_logIntervalThreshold, 15);
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
    -- Get list of new or held jobs from public.t_analysis_job
    --
    -- Data comes from view V_Get_Pipeline_Jobs,
    -- which shows new jobs in state 1 or 8 but it
    -- excludes jobs that have recently been archived
    ---------------------------------------------------

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

    If Not FOUND Then
        -- No new or held jobs were found in public.t_analysis_job

        If _debugMode Then
            RAISE INFO 'No new or held jobs found in public.t_analysis_job';
        End If;

        -- Exit this procedure
        DROP TABLE Tmp_DMSJobs;
        RETURN;
    End If;

    -- Create additional temp tables

    CREATE TEMP TABLE Tmp_ResetJobs (
        Job int
    );

    CREATE INDEX IX_Tmp_ResetJobs_Job ON Tmp_ResetJobs (Job);

    CREATE TEMP TABLE Tmp_JobsToResumeOrReset (
        Job int,
        Dataset text,
        FailedJob int
    );

    CREATE INDEX IX_Tmp_ResumedJobs_Job ON Tmp_JobsToResumeOrReset (Job);

    CREATE TEMP TABLE Tmp_JobDebugMessages (
        Message text,
        Job int,
        Script text,
        DMS_State int,
        Pipeline_State int,
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY
    );

    CREATE INDEX IX_Tmp_JobDebugMessages_Job ON Tmp_JobDebugMessages (Job);

    -- New or held jobs are available
    If _debugMode Then
        INSERT INTO Tmp_JobDebugMessages (Message, Job, Script, DMS_State, Pipeline_State)
        SELECT 'New or Held Jobs', J.job, J.script, J.state, T.state
        FROM Tmp_DMSJobs J
             LEFT OUTER JOIN sw.t_jobs T
               ON J.job = T.job
        ORDER BY job;
    End If;

    ---------------------------------------------------
    -- Find jobs to reset
    ---------------------------------------------------

    If _loggingEnabled Or extract(epoch FROM (clock_timestamp() - _startTime)) >= _logIntervalThreshold Then
        _loggingEnabled := true;
        _statusMessage := 'Finding jobs to reset';
        CALL public.post_log_entry ('Progress', _statusMessage, 'Add_New_Jobs', 'sw');
    End If;

    ---------------------------------------------------
    -- Reset job:
    -- delete existing job info from database
    ---------------------------------------------------

    -- Find jobs that are complete in the broker, but in state 1=New in public.t_analysis_job

    INSERT INTO Tmp_ResetJobs (job)
    SELECT T.job
    FROM Tmp_DMSJobs T
         INNER JOIN sw.t_jobs
           ON T.job = sw.t_jobs.job
    WHERE sw.t_jobs.state = 4 AND            -- Complete in the broker
          T.state = 1;                       -- New in public.t_analysis_job
    --
    GET DIAGNOSTICS _jobCountToReset = ROW_COUNT;

    If _jobCountToReset > 0 Then
        _statusMessage := format('Resetting %s completed %s',
                                 _jobCountToReset, public.check_plural(_jobCountToReset, 'job', 'jobs'));

        CALL public.post_log_entry ('Progress', _statusMessage, 'Add_New_Jobs', 'sw');
    End If;

    -- Also look for jobs where the DMS state is 'New', the broker state is 2, 5, or 8 (In Progress, Failed, or Holding),
    -- and none of the jobs Steps have completed or are running

    -- It is typically safer to perform a full reset on these jobs (rather than a resume) in case an admin changed the settings file for the job
    -- Exception: LTQ_FTPek and ICR2LS jobs because ICR-2LS runs as the first step and we create checkpoint copies of the .PEK files to allow for a resume

    INSERT INTO Tmp_ResetJobs (job)
    SELECT T.job
    FROM Tmp_DMSJobs T
         INNER JOIN sw.t_jobs
           ON T.job = sw.t_jobs.job
         LEFT OUTER JOIN ( SELECT J.job
                           FROM sw.t_jobs J
                                INNER JOIN sw.t_job_steps JS
                                  ON J.job = JS.job
                           WHERE J.state IN (2, 5, 8) AND   -- Jobs that are running, failed, or holding
                                 JS.state IN (4, 5, 9)      -- Steps that are running or finished (but not failed or holding)
                          ) LookupQ
     ON sw.t_jobs.job = LookupQ.job
    WHERE sw.t_jobs.state IN (2, 5, 8) AND
          NOT T.script IN ('LTQ_FTPek','ICR2LS') AND
          LookupQ.job IS NULL;                       -- Assure there are no running or finished steps
    --
    GET DIAGNOSTICS _matchCount = ROW_COUNT;

    If _matchCount > 0 Then
        _jobCountToReset := _jobCountToReset + _matchCount;

        _statusMessage := format('Resetting %s %s that %s In Progress, Failed, or Holding and % no completed or running job steps',
                                 _matchCount,
                                 public.check_plural(_matchCount, 'job', 'jobs'),
                                 public.check_plural(_matchCount, 'is',  'are'),
                                 public.check_plural(_matchCount, 'has', 'have'));

        CALL public.post_log_entry ('Progress', _statusMessage, 'Add_New_Jobs', 'sw');
    End If;

    If _jobCountToReset = 0 Then
        If _debugMode Then
            INSERT INTO Tmp_JobDebugMessages (Message, Job)
            VALUES ('No Jobs to Reset', 0);
        End If;
    Else
        -- Reset jobs

        If _maxJobsToProcess > 0 Then
            -- Limit the number of jobs to reset
            DELETE FROM Tmp_ResetJobs
            WHERE NOT Job IN ( SELECT Job
                               FROM Tmp_ResetJobs
                               ORDER BY Job
                               LIMIT _maxJobsToProcess );
        End If;

        If _debugMode Then
            INSERT INTO Tmp_JobDebugMessages (Message, job, script, DMS_State, Pipeline_State)
            SELECT 'Jobs to Reset', J.job, J.script, J.state, T.state
            FROM Tmp_ResetJobs R INNER JOIN Tmp_DMSJobs J ON R.job = J.job
                 INNER JOIN sw.t_jobs T ON J.job = T.job
            ORDER BY job;
        Else

            ---------------------------------------------------
            -- Set up and populate temp table and call procedure
            -- to delete jobs listed in it
            ---------------------------------------------------

            CREATE TEMP TABLE Tmp_Selected_Jobs (Job int);

            CREATE INDEX IX_Tmp_Selected_Jobs_Job ON Tmp_Selected_Jobs (Job);

            _createdSelectedJobsTable := true;

            INSERT INTO Tmp_Selected_Jobs (Job)
            SELECT Job FROM Tmp_ResetJobs;

            CALL sw.remove_selected_jobs (
                        _infoOnly,
                        _message => _message,           -- Output
                        _returnCode => _returnCode,     -- Output
                        _logDeletions => false,
                        _logToConsoleOnly => false);

        End If;

    End If;

    If Not _infoOnly Or _infoOnly And _infoLevel = 2 Then

        ---------------------------------------------------
        -- Import new jobs
        ---------------------------------------------------

        If _loggingEnabled Or extract(epoch FROM (clock_timestamp() - _startTime)) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := 'Adding new jobs to sw.t_jobs';
            CALL public.post_log_entry ('Progress', _statusMessage, 'Add_New_Jobs', 'sw');
        End If;

        ---------------------------------------------------
        -- Import job:
        -- Copy new jobs from DMS that are not already in table
        -- (only take jobs that have script that is currently active)
        ---------------------------------------------------

        INSERT INTO sw.t_jobs ( job, priority, script, State, Dataset, Dataset_ID, Transfer_Folder_Path,
                                comment, special_processing, storage_server, owner_username, Data_Pkg_ID )
        SELECT DJ.job, DJ.priority, DJ.script, 0 As State, DJ.Dataset, DJ.Dataset_ID, DJ.Transfer_Folder_Path,
               DJ.comment, DJ.special_processing, sw.extract_server_name(DJ.transfer_folder_path) AS Storage_Server, DJ.Owner_Username, 0 AS Data_Pkg_ID
        FROM Tmp_DMSJobs DJ
             INNER JOIN sw.t_scripts S
               ON DJ.script = S.script
        WHERE state = 1 AND
              NOT job IN ( SELECT job
                           FROM sw.t_jobs ) AND
              S.enabled = 'Y' AND
              S.backfill_to_dms = 0
        LIMIT _maxJobsToAddResetOrResume;

    End If;

    ---------------------------------------------------
    -- Find jobs to Resume or Reset
    --
    -- Jobs that are reset in public.t_analysis_job will be in 'new' state,
    -- but there will be an entry for the job in sw.t_jobs that is in the 'failed' or 'holding' state
    --
    -- For all such jobs, set all steps that are in 'failed' state to the 'waiting' state
    -- and set the job state to 'resuming'
    ---------------------------------------------------

    If _loggingEnabled Or extract(epoch FROM (clock_timestamp() - _startTime)) >= _logIntervalThreshold Then
        _loggingEnabled := true;
        _statusMessage := 'Finding jobs to Resume';
        CALL public.post_log_entry ('Progress', _statusMessage, 'Add_New_Jobs', 'sw');
    End If;

    INSERT INTO Tmp_JobsToResumeOrReset (job, dataset, FailedJob)
    SELECT J.job,
           J.dataset,
           CASE WHEN J.state = 5 THEN 1 ELSE 0 END AS FailedJob
    FROM sw.t_jobs J
    WHERE J.state IN (5, 8) AND                    -- 5=Failed, 8=Holding
          J.job IN (SELECT job FROM Tmp_DMSJobs WHERE state = 1)
    LIMIT _maxJobsToAddResetOrResume;
    --
    GET DIAGNOSTICS _jobCountToResume = ROW_COUNT;

    If _jobCountToResume = 0 Then
        If _debugMode Then
            INSERT INTO Tmp_JobDebugMessages (Message, Job)
            VALUES ('No Jobs to Resume', 0);
        End If;
    Else
        -- Resume or reset jobs

        If _debugMode Then
            INSERT INTO Tmp_JobDebugMessages (Message, job, script, DMS_State, Pipeline_State)
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
    End If;

    If _debugMode Then
        INSERT INTO Tmp_JobDebugMessages (Message, job, script, DMS_State, Pipeline_State)
        SELECT 'Jobs to Suspend', J.job, J.script, J.state, T.state
        FROM sw.t_jobs T
             INNER JOIN Tmp_DMSJobs J
               ON T.job = J.job
        WHERE
            (T.state <> 8) AND                    -- 8=Holding
            (T.job IN (SELECT job FROM Tmp_DMSJobs WHERE state = 8));

        If Not FOUND Then
            INSERT INTO Tmp_JobDebugMessages (Message, Job)
            VALUES ('No Jobs to Suspend', 0);
        End If;
    Else

        ---------------------------------------------------
        -- Find jobs to suspend
        ---------------------------------------------------

        If _loggingEnabled Or extract(epoch FROM (clock_timestamp() - _startTime)) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := 'Finding jobs to Suspend (Hold)';
            CALL public.post_log_entry ('Progress', _statusMessage, 'Add_New_Jobs', 'sw');
        End If;

        -- Set local job state to holding for jobs
        -- that are in holding state in public.t_analysis_job
        --
        UPDATE sw.t_jobs
        SET state = 8                            -- 8=Holding
        WHERE sw.t_jobs.state <> 8 AND
              sw.t_jobs.job IN ( SELECT job
                                 FROM Tmp_DMSJobs
                                 WHERE state = 8 );
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        If _updateCount > 0 Then
            _statusMessage := format('Suspended %s %s', _updateCount, public.check_plural(_updateCount, 'job', 'jobs'));
            CALL public.post_log_entry ('Progress', _statusMessage, 'Add_New_Jobs', 'sw');
        End If;
    End If;

    If _resumeUpdatesRequired Then

        ---------------------------------------------------
        -- Process the jobs that need to be resumed
        ---------------------------------------------------

        _statusMessage := format('Resuming %s %s', _jobCountToResume, public.check_plural(_jobCountToResume, 'job', 'jobs'));

        CALL public.post_log_entry ('Progress', _statusMessage, 'Add_New_Jobs', 'sw');

        If _loggingEnabled Or extract(epoch FROM (clock_timestamp() - _startTime)) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := 'Updating parameters for resumed jobs';
            CALL public.post_log_entry ('Progress', _statusMessage, 'Add_New_Jobs', 'sw');
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
            CALL sw.update_job_parameters (
                    _job,
                    _infoOnly => _infoOnly,
                    _settingsFileOverride => '',
                    _message => _message,           -- Output
                    _returnCode => _returnCode);    -- Output

            If _returnCode <> '' Then
                _message := format('Error updating parameters for job %s', _job);
                CALL public.post_log_entry ('Error', _message, 'Add_New_Jobs', 'sw');

                DROP TABLE Tmp_DMSJobs;
                DROP TABLE Tmp_ResetJobs;
                DROP TABLE Tmp_JobsToResumeOrReset;
                DROP TABLE Tmp_JobDebugMessages;

                If _createdSelectedJobsTable Then
                    DROP TABLE Tmp_Selected_Jobs;
                End If;

                RETURN;
            End If;

            ---------------------------------------------------
            -- Make sure transfer_folder_path and storage_server are up-to-date in sw.t_jobs
            ---------------------------------------------------

            CALL sw.validate_job_server_info (
                        _job,
                        _useJobParameters => true,
                        _message => _message,
                        _returnCode => _returnCode,
                        _debugMode => _debugMode);

            _jobsProcessed := _jobsProcessed + 1;

            If extract(epoch FROM (clock_timestamp() - _lastLogTime)) >= _loopingUpdateInterval Then
                -- Make sure _loggingEnabled is true
                _loggingEnabled := true;

                _statusMessage := format('... Updating parameters for resumed jobs: %s / %s', _jobsProcessed, _jobCountToResume);
                CALL public.post_log_entry ('Progress', _statusMessage, 'Add_New_Jobs', 'sw');

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
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        If _updateCount > 0 Then
            _statusMessage := format('... Updated the job comment or special_processing data in sw.t_jobs for %s resumed %s',
                                        _updateCount, public.check_plural(_updateCount, 'row', 'rows'));

            CALL public.post_log_entry ('Progress', _statusMessage, 'Add_New_Jobs', 'sw');
        End If;

        If _loggingEnabled Or extract(epoch FROM (clock_timestamp() - _startTime)) >= _logIntervalThreshold Then
            _loggingEnabled := true;
            _statusMessage := 'Updating sw.t_job_steps, sw.t_job_step_dependencies, and sw.t_jobs for resumed jobs';
            CALL public.post_log_entry ('Progress', _statusMessage, 'Add_New_Jobs', 'sw');
        End If;

        ---------------------------------------------------
        -- Set any failed or holding job steps to waiting
        ---------------------------------------------------

        UPDATE sw.t_job_steps
        SET state = 1,                  -- 1=Waiting
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

        UPDATE sw.t_jobs
        SET state = 20                  -- 20=Resuming
        WHERE job IN (SELECT job From Tmp_JobsToResumeOrReset);

    End If;

    If _loggingEnabled Or extract(epoch FROM (clock_timestamp() - _startTime)) >= _logIntervalThreshold Then
        _loggingEnabled := true;
        _statusMessage := 'AddNewJobs Complete';
        CALL public.post_log_entry ('Progress', _statusMessage, 'Add_New_Jobs', 'sw');
    End If;

    If _debugMode Then

        RAISE INFO '';

        _formatSpecifier := '%-20s %-9s %-35s %-9s %-14s %-8s';

        _infoHead := format(_formatSpecifier,
                            'Message',
                            'Job',
                            'Script',
                            'DMS_State',
                            'Pipeline_State',
                            'Entry_ID'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '--------------------',
                                     '---------',
                                     '-----------------------------------',
                                     '---------',
                                     '--------------',
                                     '--------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Message,
                   Job,
                   Script,
                   DMS_State,
                   Pipeline_State,
                   Entry_ID
            FROM Tmp_JobDebugMessages
            ORDER BY Entry_ID
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Message,
                                _previewData.Job,
                                _previewData.Script,
                                _previewData.DMS_State,
                                _previewData.Pipeline_State,
                                _previewData.Entry_ID
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    End If;

    DROP TABLE Tmp_DMSJobs;
    DROP TABLE Tmp_ResetJobs;
    DROP TABLE Tmp_JobsToResumeOrReset;
    DROP TABLE Tmp_JobDebugMessages;

    If _createdSelectedJobsTable Then
        DROP TABLE Tmp_Selected_Jobs;
    End If;
END
$$;


ALTER PROCEDURE sw.add_new_jobs(IN _bypassdms boolean, INOUT _message text, INOUT _returncode text, IN _maxjobstoprocess integer, IN _logintervalthreshold integer, IN _loggingenabled boolean, IN _loopingupdateinterval integer, IN _infoonly boolean, IN _infolevel integer, IN _debugmode boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE add_new_jobs(IN _bypassdms boolean, INOUT _message text, INOUT _returncode text, IN _maxjobstoprocess integer, IN _logintervalthreshold integer, IN _loggingenabled boolean, IN _loopingupdateinterval integer, IN _infoonly boolean, IN _infolevel integer, IN _debugmode boolean); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.add_new_jobs(IN _bypassdms boolean, INOUT _message text, INOUT _returncode text, IN _maxjobstoprocess integer, IN _logintervalthreshold integer, IN _loggingenabled boolean, IN _loopingupdateinterval integer, IN _infoonly boolean, IN _infolevel integer, IN _debugmode boolean) IS 'AddNewJobs';

