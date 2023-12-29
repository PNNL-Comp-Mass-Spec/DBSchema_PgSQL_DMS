--
-- Name: update_job_state(boolean, integer, integer, boolean, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.update_job_state(IN _bypassdms boolean DEFAULT false, IN _maxjobstoprocess integer DEFAULT 0, IN _loopingupdateinterval integer DEFAULT 5, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Based on step state, look for jobs that have been completed or have entered the 'in progress' state
**
**      Update job states in sw.t_jobs and in public.t_analysis_job accordingly
**
**      Processing steps:
**
**      1) Evaluate state of steps for jobs that are in new or busy state, or in transient state of being resumed or reset,
**         then determine what the new broker job state should be.
**
**      2) Accumulate list of jobs whose new state is different than their current state
**
**         Current               Current                      New
**         Broker                Job Step                     Broker
**         Job State             States                       Job State
**         (in sw.t_jobs)        (in sw.t_job_steps)          To Assign
**         -----------------     -------------------------    ---------
**         New or Busy           One or more steps failed     Failed
**
**         New or Busy           All steps complete           Complete
**
**         New, Busy, Resuming   One or more steps busy       Busy
**
**         Failed                All steps complete           Complete, though only if max Job Step completion time is greater than Finish time in sw.t_jobs
**
**      3) Go through list of jobs whose current state must be changed and
**         update tables in the sw and public schemas
**
**         New             Action by broker
**         Broker          - Always set job state in sw.t_jobs to new state
**         Job State       - Roll up step completion messages and append to comment in public.t_analysis_job
**         ---------       ---------------------------------------
**         Failed          Update DMS job state to 'Failed'
**
**         Complete        Update DMS job state to 'Complete'
**
**         Busy            Update DMS job state to 'In Progress'
**
**  Arguments:
**    _bypassDMS                If true, update tables in the sw schema but not in the public schema
**    _maxJobsToProcess         Maximum number of jobs to update
**    _loopingUpdateInterval    Seconds between detailed logging while looping through the dependencies
**    _infoOnly                 When true, preview updates
**
**  Auth:   grk
**  Date:   05/06/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          11/05/2008 grk - Fixed issue with broker job state update
**          12/05/2008 mem - Now setting Assigned_Processor_Name to 'Job_Broker' in t_analysis_job
**          12/09/2008 grk - Cleaned out debug code, and uncommented parts of update for DMS job comment and fasta file name
**          12/11/2008 mem - Improved null handling for comments
**          12/15/2008 mem - Now calling Set_Archive_Update_Required when a job successfully completes
**          12/17/2008 grk - Calling S_Set_Archive_Update_Required instead of public.set_archive_update_required
**          12/18/2008 grk - Calling Copy_Job_To_History when a job finishes (both success or fail)
**          12/29/2008 mem - Updated logic for when to copy comment information to DMS
**          01/12/2009 grk - Handle 'No results above threshold' (http://prismtrac.pnl.gov/trac/ticket/706)
**          02/05/2009 mem - Now populating processing_time_minutes in DMS (Ticket #722, http://prismtrac.pnl.gov/trac/ticket/722)
**                         - Updated to use the Start and Finish times of the job steps for the job start and finish times (Ticket #722)
**          02/07/2009 mem - Tweaked logic for updating Start and Finish in T_Jobs
**          02/16/2009 mem - Updated processing time calculation to use the Maximum processing time for each step tool, then take the sum of those values to compute the total job time
**          03/16/2009 mem - Updated to handle jobs with non-zero propagation_mode values in T_Analysis_Job in DMS
**          06/02/2009 mem - Now calling S_DMS_Update_Analysis_Job_Processing_Stats instead of directly updating DMS5.t_Analysis_Job (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**                         - No longer calling S_Set_Archive_Update_Required since Update_Analysis_Job_Processing_Stats does this for us
**                         - Added parameter _maxJobsToProcess
**                         - Renamed synonym for T_Analysis_Job table to S_DMS_T_Analysis_Job
**                         - Altered method of populating _startMin and _finishMax to avoid warning 'Null value is eliminated by an aggregate or other Set operation'
**          06/03/2009 mem - Added parameter _loopingUpdateInterval
**          02/27/2010 mem - Now using V_Job_Processing_Time to determine the job processing times
**          04/13/2010 grk - Automatic bypass of updating DMS for jobs with datasetID = 0
**          10/25/2010 grk - Bypass updating job in DMS if job not in DMS (_jobInDMS)
**          05/11/2011 mem - Now updating job state from Failed to Complete if all job steps are now complete and at least one of the job steps finished later than the Finish time in T_Jobs
**          11/14/2011 mem - Now using >= instead of > when looking for jobs to change from Failed to Complete because all job steps are now complete or skipped
**          12/31/2011 mem - Fixed PostedBy name when calling post_log_entry
**          01/12/2012 mem - Added parameter _infoOnly
**          09/25/2012 mem - Expanded _orgDBName and Organism_DB_Name to varchar(128)
**          02/21/2013 mem - Now updating the state of failed jobs in DMS back to state 2 if they are now in-progress or finished
**          03/13/2014 mem - Now updating _jobInDMS even if _datasetID is 0
**          09/16/2014 mem - Now looking for failed jobs that should be changed to state 2 in T_Jobs
**          05/01/2015 mem - Now setting the state to 7 (No Intermediate Files Created) if all of the job's steps were skipped
**          05/04/2015 mem - Fix bug in logic that conditionally sets the job state to 7
**          12/31/2015 mem - Setting job state in DMS to 14 if the job comment contains 'No results in DeconTools Isos file'
**          09/15/2016 mem - Update jobs in DMS5 that are in state 1=New, but are actually in progress
**          05/13/2017 mem - Treat step state 9 (Running_Remote) as 'In progress'
**          05/26/2017 mem - Add step state 16 (Failed_Remote)
**                         - Only call Copy_Job_To_History if the job state is 4 or 5
**          06/15/2017 mem - Expand _comment to varchar(512)
**          10/16/2017 mem - Remove the leading semicolon from _comment
**          01/19/2018 mem - Populate column Runtime_Minutes in T_Jobs
**                         - Use column ProcTimeMinutes_CompletedSteps in V_Job_Processing_Time
**          05/10/2018 mem - Append to the job comment, rather than replacing it (provided the job completed successfully)
**          06/12/2018 mem - Send _maxLength to append_to_text
**          03/12/2021 mem - Expand _comment to varchar(1024)
**          08/03/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Use default delimiter and max length when calling append_to_text()
**                         - Align assignment statements
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _insertCount int;
    _jobInfo record;
    _jobCountToProcess int;
    _jobsProcessed int;
    _startMin timestamp;
    _finishMax timestamp;
    _processingTimeMinutes real;
    _updateCode int;
    _startTime timestamp;
    _lastLogTime timestamp;
    _statusMessage text;
    _comment text := '';
    _newDMSJobState int;
    _orgDBName text;
    _jobPropagationMode int := 0;
    _jobInDMS boolean := false;
    _jobCommentAddnl text;

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
    _startTime             := CURRENT_TIMESTAMP;
    _loopingUpdateInterval := Coalesce(_loopingUpdateInterval, 5);
    _infoOnly              := Coalesce(_infoOnly, false);

    If _loopingUpdateInterval < 2 Then
        _loopingUpdateInterval := 2;
    End If;

    ---------------------------------------------------
    -- Temp table to hold state changes
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_ChangedJobs (
        Job int,
        NewState int,
        Results_Directory_Name text,
        Organism_DB_Name text,
        Dataset_Name text,
        Dataset_ID int
    );

    CREATE INDEX IX_Tmp_ChangedJobs_Job ON Tmp_ChangedJobs (Job);

    If _infoOnly Then
        CREATE TEMP TABLE Tmp_JobStatePreview (
            Job int,
            Old_State int,
            New_State int
        );

        CREATE INDEX IX_Tmp_JobStatePreview_Job ON Tmp_JobStatePreview (Job);

    End If;

    ---------------------------------------------------
    -- Determine what current state of active jobs should be
    -- and get list of the ones that need be changed
    ---------------------------------------------------

    INSERT INTO Tmp_ChangedJobs( Job,
                                 NewState,
                                 Results_Directory_Name,
                                 Organism_DB_Name,
                                 Dataset_Name,
                                 Dataset_ID )
    SELECT Job,
           NewState,
           Results_Directory_Name,
           Organism_DB_Name,
           Dataset,
           Dataset_ID
    FROM (
        -- Look at the step states for active or failed jobs
        -- and determine what the new state of each job should be
        SELECT J.Job,
               J.State,
               J.Results_Folder_Name As Results_Directory_Name,
               J.Organism_DB_Name,
               CASE
                 WHEN JS_Stats.Failed > 0 THEN 5                                        -- Job Failed
                 WHEN JS_Stats.FinishedOrSkipped = Total THEN
                     CASE WHEN JS_Stats.FinishedOrSkipped = JS_Stats.Skipped THEN 7     -- No Intermediate Files Created (all steps skipped)
                     ELSE 4                                                             -- Job Complete
                     END
                 WHEN JS_Stats.StartedFinishedOrSkipped > 0 THEN 2                      -- Job In Progress
                 ELSE J.State
               END AS NewState,
               J.Dataset,
               J.Dataset_ID
        FROM (
              -- Count the number of steps for each job
              -- that are in the busy, finished, or failed states
              SELECT
                  JS.Job,
                  COUNT(JS.step) AS Total,
                  SUM(CASE
                      WHEN JS.state IN (3,4,5,9) THEN 1
                      ELSE 0
                      END) AS StartedFinishedOrSkipped,
                  SUM(CASE
                      WHEN JS.state IN (6,16) THEN 1
                      ELSE 0
                      END) AS Failed,
                  SUM(CASE
                      WHEN JS.state IN (3,5) THEN 1
                      ELSE 0
                      END) AS FinishedOrSkipped,
                  SUM(CASE
                      WHEN JS.state = 3 Then 1
                      ELSE 0
                      END) AS Skipped
              FROM sw.t_job_steps JS
                   INNER JOIN sw.t_jobs J
                     ON JS.job = J.job
              WHERE J.state IN (1, 2, 5, 20)    -- job state (not step state!): new, in progress, failed, or resuming state
              GROUP BY JS.job, J.state
           ) AS JS_Stats
           INNER JOIN sw.t_jobs AS J
             ON JS_Stats.job = J.job
        ) UpdateQ
    WHERE UpdateQ.state <> UpdateQ.NewState;
    --
    GET DIAGNOSTICS _jobCountToProcess = ROW_COUNT;

    ---------------------------------------------------
    -- Loop through jobs whose state has changed
    -- and update local state and DMS state
    ---------------------------------------------------

    _jobsProcessed := 0;
    _lastLogTime := clock_timestamp();

    FOR _jobInfo IN
        SELECT Job,
               NewState AS NewJobStateInBroker,
               Results_Directory_Name AS ResultsDirectoryName,
               Organism_DB_Name AS OrgDBName,
               Dataset_ID AS DatasetID
        FROM Tmp_ChangedJobs
        ORDER BY Job
    LOOP
        ---------------------------------------------------
        -- Examine the steps for this job to determine actual start/end times
        ---------------------------------------------------

        SELECT MIN(start),
               MAX(finish)
        INTO _startMin, _finishMax
        FROM sw.t_job_steps
        WHERE job = _jobInfo.Job;

        ---------------------------------------------------
        -- Roll up step completion comments
        ---------------------------------------------------

        SELECT string_agg(Completion_Message, '; ' ORDER BY step)
        INTO _comment
        FROM sw.t_job_steps
        WHERE job = _jobInfo.Job AND
              Trim(Coalesce(completion_message, '')) <> '';

        ---------------------------------------------------
        -- Examine the steps for this job to determine total processing time
        --
        -- Steps with the same Step Tool name are assumed to be steps that can run in parallel;
        -- therefore, we use a MAX(ProcessingTime) on steps with the same Step Tool name
        ---------------------------------------------------

        SELECT Proc_Time_Minutes_Completed_Steps
        INTO _processingTimeMinutes
        FROM sw.v_job_processing_time
        WHERE Job = _jobInfo.Job;

        _processingTimeMinutes := Coalesce(_processingTimeMinutes, 0);

        If _infoOnly Then
            INSERT INTO Tmp_JobStatePreview (Job, Old_State, New_State)
            SELECT job, state, _jobInfo.NewJobStateInBroker
            FROM sw.t_jobs
            WHERE job = _jobInfo.Job;
        Else
            ------------------------------------------------------------------
            -- Update local job state, timestamp (if appropriate), and comment
            ------------------------------------------------------------------

            UPDATE sw.t_jobs
            SET state = _jobInfo.NewJobStateInBroker,
                start = CASE WHEN _jobInfo.NewJobStateInBroker >= 2                     -- job state is 2 or higher
                             THEN Coalesce(_startMin, CURRENT_TIMESTAMP)
                             ELSE Start
                        END,
                Finish = CASE WHEN _jobInfo.NewJobStateInBroker IN (4, 5, 7)            -- 4=Complete, 5=Failed, 7=No Intermediate Files Created
                              THEN _finishMax
                              ELSE Finish
                         END,
                Comment = CASE WHEN _jobInfo.NewJobStateInBroker IN (5)                 -- 5=Failed
                               THEN _comment
                               WHEN _jobInfo.NewJobStateInBroker IN (4, 7)              -- 4=Complete, 7=No Intermediate Files Created
                               THEN public.append_to_text(Comment, _comment)
                               ELSE Comment
                          END,
                Runtime_Minutes = _processingTimeMinutes
            WHERE Job = _jobInfo.Job;

        End If;

        ---------------------------------------------------
        -- Figure out what the job state should be in public.t_analysis_job
        ---------------------------------------------------

        If _jobInfo.NewJobStateInBroker In (2, 4, 5, 7) Then
            _newDMSJobState := _jobInfo.NewJobStateInBroker;
        Else
            _newDMSJobState := 99;
        End If;

        ---------------------------------------------------
        -- If this job has a data extraction step with message 'No results above threshold',
        -- change the job state to 14=No Export
        ---------------------------------------------------

        If _newDMSJobState = 4 Then     -- State 4: Complete

            If Exists ( SELECT Step
                        FROM sw.t_job_steps
                        WHERE Job = _jobInfo.Job AND
                              Completion_Message LIKE '%No results above threshold%' AND
                              tool = 'DataExtractor' ) Then
                _newDMSJobState := 14;
            End If;

        End If;

        ---------------------------------------------------
        -- If this job has a DeconTools step with message 'No results in DeconTools Isos file',
        -- change the job state to 14=No Export
        ---------------------------------------------------

        If _newDMSJobState = 4 Then     -- State 4: Complete

            If Exists ( SELECT Step
                        FROM sw.t_job_steps
                        WHERE Job = _jobInfo.Job AND
                              Completion_Message LIKE '%No results in DeconTools Isos file%' AND
                              tool LIKE 'Decon%' ) Then
                _newDMSJobState := 14;
            End If;

        End If;

        ---------------------------------------------------
        -- Decide on the FASTA file name to use for the job
        -- In addition, check whether the job has a Propagation mode of 1
        ---------------------------------------------------

        If _jobInfo.DatasetID <> 0 Then

            SELECT CASE WHEN protein_collection_list = 'na'
                        THEN organism_db_name
                        ELSE _jobInfo.OrgDBName
                   END,
                   propagation_mode
            INTO _orgDBName, _jobPropagationMode
            FROM public.t_analysis_job
            WHERE job = _jobInfo.Job;

            If FOUND Then
                _jobInDMS := true;
            End If;

        Else

            SELECT _jobInfo.OrgDBName, propagation_mode
            INTO _orgDBName, _jobPropagationMode
            FROM public.t_analysis_job
            WHERE job = _jobInfo.Job;

            If FOUND Then
                _jobInDMS := true;
            End If;

        End If;

        ---------------------------------------------------
        -- If the DMS job state is 4=complete, but _jobPropagationMode is non-zero,
        -- change the DMS job state to 14=No Export
        ---------------------------------------------------

        If _newDMSJobState = 4 And Coalesce(_jobPropagationMode, 0) <> 0 Then
            _newDMSJobState := 14;
        End If;

        ---------------------------------------------------
        -- Are we enabled for making changes to public.t_analysis_job?
        ---------------------------------------------------

        If Not _bypassDMS And _jobInDMS And Not _infoOnly Then
            -- Public schema changes enabled, update job state in public.t_analysis_job

            -- Uncomment to debug
            -- _debugMsg := format('Calling update_analysis_job_processing_stats for job %s', _jobInfo.Job);
            -- CALL public.post_log_entry ('Debug', _debugMsg, 'Update_Job_State', 'sw');

            -- Compute the value for _updateCode, which is used as a safety feature to prevent unauthorized job updates
            -- Procedure update_analysis_job_processing_stats will re-compute _updateCode based on _jobInfo.Job,
            -- and if the values don't match, the update is not performed

            If char_length(_comment) <= 1024 Then
                _jobCommentAddnl := _comment;
            Else
                _jobCommentAddnl := Substring(_comment, 1, 1024);
            End If;

            If _jobInfo.Job % 2 = 0 Then
                _updateCode := (_jobInfo.Job % 220) + 14;
            Else
                _updateCode := (_jobInfo.Job % 125) + 11;
            End If;

            CALL public.update_analysis_job_processing_stats (
                    _job                   => _jobInfo.Job,
                    _newDMSJobState        => _newDMSJobState,
                    _newBrokerJobState     => _jobInfo.NewJobStateInBroker,
                    _jobStart              => _startMin,
                    _jobFinish             => _finishMax,
                    _resultsDirectoryName  => _jobInfo.ResultsDirectoryName,
                    _assignedProcessor     => 'Job_Broker',
                    _jobCommentAddnl       => _jobCommentAddnl,
                    _organismDBName        => _orgDBName,
                    _processingTimeMinutes => _processingTimeMinutes,
                    _updateCode            => _updateCode,
                    _infoOnly              => false,
                    _message               => _message,         -- Output
                    _returncode            => _returnCode);     -- Output

            If _returnCode <> '' Then
                CALL public.post_log_entry ('Error', _message, 'Update_Job_State', 'sw');
            End If;

        End If;

        If Not _infoOnly And _jobInfo.NewJobStateInBroker In (4, 5) Then

            ---------------------------------------------------
            -- Save job history
            ---------------------------------------------------

            CALL sw.copy_job_to_history (
                        _jobInfo.Job,
                        _jobInfo.NewJobStateInBroker,
                        _message    => _message,        -- Output
                        _returnCode => _returnCode      -- Output
                        );
        End If;

        _jobsProcessed := _jobsProcessed + 1;

        If extract(epoch FROM (clock_timestamp() - _lastLogTime)) >= _loopingUpdateInterval Then
            _statusMessage := format('... Updating job state: %s / %s', _jobsProcessed, _jobCountToProcess);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Update_Job_State', 'sw');
            _lastLogTime := clock_timestamp();
        End If;

        If _maxJobsToProcess > 0 And _jobsProcessed >= _maxJobsToProcess Then
            -- Break out of the for loop
            EXIT;
        End If;

    END LOOP;

    If _infoOnly Then

        ---------------------------------------------------
        -- Preview changes that would be made via the above for loop
        ---------------------------------------------------

        RAISE INFO '';

        _formatSpecifier := '%-9s %-9s %-9s';

        _infoHead := format(_formatSpecifier,
                            'Job',
                            'Old_State',
                            'New_State'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '---------',
                                     '---------',
                                     '---------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Job,
                   Old_State,
                   New_State
            FROM Tmp_JobStatePreview
            ORDER BY Job
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Job,
                                _previewData.Old_State,
                                _previewData.New_State
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    End If;

    If _bypassDMS Then
        DROP TABLE Tmp_ChangedJobs;

        If _infoOnly Then
            DROP TABLE Tmp_JobStatePreview;
        End If;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Look for jobs in public.t_analysis_job that are failed, yet are not failed in sw.t_jobs
    -- Also look for jobs listed as new that are actually in progress
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_JobsToReset (
        Job int not null,
        NewState int not null
    );

    -- Look for jobs that are listed as Failed in public.t_analysis_job, but are in-progress in sw.t_jobs

    INSERT INTO Tmp_JobsToReset (job, NewState )
    SELECT DMSJobs.job AS Job,
           J.state AS NewState
    FROM public.t_analysis_job AS DMSJobs
         INNER JOIN sw.t_jobs AS J
           ON J.job = DMSJobs.job
    WHERE DMSJobs.job_state_id = 5 AND
          J.state IN (1, 2, 4);

    -- Also look for jobs that are in state New in public.t_analysis_job, but are in-progress in sw.t_jobs

    INSERT INTO Tmp_JobsToReset (job, NewState )
    SELECT DMSJobs.job AS Job,
           J.state AS NewState
    FROM public.t_analysis_job AS DMSJobs
         INNER JOIN sw.t_jobs AS J
           ON J.job = DMSJobs.job
    WHERE DMSJobs.job_state_id = 1 AND
          J.state IN (2);

    If Not Exists (SELECT job FROM Tmp_JobsToReset) Then
        DROP TABLE Tmp_ChangedJobs;
        DROP TABLE Tmp_JobsToReset;

        If _infoOnly Then
            DROP TABLE Tmp_JobStatePreview;
        End If;

        RETURN;
    End If;

    -- Add an index to Tmp_JobsToReset, which will be beneficial if Tmp_JobsToReset has a large number of jobs
    CREATE INDEX IX_Tmp_JobsToReset ON Tmp_JobsToReset (Job);

    FOR _jobInfo IN
        SELECT Job, MAX(NewState) AS NewJobStateInBroker
        FROM Tmp_JobsToReset
        GROUP BY Job
        ORDER BY Job
    LOOP
        -- Compute the value for _updateCode, which is used as a safety feature to prevent unauthorized job updates

        If _jobInfo.Job % 2 = 0 Then
            _updateCode := (_jobInfo.Job % 220) + 14;
        Else
            _updateCode := (_jobInfo.Job % 125) + 11;
        End If;

        -- Update the job start time based on the job steps
        -- Note that if no steps have started yet, _startMin will be Null

        SELECT MIN(start)
        INTO _startMin
        FROM sw.t_job_steps
        WHERE job = _jobInfo.Job;

        CALL public.update_failed_job_now_in_progress (
                        _job               => _jobInfo.Job,
                        _newBrokerJobState => _jobInfo.NewJobStateInBroker,
                        _jobStart          => _startMin,
                        _updateCode        => _updateCode,
                        _infoOnly          => _infoOnly,
                        _message           => _message,         -- Output
                        _returncode        => _returnCode);     -- Output

        If _returnCode <> '' Then
            CALL public.post_log_entry ('Error', _message, 'Update_Job_State', 'sw');
        End If;

    END LOOP;

    DROP TABLE Tmp_ChangedJobs;
    DROP TABLE Tmp_JobsToReset;

    If _infoOnly Then
        DROP TABLE Tmp_JobStatePreview;
    End If;
END
$$;


ALTER PROCEDURE sw.update_job_state(IN _bypassdms boolean, IN _maxjobstoprocess integer, IN _loopingupdateinterval integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_job_state(IN _bypassdms boolean, IN _maxjobstoprocess integer, IN _loopingupdateinterval integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.update_job_state(IN _bypassdms boolean, IN _maxjobstoprocess integer, IN _loopingupdateinterval integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateJobState';

