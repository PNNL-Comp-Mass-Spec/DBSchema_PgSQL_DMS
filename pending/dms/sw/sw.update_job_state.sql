--
CREATE OR REPLACE PROCEDURE sw.update_job_state
(
    _bypassDMS boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _maxJobsToProcess int = 0,
    _loopingUpdateInterval int = 5,
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Based on step state, look for jobs that have been completed or have entered the 'in progress' state.
**      Update state of job locally and in DMS accordingly.
**
**      Processing steps:
**
**      1) Evaluate state of steps for jobs that are in new or busy state, or in transient state of being resumed or reset,
**         then determine what the new broker job state should be.
**
**      2) Accumulate list of jobs whose new state is different than their current state
**
**         Current             Current                     New
**         Broker              Job                         Broker
**         Job                 Step                        Job
**         State               States                      State
**         -----               -------                     ---------
**         New or Busy         One or more steps failed    Failed
**
**         New or Busy         All steps complete          Complete
**
**         New,Busy,Resuming   One or more steps busy      Busy
**
**         Failed              All steps complete          Complete, though only if max Job Step completion time is greater than Finish time in T_Jobs
**
**      3) Go through list of jobs whose current state must be changed and
**         update tables in the sw and public schemas
**
**         New             Action by broker
**         Broker          - Always set job state in broker to new state
**         Job             - Roll up step completion messages and append to comment in DMS job
**         State
**         ------          ---------------------------------------
**         Failed          Current: Update DMS job state to 'Failed'
**
**                                In the future, might implement updating
**                                DMS job state to one of several failure states
**                                according to job step completion codes (See note 1)
**                                - Failed
**                                - No Intermediate Files Created
**                                - Data Extraction Failed
**
**         Complete        Update DMS job state to 'Complete'
**
**         Busy            Update DMS job state to 'In Progress'
**
**  Arguments:
**    _bypassDMS                If true, update tables in the sw schema but not in the public schema
**    _message                  Output: status message
**    _maxJobsToProcess         Maximum number of jobs to update
**    _loopingUpdateInterval    Seconds between detailed logging while looping through the dependencies
**    _infoOnly                 If true, preview updates
**
**  Auth:   grk
**  Date:   05/06/2008 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          11/05/2008 grk - fixed issue with broker job state update
**          12/05/2008 mem - Now setting Assigned_Processor_Name to 'Job_Broker' in t_analysis_job
**          12/09/2008 grk - Cleaned out debug code, and uncommented parts of update for DMS job comment and fasta file name
**          12/11/2008 mem - Improved null handling for comments
**          12/15/2008 mem - Now calling SetArchiveUpdateRequired when a job successfully completes
**          12/17/2008 grk - Calling S_SetArchiveUpdateRequired instead of public.set_archive_update_required
**          12/18/2008 grk - Calling CopyJobToHistory when a job finishes (both success or fail)
**          12/29/2008 mem - Updated logic for when to copy comment information to DMS
**          01/12/2009 grk - Handle 'No results above threshold' (http://prismtrac.pnl.gov/trac/ticket/706)
**          02/05/2009 mem - Now populating processing_time_minutes in DMS (Ticket #722, http://prismtrac.pnl.gov/trac/ticket/722)
**                         - Updated to use the Start and Finish times of the job steps for the job start and finish times (Ticket #722)
**          02/07/2009 mem - Tweaked logic for updating Start and Finish in T_Jobs
**          02/16/2009 mem - Updated processing time calculation to use the Maximum processing time for each step tool, then take the sum of those values to compute the total job time
**          03/16/2009 mem - Updated to handle jobs with non-zero propagation_mode values in T_Analysis_Job in DMS
**          06/02/2009 mem - Now calling S_DMS_UpdateAnalysisJobProcessingStats instead of directly updating DMS5.t_Analysis_Job (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**                         - No longer calling S_SetArchiveUpdateRequired since UpdateAnalysisJobProcessingStats does this for us
**                         - Added parameter _maxJobsToProcess
**                         - Renamed synonym for T_Analysis_Job table to S_DMS_T_Analysis_Job
**                         - Altered method of populating _startMin and _finishMax to avoid warning 'Null value is eliminated by an aggregate or other Set operation'
**          06/03/2009 mem - Added parameter _loopingUpdateInterval
**          02/27/2010 mem - Now using V_Job_Processing_Time to determine the job processing times
**          04/13/2010 grk - Automatic bypass of updating DMS for jobs with datasetID = 0
**          10/25/2010 grk - Bypass updating job in DMS if job not in DMS (_jobInDMS)
**          05/11/2011 mem - Now updating job state from Failed to Complete if all job steps are now complete and at least one of the job steps finished later than the Finish time in T_Jobs
**          11/14/2011 mem - Now using >= instead of > when looking for jobs to change from Failed to Complete because all job steps are now complete or skipped
**          12/31/2011 mem - Fixed PostedBy name when calling PostLogEntry
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
**                         - Only call CopyJobToHistory if the job state is 4 or 5
**          06/15/2017 mem - Expand _comment to varchar(512)
**          10/16/2017 mem - Remove the leading semicolon from _comment
**          01/19/2018 mem - Populate column Runtime_Minutes in T_Jobs
**                         - Use column ProcTimeMinutes_CompletedSteps in V_Job_Processing_Time
**          05/10/2018 mem - Append to the job comment, rather than replacing it (provided the job completed successfully)
**          06/12/2018 mem - Send _maxLength to AppendToText
**          03/12/2021 mem - Expand _comment to varchar(1024)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _previousJob int;
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
BEGIN

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _bypassDMS := Coalesce(_bypassDMS, false);
    _message := '';
    _returnCode:= '';
    _maxJobsToProcess := Coalesce(_maxJobsToProcess, 0);

    _startTime := CURRENT_TIMESTAMP;
    _loopingUpdateInterval := Coalesce(_loopingUpdateInterval, 5);
    If _loopingUpdateInterval < 2 Then
        _loopingUpdateInterval := 2;
    End If;

    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- FUTURE: may need to look at jobs in the holding
    -- state that have been reset
    ---------------------------------------------------

    ---------------------------------------------------
    -- Temp table to hold state changes
    ---------------------------------------------------
    --
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
            OldState int,
            NewState int
        );

        CREATE INDEX IX_Tmp_JobStatePreview_Job ON Tmp_JobStatePreview (Job);

    End If;

    ---------------------------------------------------
    -- Determine what current state of active jobs should be
    -- and get list of the ones that need be changed
    ---------------------------------------------------
    --
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
        -- Look at the state of steps for active or failed jobs
        -- and determine what the new state of each job should be
        SELECT
          J.Job,
          J.State,
          J.Results_Folder_Name As Results_Directory_Name,
          J.Organism_DB_Name,
          CASE
            WHEN JS_Stats.Failed > 0 THEN 5                                        -- Job Failed
            WHEN JS_Stats.FinishedOrSkipped = Total THEN
                CASE WHEN JS_Stats.FinishedOrSkipped = JS_Stats.Skipped THEN 7     -- No Intermediate Files Created (all steps skipped)
                Else 4                                                             -- Job Complete
                End
            WHEN JS_Stats.StartedFinishedOrSkipped > 0 THEN 2                      -- Job In Progress
            Else J.State
          End AS NewState,
          J.Dataset,
          J.Dataset_ID
        FROM
          (
            -- Count the number of steps for each job
            -- that are in the busy, finished, or failed states
            SELECT
                JS.Job,
                COUNT(*) AS Total,
                SUM(CASE
                    WHEN JS.State IN (3,4,5,9) THEN 1
                    ELSE 0
                    END) AS StartedFinishedOrSkipped,
                SUM(CASE
                    WHEN JS.State IN (6,16) THEN 1
                    ELSE 0
                    END) AS Failed,
                SUM(CASE
                    WHEN JS.State IN (3,5) THEN 1
                    ELSE 0
                    END) AS FinishedOrSkipped,
                SUM(CASE
                    WHEN JS.State = 3 Then 1
                    ELSE 0
                    END) AS Skipped
            FROM sw.t_job_steps JS
                 INNER JOIN sw.t_jobs J
                   ON JS.job = J.job
            WHERE (J.state IN (1,2,5,20))    -- job state (not step state!): new, in progress, failed, or resuming state
            GROUP BY JS.job, J.state
           ) AS JS_Stats
           INNER JOIN sw.t_jobs AS J
             ON JS_Stats.job = J.job
        ) UpdateQ
    WHERE UpdateQ.state <> UpdateQ.NewState
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;
    --
    _jobCountToProcess := _myRowCount;

    ---------------------------------------------------
    -- Loop through jobs whose state has changed
    -- and update local state and DMS state
    ---------------------------------------------------

    _jobsProcessed := 0;
    _lastLogTime := clock_timestamp();
    _previousJob := -1;

    WHILE true
    LOOP
        SELECT
            Job,
            NewState As NewJobStateInBroker,
            Results_Directory_Name As ResultsDirectoryName,
            Organism_DB_Name As OrgDBName
            Dataset_ID As DatasetID
        INTO _jobInfo
        FROM Tmp_ChangedJobs
        WHERE
            Job > _previousJob
        ORDER BY Job
        LIMIT 1;

        If Not FOUND Then
            -- Break out of the while loop
            EXIT;
        End If;

        ---------------------------------------------------
        -- Examine the steps for this job to determine actual start/End times
        ---------------------------------------------------

        _startMin := Null;
        _finishMax := Null;
        _processingTimeMinutes := 0;

        -- Note: You can use the following query to update _startMin and _finishMax

        -- However, when a job has some completed steps and some not yet started, this query
        -- will trigger the warning 'Null value is eliminated by an aggregate or other Set operation'

        -- The warning can be safely ignored, but tends to bloat up the Sql Server Agent logs,
        -- so we are instead populating _startMin and _finishMax separately

        /*
        SELECT MIN(start),
               MAX(finish)
        INTO _startMin, _finishMax
        FROM sw.t_job_steps
        WHERE job = _jobInfo.Job;
        */

        -- Update _startMin
        -- Note that if no steps have started yet, _startMin will be Null
        SELECT MIN(start)
        INTO _startMin
        FROM sw.t_job_steps
        WHERE job = _jobInfo.Job AND Not start Is Null;

        -- Update _finishMax
        -- Note that if no steps have finished yet, _finishMax will be Null
        SELECT MAX(finish)
        INTO _finishMax
        FROM sw.t_job_steps
        WHERE job = _jobInfo.Job AND Not finish Is Null;

        ---------------------------------------------------
        -- Roll up step completion comments
        ---------------------------------------------------
        --
        --
        SELECT string_agg(Completion_Message, '; ')
        INTO _comment
        FROM sw.t_job_steps
        WHERE job = _jobInfo.Job AND Not completion_message Is Null

        ---------------------------------------------------
        -- Examine the steps for this job to determine total processing time
        --
        -- Steps with the same Step Tool name are assumed to be steps that can run in parallel;
        -- therefore, we use a MAX(ProcessingTime) on steps with the same Step Tool name
        ---------------------------------------------------

        SELECT ProcTimeMinutes_CompletedSteps
        INTO _processingTimeMinutes
        FROM V_Job_Processing_Time
        WHERE Job = _jobInfo.Job;

        _processingTimeMinutes := Coalesce(_processingTimeMinutes, 0);

        If _infoOnly Then

            INSERT INTO Tmp_JobStatePreview (job, OldState, NewState)
            SELECT job, state, _jobInfo.NewJobStateInBroker
            FROM sw.t_jobs
            WHERE job = _jobInfo.Job;

        Else

            ---------------------------------------------------
            -- Update local job state, timestamp (if appropriate), and comment
            ---------------------------------------------------
            --
            UPDATE sw.t_jobs
            Set
                state = _jobInfo.NewJobStateInBroker,
                start =
                    CASE WHEN _jobInfo.NewJobStateInBroker >= 2                     -- job state is 2 or higher
                    THEN Coalesce(_startMin, CURRENT_TIMESTAMP)
                    ELSE Start
                    End If;,
                Finish =
                    CASE WHEN _jobInfo.NewJobStateInBroker IN (4, 5, 7)             -- 4=Complete, 5=Failed, 7=No Intermediate Files Created
                    THEN _finishMax
                    ELSE Finish
                    END LOOP;,
                Comment =
                    CASE WHEN _jobInfo.NewJobStateInBroker IN (5) THEN _comment     -- 5=Failed
                    WHEN _jobInfo.NewJobStateInBroker IN (4, 7)                     -- 4=Complete, 7=No Intermediate Files Created
                    THEN public.append_to_text(Comment, _comment, 0, '; ', 1024)
                    ELSE Comment
                    END,
                Runtime_Minutes = _processingTimeMinutes
            WHERE Job = _jobInfo.Job

        End If;

        ---------------------------------------------------
        -- Figure out what DMS job state should be
        -- and update it
        ---------------------------------------------------
        --
        _newDMSJobState := CASE _jobInfo.NewJobStateInBroker;
                                    WHEN 2 THEN 2
                                    WHEN 4 THEN 4
                                    WHEN 5 THEN 5
                                    WHEN 7 THEN 7
                                    Else 99
                           END;

        ---------------------------------------------------
        -- If this job has a data extraction step with message 'No results above threshold',
        -- change the job state to 14=No Export
        ---------------------------------------------------
        --
        If _newDMSJobState = 4 Then
            -- State 4: Complete
            --
            If Exists ( SELECT Step_Number Then
                        FROM sw.t_job_steps;
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
        --
        If _newDMSJobState = 4 Then
            -- State 4: Complete
            --
            If Exists ( SELECT Step_Number
                        FROM sw.t_job_steps;
                        WHERE Job = _jobInfo.Job AND
                              Completion_Message LIKE '%No results in DeconTools Isos file%' AND
                              tool LIKE 'Decon%' ) Then
                _newDMSJobState := 14;
            End If;
        End If;

        ---------------------------------------------------
        -- Decide on the fasta file name to save in job
        -- In addition, check whether the job has a Propagation mode of 1
        ---------------------------------------------------
        --
        If _jobInfo.DatasetID <> 0 Then

            SELECT CASE WHEN protein_collection_list = 'na'
                        THEN organism_db_name
                        Else _jobInfo.OrgDBName
                   END,
                   propagation_mode
            INTO _orgDBName, _jobPropagationMode
            FROM public.T_Analysis_Job
            WHERE job = _jobInfo.Job;

            If FOUND Then
                _jobInDMS := true;
            End If;

        Else

            SELECT _jobInfo.OrgDBName, propagation_mode
            INTO _orgDBName, _jobPropagationMode
            FROM public.T_Analysis_Job
            WHERE job = _jobInfo.Job;

            If FOUND Then
                _jobInDMS := true;
            End If;

        End If;

        ---------------------------------------------------
        -- If the DMS job state is 4=complete, but _jobPropagationMode is non-zero,
        -- then change the DMS job state to 14=No Export
        ---------------------------------------------------
        --
        If _newDMSJobState = 4 AND Coalesce(_jobPropagationMode, 0) <> 0 Then
            _newDMSJobState := 14;
        End If;

        ---------------------------------------------------
        -- Are we enabled for making changes to DMS?
        ---------------------------------------------------
        --
        If Not _bypassDMS AND _jobInDMS And Not _infoOnly Then
        --<c1>
            -- DMS changes enabled, update DMS job state

            -- Uncomment to debug
            -- Declare _debugMsg text = 'Calling update_analysis_job_processing_stats for job ' || _jobInfo.Job::text
            -- exec PostLogEntry 'Debug', _debugMsg, 'UpdateJobState'

            -- Compute the value for _updateCode, which is used as a safety feature to prevent unauthorized job updates
            -- Procedure update_analysis_job_processing_stats will re-compute _updateCode based on _jobInfo.Job,
            -- and if the values don't match, the update is not performed

            If char_length(_comment) <= 512 Then
                _jobCommentAddnl := _comment;
            Else
                _jobCommentAddnl := Substring(_comment, 1, 512);
            End If;

            If _jobInfo.Job % 2 = 0 Then
                _updateCode := (_jobInfo.Job % 220) + 14;
            Else
                _updateCode := (_jobInfo.Job % 125) + 11;
            End If;

            Call public.update_analysis_job_processing_stats (
                    _job => _jobInfo.Job,
                    _newDMSJobState => _newDMSJobState,
                    _newBrokerJobState => _jobInfo.NewJobStateInBroker,
                    _jobStart => _startMin,
                    _jobFinish => _finishMax,
                    _resultsDirectoryName => _jobInfo.ResultsDirectoryName,
                    _assignedProcessor => 'Job_Broker',
                    _jobCommentAddnl => _jobCommentAddnl,
                    _organismDBName => _orgDBName,
                    _processingTimeMinutes => _processingTimeMinutes,
                    _updateCode => _updateCode,
                    _infoOnly => false,
                    _message => _message,           -- Output
                    _returncode => _returnCode);    -- Output

            If _returnCode <> '' Then
                Call public.post_log_entry ('Error', _message, 'Update_Job_State', 'sw');
            End If;

        End If; --</c1>

        If Not _infoOnly Then
            If _jobInfo.NewJobStateInBroker IN (4,5) Then
                ---------------------------------------------------
                -- Save job history
                ---------------------------------------------------
                --
                Call sw.copy_job_to_history (_jobInfo.Job, _jobInfo.NewJobStateInBroker, _message => _message);
            End If;

        End If;

        _jobsProcessed := _jobsProcessed + 1;

        If extract(epoch FROM (clock_timestamp() - _lastLogTime)) >= _loopingUpdateInterval Then
            _statusMessage := '... Updating job state: ' || _jobsProcessed::text || ' / ' || _jobCountToProcess::text;
            Call public.post_log_entry ('Progress', _statusMessage, 'Update_Job_State', 'sw');
            _lastLogTime := clock_timestamp();
        End If;

        If _maxJobsToProcess > 0 And _jobsProcessed >= _maxJobsToProcess Then
            -- Break out of the while loop
            EXIT
        End If;

    END LOOP;

    If _infoOnly Then
        ---------------------------------------------------
        -- Preview changes that would be made via the above while loop
        ---------------------------------------------------
        --

        -- ToDo: Update this to use RAISE INFO

        SELECT *
        FROM Tmp_JobStatePreview
        ORDER BY Job
    End If;

    ---------------------------------------------------
    -- Look for jobs in DMS that are failed, yet are not failed in sw.t_jobs
    -- Also look for jobs listed as new that are actually in progress
    ---------------------------------------------------
    --
    If _bypassDMS Then
        DROP TABLE Tmp_ChangedJobs;

        If _infoOnly Then
            DROP TABLE Tmp_JobStatePreview;
        End If;

        RETURN;
    End If;

    CREATE TEMP TABLE Tmp_JobsToReset (
        Job int not null,
        NewState int not null
    );

    -- Look for jobs that are listed as Failed in DMS, but are in-progress here
    --
    INSERT INTO Tmp_JobsToReset (job, NewState )
    SELECT DMSJobs.job AS Job,
           J.state AS NewState
    FROM public.T_Analysis_Job AS DMSJobs
         INNER JOIN sw.t_jobs AS J
           ON J.job = DMSJobs.job
    WHERE DMSJobs.state_id = 5 AND
          J.state IN (1, 2, 4);

    -- Also look for jobs that are in state New in DMS, but are in-progress here
    --
    INSERT INTO Tmp_JobsToReset (job, NewState )
    SELECT DMSJobs.job AS Job,
           J.state AS NewState
    FROM public.T_Analysis_Job AS DMSJobs
         INNER JOIN sw.t_jobs AS J
           ON J.job = DMSJobs.job
    WHERE DMSJobs.state_id = 1 AND
          J.state IN (2);

    If Not Exists (SELECT job FROM Tmp_JobsToReset) Then
        DROP TABLE Tmp_ChangedJobs;
        DROP TABLE Tmp_JobsToReset;

        If _infoOnly Then
            DROP TABLE Tmp_JobStatePreview;
        End If;
    End If;

    -- Add an index to Tmp_JobsToReset, which will be beneficial if Tmp_JobsToReset has a large number of jobs
    CREATE INDEX IX_Tmp_JobsToReset ON Tmp_JobsToReset (Job);

    FOR _jobInfo IN
        SELECT Job, MAX(NewState) As NewJobStateInBroker
        FROM Tmp_JobsToReset
        GROUP BY Job
        ORDER BY Job
    LOOP
        -- Compute the value for _updateCode, which is used as a safety feature to prevent unauthorized job updates
        -- Procedure will re-compute _updateCode based on _jobInfo.Job,
        -- and if the values don't match, the update is not performed

        If _jobInfo.Job % 2 = 0 Then
            _updateCode := (_jobInfo.Job % 220) + 14;
        Else
            _updateCode := (_jobInfo.Job % 125) + 11;
        End If;

        -- Update the job start time based on the job steps
        -- Note that if no steps have started yet, _startMin will be Null
        _startMin := null;

        SELECT MIN(start)
        INTO _startMin
        FROM sw.t_job_steps
        WHERE (job = _jobInfo.Job) AND Not start Is Null;

        Call public.update_failed_job_now_in_progress (
                _job => _jobInfo.Job,
                _newBrokerJobState => _jobInfo.NewJobStateInBroker,
                _jobStart => _startMin,
                _updateCode => _updateCode,
                _infoOnly => _infoOnly,
                _message => _message,      -- Output
                _returncode => _returnCode);        -- Output

        If _returnCode <> '' Then
            Call public.post_log_entry ('Error', _message, 'Update_Job_State', 'sw');
        End If;

    END LOOP;

    DROP TABLE Tmp_ChangedJobs;
    DROP TABLE Tmp_JobsToReset;

    If _infoOnly Then
        DROP TABLE Tmp_JobStatePreview;
    End If;

END
$$;

COMMENT ON PROCEDURE sw.update_job_state IS 'UpdateJobState';
