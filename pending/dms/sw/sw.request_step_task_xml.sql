--
CREATE OR REPLACE PROCEDURE sw.request_step_task_xml
(
    _processorName text,
    INOUT _job int = 0,
    INOUT _parameters text default '',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoLevel int = 0,
    _analysisManagerVersion text = '',
    _remoteInfo text = '',
    _jobCountToPreview int = 10,
    _useBigBangQuery boolean = true,
    _throttleByStartTime int = 0,
    _maxStepNumToThrottle int = 10,
    _throttleAllStepTools int = 0,
    _logSPUsage boolean = false,
    INOUT _returnCode text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Looks for analysis job step that is appropriate for the given Processor Name.
**      If found, step is assigned to caller
**
**      Job assignment will be based on:
**      Assignment type:
**         Exclusively associated steps ('Exclusive Association', aka Association_Type=1):
**         Directly associated steps ('Specific Association', aka Association_Type=2):
**         Directly associated steps (Generic) ('Specific Association', aka Association_Type=2):
**         Non-associated steps ('Non-associated', aka Association_Type=3):
**         Generic processing steps ('Non-associated Generic', aka Association_Type=4):
**         No processing load available on machine, aka Association_Type=101 (disqualified)
**         Transfer tool steps for jobs that are in the midst of an archive operation, aka Association_Type=102 (disqualified)
**         Specifically assigned to alternate processor, aka Association_Type=103 (disqualified)
**         Too many recently started job steps for the given tool, aka Association_Type=104 (disqualified)
**      Job-Tool priority
**      Job priority
**      Job number
**      Step Number
**      Max_Job_Priority for the step tool associated with a manager
**      Next_Try
**
**  Arguments:
**    _processorName            Name of the processor (aka manager) requesting a job
**    _job                      Job number assigned; 0 if no job available
**    _parameters               job step parameters (in XML)
**    _message                  Output message
**    _infoLevel                Set to 1 to preview the job that would be returned; if 2, will print debug statements
**    _analysisManagerVersion   Used to update T_Local_Processors
**    _remoteInfo               Provided by managers that stage jobs to run remotely; used to assure that we don't stage too many jobs at once and to assure that we only check remote progress using a manager that has the same remote info as a job step
**    _jobCountToPreview        The number of jobs to preview when _infoLevel >= 1
**    _useBigBangQuery          Ignored and always set to 1 by this procedure (When non-zero, uses a single, large query to find candidate steps, which can be very expensive if there is a large number of active jobs (i.e. over 10,000 active jobs))
**    _throttleByStartTime      Set to 1 to limit the number of job steps that can start simultaneously on a given storage server (to avoid overloading the disk and network I/O on the server); this is no longer a necessity because copying of large files now uses lock files (effective January 2013)
**    _maxStepNumToThrottle     Only used if _throttleByStartTime is non-zero
**    _throttleAllStepTools     Only used if _throttleByStartTime is non-zero; when 0, will not throttle Sequest or Results_Transfer steps
**
**  Auth:   grk
**  Date:   08/23/2008 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          12/03/2008 grk - included processor-tool priority in assignement logic
**          12/04/2008 mem - Now returning _jobNotAvailableErrorCode if _processorName is not in T_Local_Processors
**          12/11/2008 mem - Rearranged preference order for job assignment priorities
**          12/11/2008 grk - Rewrote to use tool/processor priority in assignment logic
**          12/29/2008 mem - Now setting Finish to Null when a job step's state changes to 4=Running
**          01/13/2009 mem - Added parameter AnalysisManagerVersion (Ticket #714, http://prismtrac.pnl.gov/trac/ticket/714)
**          01/14/2009 mem - Now checking for T_Jobs.State = 8 (holding)
**          01/15/2009 mem - Now previewing the next 10 available jobs when _infoLevel <> 0 (Ticket #716, http://prismtrac.pnl.gov/trac/ticket/716)
**          01/25/2009 mem - Now checking for Enabled > 0 in T_Processor_Tool
**          02/09/2009 mem - Altered job step ordering to account for parallelized Inspect jobs
**          02/18/2009 grk - Populating candidate table with single query ("big-bang") instead of multiple queries
**          02/26/2009 mem - Now making an entry in T_Job_Step_Processing_Log for each job step assigned
**          05/14/2009 mem - Fixed logic that checks whether _cpuLoadExceeded should be non-zero
**                         - Updated to report when a job is invalid for this processor, but is specifically associated with another processor (Association_Type 103)
**          06/02/2009 mem - Optimized Big-bang query (which populates Tmp_CandidateJobSteps) due to high LockRequest/sec rates when we have thousands of active jobs (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**                         - Added parameter _useBigBangQuery to allow for disabling use of the Big-Bang query
**          06/03/2009 mem - When finding candidate tasks, now treating Results_Transfer steps as step '100' so that they are assigned first, and so that they are assigned grouped by Job when multiple Results_Transfer tasks are 'Enabled' for a given job
**          08/20/2009 mem - Now checking for _machine in T_Machines when _infoLevel is non-zero
**          09/02/2009 mem - Now using T_Processor_Tool_Groups and T_Processor_Tool_Group_Details to determine the processor tool priorities for the given processor
**          09/03/2009 mem - Now verifying that the processor is enabled and the processor tool group is enabled
**          10/12/2009 mem - Now treating enabled states <= 0 as disabled for processor tool groups
**          03/03/2010 mem - Added parameters _throttleByStartTime and _maxStepNumToThrottle
**          03/10/2010 mem - Fixed bug that ignored _maxStepNumToThrottle when updating Tmp_CandidateJobSteps
**          08/20/2010 mem - No longer ordering by step number Descending prior to job number; this caused problems choosing the next appropriate Sequest job since Sequest_DTARefinery jobs run Sequest as step 4 while normal Sequest jobs run Sequest as step 3
**                         - Sort order is now: Association_Type, Tool_Priority, Job Priority, Favor Results_Transfer steps, Job, Step
**          09/09/2010 mem - Bumped _maxStepNumToThrottle up to 10
**                         - Added parameter _throttleAllStepTools, defaulting to 0 (meaning we will not throttle Sequest or Results_Transfer steps)
**          09/29/2010 mem - Tweaked throttling logic to move the Step_Tool exclusion test to the outer WHERE clause
**          06/09/2011 mem - Added parameter _logSPUsage, which posts a log entry to T_SP_Usage if non-zero
**          10/17/2011 mem - Now considering Memory_Usage_MB
**          11/01/2011 mem - Changed _holdoffWindowMinutes from 7 to 3 minutes
**          12/19/2011 mem - Now showing memory amounts in 'Not enough memory available' error message
**          04/25/2013 mem - Increased _maxSimultaneousJobCount from 10 to 75; this is feasible since the storage servers now have the DMS_LockFiles share, which is used to prioritize copying large files
**          01/10/2014 mem - Now only assigning Results_Transfer tasks to the storage server on which the dataset resides
**                         - Changed _throttleByStartTime to 0
**          09/24/2014 mem - Removed reference to Machine in T_Job_Steps
**          04/21/2015 mem - Now using column Uses_All_Cores
**          06/01/2015 mem - No longer querying T_Local_Job_Processors since we have deprecated processor groups
**                         - Also now ignoring GP_Groups and Available_For_General_Processing
**          11/18/2015 mem - Now using Actual_CPU_Load instead of CPU_Load
**          02/15/2016 mem - Re-enabled use of T_Local_Job_Processors and processor groups
**                         - Added job step exclusion using T_Local_Processor_Job_Step_Exclusion
**          05/04/2017 mem - Filter on column Next_Try
**          05/11/2017 mem - Look for jobs in state 2 or 9
**                           Commit the transaction earlier to reduce the time that a HoldLock is on table T_Job_Steps
**                           Pass _jobIsRunningRemote to GetJobStepParamsXML
**          05/15/2017 mem - Consider MonitorRunningRemote when looking for candidate jobs
**          05/16/2017 mem - Do not update T_Job_Step_Processing_Log if checking the status of a remotely running job
**          05/18/2017 mem - Add parameter _remoteInfo
**          05/22/2017 mem - Limit assignment of RunningRemote jobs to managers with the same RemoteInfoID as the job
**          05/23/2017 mem - Update Remote_Start, Remote_Finish, and Remote_Progress
**          05/26/2017 mem - Treat state 9 (Running_Remote) as having a CPU_Load of 0
**          06/08/2017 mem - Remove use of column MonitorRunningRemote in T_Machines since _remoteInfo replaces it
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          10/03/2017 mem - Use column Max_Job_Priority in table T_Processor_Tool_Group_Details
**          02/17/2018 mem - When previewing job candidates, show jobs that would be excluded due to Next_Try
**          03/08/2018 mem - Reset Next_Try and Retry_Count when a job is assigned
**          03/14/2018 mem - When finding job steps to assign, prevent multiple managers on a given machine from analyzing the same dataset simultaneously (filtering on job started within the last 10 minutes)
**          03/29/2018 mem - Ignore CPU checks when the manager runs jobs remotely (_remoteInfoID is greater than 1 because _remoteInfo is non-blank)
**                         - Update Remote_Info_ID when assigning a new job, both in T_Job_Steps and in T_Job_Step_Processing_Log
**          02/21/2019 mem - Reset Completion_Code and Completion_Message when a job is assigned
**          01/31/2020 mem - Add _returnCode, which duplicates the integer returned by this procedure; _returnCode is varchar for compatibility with Postgres error codes
**          03/29/2023 mem - Add support for state 11 (Waiting_For_File)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
    _jobAssigned boolean := false;
    _candidateJobStepsToRetrieve int := 15;
    _holdoffWindowMinutes int;
    _maxSimultaneousJobCount int;
    _remoteInfoID int := 0;
    _maxSimultaneousRunningRemoteSteps int := 0;
    _runningRemoteLimitReached int := 0;
    _jobNotAvailableErrorCode text := 'U5301'
    _machine text;
    _availableCPUs int;
    _availableMemoryMB int;
    _processorState char;
    _processorID int;
    _enabled int;
    _processToolGroup text;
    _processorDoesGP int := -1;
    _availableProcessorTools TABLE (;
    _stepsRunningRemotely int := 0;
    _processorGP int;
    _cpuLoadExceeded int := 0;
    _associationTypeIgnoreThreshold int := 10;
    _step int := 0;
    _jobIsRunningRemote int := 0;
BEGIN
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- These 3 hard-coded values give optimal performance
    -- (note that _useBigBangQuery overrides the value passed into this procedure)
    ---------------------------------------------------
    --
    _holdoffWindowMinutes := 3               ; -- Typically 3
    _maxSimultaneousJobCount := 75           ; -- Increased from 10 to 75 on 4/25/2013
    _useBigBangQuery := 1                    ; -- Always forced by this procedure to be 1

    ---------------------------------------------------
    -- Validate the inputs; clear the outputs
    ---------------------------------------------------

    _processorName := Coalesce(_processorName, '');
    _job := 0;
    _parameters := '';
    _message := '';
    _returnCode:= '';
    _infoLevel := Coalesce(_infoLevel, 0);
    _analysisManagerVersion := Coalesce(_analysisManagerVersion, '');
    _remoteInfo := Coalesce(_remoteInfo, '');
    _jobCountToPreview := Coalesce(_jobCountToPreview, 10);
    If _jobCountToPreview <= 0 Then
        _jobCountToPreview := 10;
    End If;

    _useBigBangQuery := Coalesce(_useBigBangQuery, 1);

    _throttleByStartTime := Coalesce(_throttleByStartTime, 0);
    _maxStepNumToThrottle := Coalesce(_maxStepNumToThrottle, 10);
    _throttleAllStepTools := Coalesce(_throttleAllStepTools, 0);

    If _maxStepNumToThrottle < 1 Then
        _maxStepNumToThrottle := 1000000;
    End If;

    If _jobCountToPreview > _candidateJobStepsToRetrieve Then
        _candidateJobStepsToRetrieve := _jobCountToPreview;
    End If;

    ---------------------------------------------------
    -- The analysis manager expects a non-zero
    -- return value if no jobs are available
    -- Code 'U53000' is used for this
    ---------------------------------------------------
    --

    If _infoLevel > 1 Then
        RAISE INFO '%, RequestStepTaskXML: Starting; make sure this is a valid processor', public.timestamp_text_immutable(clock_timestamp());
    End If;

    ---------------------------------------------------
    -- Make sure this is a valid processor (and capitalize it according to sw.t_local_processors)
    ---------------------------------------------------
    --
    SELECT 1,        -- Prior to May 2015 used: _processorDoesGP = gp_groups
           machine,
           processor_name,
           state,
           processor_id
    INTO _processorDoesGP, _machine, _processorName, _processorState, _processorID
    FROM sw.t_local_processors
    WHERE processor_name = _processorName;

    If Not FOUND Then
        ---------------------------------------------------
        -- Processor not found
        --
        -- _returnCode will be 'U5301'
        ---------------------------------------------------

        _message := 'Processor not defined in sw.t_local_processors: ' || _processorName;
        _returnCode := _jobNotAvailableErrorCode;

        INSERT INTO sw.t_sp_usage( posted_by, processor_id, calling_user )
        VALUES('RequestStepTaskXML', null, session_user || ' Invalid processor: ' || _processorName)

        RETURN;
    End If;

    ---------------------------------------------------
    -- Update processor's request timestamp
    -- (to show when the processor was most recently active)
    ---------------------------------------------------
    --
    If _infoLevel = 0 Then
        UPDATE sw.t_local_processors
        SET latest_request = CURRENT_TIMESTAMP,
            manager_version = _analysisManagerVersion
        WHERE processor_name = _processorName
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If Coalesce(_logSPUsage, 0) <> 0 Then
            INSERT INTO sw.t_sp_usage (;
        End If;
                            Posted_By,
                            ProcessorID,
                            Calling_User )
            VALUES('RequestStepTaskXML', _processorID, session_user)

    End If;

    ---------------------------------------------------
    -- Abort if not enabled in sw.t_local_processors
    ---------------------------------------------------
    If _processorState <> 'E' Then
        _message := 'Processor is not enabled in sw.t_local_processors: ' || _processorName;
        _returnCode := _jobNotAvailableErrorCode;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make sure this processor's machine is in sw.t_machines
    ---------------------------------------------------
    If Not Exists (SELECT * FROM sw.t_machines Where machine = _machine) Then
        _message := 'machine "' || _machine || '" is not present in sw.t_machines (but is defined in sw.t_local_processors for processor "' || _processorName || '")';
        _returnCode := _jobNotAvailableErrorCode;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Lookup the number of CPUs available and amount of memory available for this processor's machine
    -- In addition, make sure this machine is a member of an enabled group
    ---------------------------------------------------

    SELECT M.cpus_available,
           M.memory_available,
           PTG.enabled,
           PTG.group_name
    INTO _availableCPUs, _availableMemoryMB, _enabled, _processToolGroup
    FROM sw.t_machines M
         INNER JOIN sw.t_processor_tool_groups PTG
           ON M.proc_tool_group_id = PTG.group_id
    WHERE M.machine = _machine;

    If Not Found Then
        _message := format('Machine "%s" not found in sw.t_machines (for processor %s)', _machine, _processorName);
        _returnCode := _jobNotAvailableErrorCode;
        RETURN;
    End If

    If _enabled <= 0 Then
        _message := 'Machine "' || _machine || '" is in a disabled tool group; no tasks will be assigned for processor ' || _processorName;
        _returnCode := _jobNotAvailableErrorCode;
        RETURN;
    End If;

    If _infoLevel > 0 Then
    -- <PreviewProcessorTools>

        ---------------------------------------------------
        -- Get list of step tools currently assigned to processor
        ---------------------------------------------------
        --
            Processor_Tool_Group text,
            Tool_Name text,
            CPU_Load int,
            Memory_Usage_MB int,
            Tool_Priority int,
            GP int,                    -- 1 when tool is designated as a "Generic Processing" tool, meaning it ignores processor groups
            Max_Job_Priority int,
            Exceeds_Available_CPU_Load int NOT NULL,
            Exceeds_Available_Memory int NOT NULL
        )
        --
        INSERT INTO _availableProcessorTools (
            Processor_Tool_Group, tool_name,
            cpu_load, memory_usage_mb,
            Tool_Priority, GP, max_job_priority,
            Exceeds_Available_CPU_Load,
            Exceeds_Available_Memory)
        SELECT PTG.group_name,
               PTGD.tool_name,
               ST.cpu_load,
               ST.memory_usage_mb,
               PTGD.priority,
               1 AS GP,            -- Prior to May 2015 used: CASE WHEN ST.Available_For_General_Processing = 'N' THEN 0 ELSE 1 END AS GP,
               PTGD.max_job_priority,
               CASE WHEN ST.cpu_load > _availableCPUs THEN 1 ELSE 0 END AS Exceeds_Available_CPU_Load,
               CASE WHEN ST.memory_usage_mb > _availableMemoryMB THEN 1 ELSE 0 END AS Exceeds_Available_Memory
        FROM sw.t_machines M
             INNER JOIN sw.t_local_processors LP
               ON M.machine = LP.machine
             INNER JOIN sw.t_processor_tool_groups PTG
               ON M.proc_tool_group_id = PTG.group_id
             INNER JOIN sw.t_processor_tool_group_details PTGD
               ON PTG.group_id = PTGD.group_id AND
                  LP.proc_tool_mgr_id = PTGD.mgr_id
             INNER JOIN sw.t_step_tools ST
               ON PTGD.tool_name = ST.step_tool
        WHERE LP.processor_name = _processorName AND
              PTGD.enabled > 0
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        -- Preview the tools for this processor (as defined in _availableProcessorTools, which we just populated)
        SELECT PT.Processor_Tool_Group,
               PT.Tool_Name,
               PT.CPU_Load,
               PT.Memory_Usage_MB,
               PT.Tool_Priority,
               PT.Max_Job_Priority,
               MachineQ.total_cpus,
               MachineQ.cpus_available,
               MachineQ.total_memory_mb,
               MachineQ.memory_available,
               PT.Exceeds_Available_CPU_Load,
               PT.Exceeds_Available_Memory,
             CASE WHEN _processorDoesGP > 0 THEN 'Yes' ELSE 'No' END AS Processor_Does_General_Proc
        FROM _availableProcessorTools PT
             CROSS JOIN ( SELECT M.total_cpus,
           M.cpus_available,
               M.total_memory_mb,
                                 M.memory_available
                          FROM sw.t_local_processors LP
                             INNER JOIN sw.t_machines M
                    ON LP.machine = M.machine
                          WHERE LP.processor_name = _processorName ) MachineQ
        ORDER BY PT.Tool_Name

    End If; -- </PreviewProcessorTools>

    If _remoteInfo <> '' Then
    -- <CheckRunningRemoteTasks>

        ---------------------------------------------------
        -- Get list of job steps that are currently RunningRemote
        -- on the remote server associated with this manager
        ---------------------------------------------------
        --

        _remoteInfoID := get_remote_info_id (_remoteInfo);

        -- Note that _remoteInfoID 1 means the _remoteInfo is 'Unknown'

        If _remoteInfoID > 1 Then
            If _infoLevel > 0 Then
                RAISE INFO '_remoteInfoID is % for %', _remoteInfoID, _remoteInfo);
            End If;

            SELECT COUNT(*)
            INTO _stepsRunningRemotely
            FROM sw.t_job_steps
            WHERE state IN (4, 9) AND remote_info_id = _remoteInfoID;
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _stepsRunningRemotely > 0 Then
                SELECT max_running_job_steps
                INTO _maxSimultaneousRunningRemoteSteps
                FROM sw.t_remote_info
                WHERE remote_info_id = _remoteInfoID
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                If _stepsRunningRemotely >= Coalesce(_maxSimultaneousRunningRemoteSteps, 1) Then
                    _runningRemoteLimitReached := 1;
                End If;
            End If;

            If _infoLevel > 0 Then
                -- Preview RunningRemote tasks on the remote host associated with this manager
                --
                SELECT RemoteInfo.remote_info_id,
                       RemoteInfo.remote_info,
                       RemoteInfo.most_recent_job,
                       RemoteInfo.last_used,
                       RemoteInfo.max_running_job_steps,
                       JS.Job,
                       JS.Dataset,
                       JS.StateName,
                       JS.State,
                       JS.Start,
                       JS.Finish
                FROM sw.t_remote_info RemoteInfo
                     INNER JOIN V_Job_Steps JS
                       ON RemoteInfo.remote_info_id = JS.remote_info_id
                WHERE RemoteInfo.remote_info_id = _remoteInfoID AND
                      JS.State IN (4, 9)
                ORDER BY Job, Step
            End If;

        Else
            If _infoLevel > 0 Then
                RAISE INFO '%', 'Could not resolve ' || _remoteInfo || ' to Remote_Info_ID';
            End If;
        End If;

    End If; -- </CheckRunningRemoteTasks>

    ---------------------------------------------------
    -- Temp table to hold job step candidates
    -- for possible assignment
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_CandidateJobSteps (
        Seq int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Job int,
        Step int,
        State int,
        Job_Priority int,
        Tool text,
        Tool_Priority int,
        Max_Job_Priority int,
        Memory_Usage_MB int,
        Association_Type int NOT NULL,                -- Valid types are: 1=Exclusive Association, 2=Specific Association, 3=Non-associated, 4=Non-Associated Generic, etc.
        Machine text,
        Alternate_Specific_Processor text,        -- This field is only used if _infoLevel is non-zero and if jobs exist with Association_Type 103
        Storage_Server text,
        Dataset_ID int,
        Next_Try timestamp
    )

    If _infoLevel > 1 Then
        RAISE INFO '%, RequestStepTaskXML: Populate Tmp_CandidateJobSteps', public.timestamp_text_immutable(clock_timestamp());
    End If;

    ---------------------------------------------------
    -- Look for available Results_Transfer steps
    -- Only assign a Results_Transfer step to a manager running on the job's storage server
    ---------------------------------------------------

    If Exists (SELECT * Then
               FROM sw.t_local_processors LP;
                    INNER JOIN sw.t_machines M
                      ON LP.machine = M.machine
                    INNER JOIN sw.t_processor_tool_group_details PTGD
                      ON LP.ProcTool_Mgr_ID = PTGD.mgr_id AND
                         M.proc_tool_group_id = PTGD.group_id
               WHERE LP.Processor_Name = _processorName And
                     PTGD.enabled > 0 And
                     PTGD.tool_name = 'Results_Transfer') Then

        -- Look for Results_Transfer candidates
        --
        INSERT INTO Tmp_CandidateJobSteps (
            Job,
            Step,
            State,
            Job_Priority,
            Tool,
            Tool_Priority,
            Memory_Usage_MB,
            Storage_Server,
            Dataset_ID,
            Machine,
            Association_Type,
            Next_Try
        )
        SELECT TOP (_candidateJobStepsToRetrieve)
            JS.Job,
            JS.Step,
            JS.State,
            J.Priority AS Job_Priority,
            JS.Tool,
            1 As Tool_Priority,
            JS.Memory_Usage_MB,
            J.Storage_Server,
            J.Dataset_ID,
            TP.Machine,
            CASE
                WHEN (J.Archive_Busy = 1)
                    -- Transfer tool steps for jobs that are in the midst of an archive operation
                    -- The archive_busy flag in sw.t_jobs is updated by SyncJobInfo
                    -- It uses public.v_get_analysis_jobs_for_archive_busy to look for jobs that have an archive in progress
                    -- However, if the dataset has been in state 'Archive In Progress' for over 90 minutes, archive_busy will be changed back to 0 (false)
                    THEN 102
                WHEN J.Storage_Server Is Null
                    -- Results_Transfer step for job without a specific storage server
                    THEN 6
                WHEN JS.Next_Try > CURRENT_TIMESTAMP
                    -- Job won't start until after Next_Try
                    THEN 20
                ELSE 5   -- Results_Transfer step to be run on the job-specific storage server
            END AS Association_Type,
            JS.next_try
        FROM ( SELECT TJ.job,
                      TJ.priority,        -- Job_Priority
                      TJ.archive_busy,
                      TJ.storage_server,
                      TJ.dataset_id
               FROM sw.t_jobs TJ
               WHERE TJ.state <> 8
             ) J
             INNER JOIN sw.t_job_steps JS
               ON J.job = JS.job
             INNER JOIN ( SELECT LP.processor_name,
                                 M.machine
                          FROM sw.t_machines M
                               INNER JOIN sw.t_local_processors LP
                                 ON M.machine = LP.machine
                               INNER JOIN sw.t_processor_tool_group_details PTGD
                                 ON LP.proc_tool_mgr_id = PTGD.mgr_id AND
                                    M.proc_tool_group_id = PTGD.group_id
                          WHERE LP.processor_name = _processorName AND
                                PTGD.enabled > 0 AND
                                PTGD.tool_name = 'Results_Transfer'
             ) TP
               ON JS.Tool = 'Results_Transfer' AND
                  TP.machine = Coalesce(J.storage_server, TP.machine)        -- Must use Coalesce here to handle jobs where the storage server is not defined in sw.t_jobs
        WHERE JS.state = 2 And (CURRENT_TIMESTAMP > JS.next_try Or _infoLevel > 0)
        ORDER BY
            Association_Type,
            J.priority,        -- Job_Priority
            job,
            step
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount = 0 And _infoLevel <> 0 Then
            -- Look for results transfer tasks that need to be handled by another storage server
            --
            INSERT INTO Tmp_CandidateJobSteps (
                Job,
                Step,
                State,
                Job_Priority,
                Tool,
                Tool_Priority,
                Memory_Usage_MB,
                Storage_Server,
                Dataset_ID,
                Machine,
                Association_Type,
                Next_Try
            )
            SELECT TOP (_candidateJobStepsToRetrieve)
                JS.Job,
                JS.Step,
                JS.State,
                J.Priority AS Job_Priority,
                JS.Tool,
                1 As Tool_Priority,
                JS.Memory_Usage_MB,
                J.Storage_Server,
                J.Dataset_ID,
                TP.Machine,
                CASE
                    WHEN JS.Next_Try > CURRENT_TIMESTAMP
                        -- Job won't start until after Next_Try
                        THEN 20
                    WHEN (J.Archive_Busy = 1)
                        -- Transfer tool steps for jobs that are in the midst of an archive operation
                        THEN 102
                    ELSE 106  -- Results_Transfer step to be run on the job-specific storage server
                END AS Association_Type,
                JS.next_try
            FROM ( SELECT TJ.job,
                        TJ.priority,        -- Job_Priority
                        TJ.archive_busy,
                        TJ.storage_server,
                        TJ.dataset_id
                    FROM sw.t_jobs TJ
                    WHERE TJ.state <> 8
                  ) J
                  INNER JOIN sw.t_job_steps JS
                    ON J.job = JS.job
                  INNER JOIN ( SELECT LP.processor_name,
                                    M.machine
                            FROM sw.t_machines M
                                INNER JOIN sw.t_local_processors LP
                                    ON M.machine = LP.machine
                                INNER JOIN sw.t_processor_tool_group_details PTGD
                                    ON LP.proc_tool_mgr_id = PTGD.mgr_id AND
                                       M.proc_tool_group_id = PTGD.group_id
                            WHERE LP.processor_name = _processorName AND
                                  PTGD.enabled > 0 AND
                                  PTGD.tool_name = 'Results_Transfer'
                ) TP
                ON JS.Tool = 'Results_Transfer' AND
                   TP.machine <> J.storage_server
               WHERE JS.state = 2 And (CURRENT_TIMESTAMP > JS.next_try Or _infoLevel > 0)
            ORDER BY
                Association_Type,
                J.priority,        -- Job_Priority
                job,
                step
        End If;

    End If;

    ---------------------------------------------------
    -- Get list of viable job step assignments organized
    -- by processor in order of assignment priority
    ---------------------------------------------------
    --
    If _useBigBangQuery <> 0 OR _infoLevel <> 0 Then
    -- <UseBigBang>
        -- *********************************************************************************
        -- Big-bang query
        -- This query can be very expensive if there is a large number of active jobs
        -- and SQL Server gets confused about which indices to use (more likely on SQL Server 2005)
        --
        -- This can lead to huge "lock request/sec" rates, particularly when there are
        -- thouands of jobs in sw.t_jobs with state <> 8 and steps with state IN (2, 9)
        -- *********************************************************************************
        --
        INSERT INTO Tmp_CandidateJobSteps (
            Job,
            Step,
            State,
            Job_Priority,
            Tool,
            Tool_Priority,
            Memory_Usage_MB,
            Storage_Server,
            Dataset_ID,
            Machine,
            Association_Type,
            Next_Try
        )
        SELECT TOP (_candidateJobStepsToRetrieve)
            JS.Job,
            JS.Step,
            JS.State,
            J.Priority AS Job_Priority,
            JS.Tool,
            TP.Tool_Priority,
            JS.Memory_Usage_MB,
            J.Storage_Server,
            J.Dataset_ID,
            TP.Machine,
            CASE
                WHEN (TP.CPUs_Available < CASE WHEN JS.State = 9 Or _remoteInfoID > 1 Then -50
                                               ELSE TP.CPU_Load END)
                    -- No processing load available on machine
                    THEN 101
                WHEN (JS.Tool = 'Results_Transfer' AND J.Archive_Busy = 1)
                    -- Transfer tool steps for jobs that are in the midst of an archive operation
                    THEN 102
                WHEN (TP.Memory_Available < JS.Memory_Usage_MB)
                    -- Not enough memory available on machine
                    THEN 105
                WHEN JS.State = 2 AND _runningRemoteLimitReached > 0
                    -- Too many remote tasks are already running
                    THEN 107
                WHEN JS.State = 9 AND JS.Remote_Info_ID <> _remoteInfoID
                    -- Remotely running task; only check status using a manager with the same Remote_Info
                    THEN 108
                WHEN (JS.job IN (SELECT job FROM sw.t_local_job_processors WHERE processor = Processor_Name))
                    -- Directly associated steps (Generic) ('Specific Association', aka Association_Type=2):
                    THEN 2
                WHEN (NOT JS.job IN (SELECT job FROM sw.t_local_job_processors))
                    -- Generic processing steps ('Non-associated Generic', aka Association_Type=4):
                    THEN 4
                WHEN JS.Next_Try > CURRENT_TIMESTAMP
                    -- Job won't start until after Next_Try
                    THEN 20
                WHEN (JS.job IN (SELECT job FROM sw.t_local_job_processors))
                    -- Job associated with an alternate, specific processor
                    THEN 99
            /*
                ---------------------------------------------------
                -- Deprecated in May 2015:
                --
                WHEN (Processor_GP > 0 AND Tool_GP = 'Y' AND JS.job IN (SELECT job FROM sw.t_local_job_processors WHERE processor = Processor_Name))
                    -- Directly associated steps (Generic) ('Specific Association', aka Association_Type=2):
                    THEN 2
                WHEN (Processor_GP > 0 AND Tool_GP = 'Y')
                    -- Generic processing steps ('Non-associated Generic', aka Association_Type=4):
                    THEN 4
                WHEN (Processor_GP > 0 AND Tool_GP = 'N' AND JS.job IN (SELECT job FROM sw.t_local_job_processors WHERE processor = Processor_Name))
                    -- Directly associated steps ('Specific Association', aka Association_Type=2):
                    THEN 2
                WHEN (Processor_GP > 0 AND Tool_GP = 'N' AND NOT JS.job IN (SELECT job FROM sw.t_local_job_processors WHERE processor <> Processor_Name AND general_processing = 0))
                    -- Non-associated steps ('Non-associated', aka Association_Type=3):
                    THEN 3
                WHEN (Processor_GP = 0 AND Tool_GP = 'N' AND JS.job IN (SELECT job FROM sw.t_local_job_processors WHERE processor = Processor_Name AND general_processing = 0))
                    -- Exclusively associated steps ('Exclusive Association', aka Association_Type=1):
                    THEN 1
            */
                ELSE 100 -- not recognized assignment ('<Not recognized>')
            END AS Association_Type,
            JS.next_try
        FROM ( SELECT TJ.job,
                      TJ.priority,        -- Job_Priority
                      TJ.archive_busy,
                      TJ.storage_server,
                      TJ.dataset_id
               FROM sw.t_jobs TJ
               WHERE TJ.state <> 8
             ) J
             INNER JOIN sw.t_job_steps JS
               ON J.job = JS.job
             INNER JOIN (    -- Viable processors/step tool combinations (with CPU loading, memory usage,and processor group information)
                          SELECT LP.Processor_Name,
                                 LP.ID AS Processor_ID,
                                 PTGD.Tool_Name,
                                 PTGD.priority AS Tool_Priority,
                                 PTGD.Max_Job_Priority,
                                 /*
                                 ---------------------------------------------------
                                 -- Deprecated in May 2015:
                                 --
                                 LP.gp_groups AS Processor_GP,
                                 ST.available_for_general_processing AS Tool_GP,
                                 */
                                 M.cpus_available,
                                 ST.cpu_load,
                                 M.memory_available,
                                 M.machine
                          FROM sw.t_machines M
                               INNER JOIN sw.t_local_processors LP
                                 ON M.machine = LP.machine
                               INNER JOIN sw.t_processor_tool_group_details PTGD
                                 ON LP.proc_tool_mgr_id = PTGD.mgr_id AND
                                    M.proc_tool_group_id = PTGD.group_id
                               INNER JOIN sw.t_step_tools ST
                                 ON PTGD.tool_name = ST.step_tool
                          WHERE LP.processor_name = _processorName AND
                                PTGD.enabled > 0 AND
                                PTGD.tool_name <> 'Results_Transfer'        -- Candidate Result_Transfer steps were found above
             ) TP
               ON TP.tool_name = JS.tool
        WHERE (CURRENT_TIMESTAMP > JS.Next_Try Or _infoLevel > 0) AND
              J.priority <= TP.max_job_priority AND
              (JS.state In (2, 11) OR _remoteInfoID > 1 And JS.state = 9) AND
              NOT EXISTS (SELECT * FROM sw.t_local_processor_job_step_exclusion JSE WHERE JSE.processor_id = TP.processor_id And JSE.step = JS.Step)
        ORDER BY
            Association_Type,
            Tool_Priority,
            J.priority,        -- Job_Priority
            CASE WHEN JS.tool = 'Results_Transfer' Then 10    -- Give Results_Transfer steps priority so that they run first and are grouped by Job
                 ELSE 0
            END DESC,
            Job,
            Step
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
        -- </UseBigBang>
    Else
        -- <UseMultiStep>
        -- Not using the Big-bang query

        /*

        ---------------------------------------------------
        -- Deprecated in May 2015:
        --
        -- Lookup the GP_Groups count for this processor

        SELECT LP.gp_groups
        INTO _processorGP
        FROM sw.t_machines M
            INNER JOIN sw.t_local_processors LP
                ON M.machine = LP.machine
            INNER JOIN sw.t_processor_tool_group_details PTGD
                ON LP.proc_tool_mgr_id = PTGD.mgr_id AND
                M.proc_tool_group_id = PTGD.group_id
            INNER JOIN sw.t_step_tools ST
                ON PTGD.tool_name = ST.step_tool
        WHERE PTGD.enabled > 0 AND
              LP.processor_name = _processorName
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        _processorGP := Coalesce(_processorGP, 0);

        If _processorGP = 0 Then
        -- <LimitedProcessingMachine>
            -- Processor does not do general processing
            INSERT INTO Tmp_CandidateJobSteps (
                job,
                step,
                state,
                Job_Priority,
                tool,
                Tool_Priority,
                storage_server,
                dataset_id,
                machine,
                Association_Type,
                next_try
            )
            SELECT TOP (_candidateJobStepsToRetrieve)
                JS.job,
                step,
                state,
                J.priority AS Job_Priority,
                tool,
                Tool_Priority,
                J.storage_server,
                J.dataset_id,
                TP.machine,
                1 AS Association_Type,
                JS.next_try
            FROM ( SELECT TJ.job,
                          TJ.priority,        -- Job_Priority
                          TJ.archive_busy,
                          TJ.storage_server,
                          TJ.dataset_id
                   FROM sw.t_jobs TJ
               WHERE TJ.state <> 8 ) J
               INNER JOIN sw.t_job_steps JS
                   ON J.job = JS.job
                 INNER JOIN (    -- Viable processors/step tools combinations (with CPU loading and processor group information)
                              SELECT LP.processor_name,
                                     LP.processor_id AS Processor_ID,
                                     PTGD.tool_name,
                                     PTGD.priority AS Tool_Priority,
                                     LP.gp_groups AS Processor_GP,
                                     ST.available_for_general_processing AS Tool_GP,
                                     M.cpus_available,
                                     ST.cpu_load,
                                     M.memory_available,
                                     M.machine
                              FROM sw.t_machines M
                                   INNER JOIN sw.t_local_processors LP
                                     ON M.machine = LP.machine
                                   INNER JOIN sw.t_processor_tool_group_details PTGD
                                     ON LP.proc_tool_mgr_id = PTGD.mgr_id AND
                                        M.proc_tool_group_id = PTGD.group_id
                                   INNER JOIN sw.t_step_tools ST
                                     ON PTGD.tool_name = ST.step_tool
                              WHERE PTGD.enabled > 0 AND
                LP.processor_name = _processorName AND
                PTGD.tool_name <> 'Results_Transfer'        -- Candidate Result_Transfer steps were found above
                            ) TP
                   ON TP.tool_name = JS.tool
            WHERE (TP.cpus_available >= CASE WHEN JS.state = 9 THEN 0 ELSE TP.cpu_load END) AND
                  CURRENT_TIMESTAMP > JS.next_try AND
                  (JS.state In (2, 11) OR JS.state = 9 AND JS.remote_info_id = _remoteInfoId) AND
                  TP.memory_available >= JS.memory_usage_mb AND
                  NOT (tool = 'Results_Transfer' AND J.archive_busy = 1) AND
                  NOT EXISTS (SELECT * FROM sw.t_local_processor_job_step_exclusion JSE WHERE JSE.processor_id = TP.processor_id And JSE.step = JS.step) AND
                  -- Exclusively associated steps ('Exclusive Association', aka Association_Type=1):
                  -- (Processor_GP = 0 AND Tool_GP = 'N' AND JS.job IN (SELECT job FROM sw.t_local_job_processors WHERE processor = Processor_Name AND general_processing = 0))
            ORDER BY
                Association_Type,
                Tool_Priority,
                J.Priority,    -- Job_Priority
                CASE WHEN tool = 'Results_Transfer' Then 10    -- Give Results_Transfer steps priority so that they run first and are grouped by Job
                    ELSE 0
                End If; DESC,
                Job,
                Step
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

              -- </LimitedProcessingMachine>
        Else
              -- <GeneralProcessingMachine>
        */

            -- Processor does do general processing
            INSERT INTO Tmp_CandidateJobSteps (
                Job,
                Step,
                State,
                Job_Priority,
                Tool,
                Tool_Priority,
                Storage_Server,
                Dataset_ID,
                Machine,
                Association_Type,
                Next_Try
            )
            SELECT TOP (_candidateJobStepsToRetrieve)
                JS.Job,
                Step,
                State,
                J.Priority AS Job_Priority,
                Tool,
                Tool_Priority,
                J.Storage_Server,
                J.Dataset_ID,
                TP.Machine,
                CASE
                    WHEN JS.State = 2 AND _runningRemoteLimitReached > 0
                        -- Too many remote tasks are already running
                        THEN 107
                    WHEN JS.State = 9 AND JS.Remote_Info_ID <> _remoteInfoID
                        -- Remotely running task; only check status using a manager with the same Remote_Info
                        THEN 108
                    WHEN (JS.job IN (SELECT job FROM sw.t_local_job_processors WHERE processor = Processor_Name))
                        -- Directly associated steps (Generic) ('Specific Association', aka Association_Type=2):
                        THEN 2
                    WHEN (Not JS.job IN (SELECT job FROM sw.t_local_job_processors))
                        -- Generic processing steps ('Non-associated Generic', aka Association_Type=4):
                        THEN 4
                    WHEN JS.Next_Try > CURRENT_TIMESTAMP
                        -- Job won't start until after Next_Try
                        Then 20
                    WHEN (JS.job IN (SELECT job FROM sw.t_local_job_processors))
                        -- Job associated with an alternate, specific processor
                        THEN 99
                    ELSE 100    -- not recognized assignment ('<Not recognized>')
                END AS Association_Type,
                JS.next_try
            FROM ( SELECT TJ.job,
                          TJ.priority,        -- Job_Priority
                          TJ.archive_busy,
                          TJ.storage_server,
                          TJ.dataset_id
                   FROM sw.t_jobs TJ
                   WHERE TJ.state <> 8 ) J
                 INNER JOIN sw.t_job_steps JS
                   ON J.job = JS.job
                 INNER JOIN (    -- Viable processors/step tools combinations (with CPU loading and processor group information)
                              SELECT LP.Processor_Name,
                                     LP.ID as Processor_ID,
                                     PTGD.Tool_Name,
                                     PTGD.priority AS Tool_Priority,
                                     PTGD.Max_Job_Priority,
                                     /*
                                     ---------------------------------------------------
                                     -- Deprecated in May 2015:
                                     --
                                     ST.available_for_general_processing AS Tool_GP,
                                     */
                                     M.cpus_available,
                                     ST.cpu_load,
                                     M.memory_available,
                                     M.machine
                              FROM sw.t_machines M
                                   INNER JOIN sw.t_local_processors LP
                                     ON M.machine = LP.machine
                                   INNER JOIN sw.t_processor_tool_group_details PTGD
                                     ON LP.proc_tool_mgr_id = PTGD.mgr_id AND
                                        M.proc_tool_group_id = PTGD.group_id
                                   INNER JOIN sw.t_step_tools ST
                                     ON PTGD.tool_name = ST.step_tool
                              WHERE PTGD.enabled > 0 AND
                                    LP.processor_name = _processorName AND
                                    PTGD.tool_name <> 'Results_Transfer'            -- Candidate Result_Transfer steps were found above
                            ) TP
                   ON TP.tool_name = JS.tool
            WHERE (TP.cpus_available >= CASE WHEN JS.state = 9 Or _remoteInfoID > 1 Then -50 ELSE TP.cpu_load END) AND
                  J.priority <= TP.max_job_priority AND
                  (CURRENT_TIMESTAMP > JS.Next_Try Or _infoLevel > 0) AND
                  (JS.state In (2, 11) OR _remoteInfoID > 1 And JS.state = 9) AND
                  TP.memory_available >= JS.memory_usage_mb AND
                  NOT (tool = 'Results_Transfer' AND J.Archive_Busy = 1) AND
                  NOT EXISTS (SELECT * FROM sw.t_local_processor_job_step_exclusion JSE WHERE JSE.processor_id = TP.processor_id And JSE.step = JS.Step)
                    /*
                    ** To improve query speed remove the Case Statement above and uncomment the following series of tests
                    AND
                    (
                        -- Directly associated steps (Generic) ('Specific Association', aka Association_Type=2):
                        -- Type 2
                        (Tool_GP = 'Y' AND JS.job IN (SELECT job FROM sw.t_local_job_processors WHERE processor = Processor_Name)) OR

                        -- Generic processing steps ('Non-associated Generic', aka Association_Type=4):
                        -- Type 4
                        (Tool_GP = 'Y') OR

                        -- Directly associated steps ('Specific Association', aka Association_Type=2):
                        -- Type 2
                        (Tool_GP = 'N' AND JS.job IN (SELECT job FROM sw.t_local_job_processors WHERE processor = Processor_Name)) OR

                        -- Non-associated steps ('Non-associated', aka Association_Type=3):
                        -- Type 3
                        (Tool_GP = 'N' AND NOT JS.job IN (SELECT job FROM sw.t_local_job_processors WHERE processor <> Processor_Name AND general_processing = 0))
                    )
                    */
            ORDER BY
                Association_Type,
                Tool_Priority,
                J.Priority,        -- Job_Priority
                CASE WHEN Tool = 'Results_Transfer' Then 10    -- Give Results_Transfer steps priority so that they run first and are grouped by job
                    ELSE 0
                END DESC,
                Job,
                Step
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        -- Comment this end statement out due to deprecating processor groups
        -- End If;     -- </GeneralProcessingMachine>

    End If;-- </UseMultiStep>

    ---------------------------------------------------
    -- Check for jobs with Association_Type 101
    ---------------------------------------------------
    --
    If _infoLevel > 1 Then
        RAISE INFO '%, RequestStepTaskXML: Check for jobs with Association_Type 101', public.timestamp_text_immutable(clock_timestamp());
    End If;

    If Exists (SELECT * FROM Tmp_CandidateJobSteps WHERE Association_Type = 101) Then
        _cpuLoadExceeded := 1;
    End If;

    ---------------------------------------------------
    -- Check for storage servers for which too many
    -- steps have recently started (and are still running)
    --
    -- As of January 2013, this is no longer a necessity because copying of large files now uses lock files
    ---------------------------------------------------
    --
    If _throttleByStartTime <> 0 Then
        If _infoLevel > 1 Then
            RAISE INFO '%, RequestStepTaskXML: Check for servers that need to be throttled', public.timestamp_text_immutable(clock_timestamp());
        End If;

        -- The following query counts the number of job steps that recently started,
        -- grouping by storage server, and only examining steps numbers <= _maxStepNumToThrottle

        -- If _throttleAllStepTools is 0, it excludes Sequest and Results_Transfer steps
        -- It then looks for storage servers where too many steps have recently started (count >= _maxSimultaneousJobCount)
        -- We then link those results into Tmp_CandidateJobSteps via Storage_Server
        -- If any matches are found, Association_Type is updated to 104 so that the given candidate(s) will be excluded
        --
        UPDATE Tmp_CandidateJobSteps
        SET Association_Type = 104
        FROM Tmp_CandidateJobSteps CJS

        /********************************************************************************
        ** This UPDATE query includes the target table name in the FROM clause
        ** The WHERE clause needs to have a self join to the target table, for example:
        **   UPDATE Tmp_CandidateJobSteps
        **   SET ...
        **   FROM source
        **   WHERE source.id = Tmp_CandidateJobSteps.id;
        ********************************************************************************/

                               ToDo: Fix this query

            INNER JOIN ( -- Look for Storage Servers with too many recently started tasks
                        SELECT Storage_Server
                        FROM (  -- Look for running steps that started within the last _holdoffWindow minutes
                                -- Group by storage server
                                -- Only examine steps <= _maxStepNumToThrottle
                                SELECT sw.t_jobs.storage_server,
                                        COUNT(*) AS Running_Steps_Recently_Started
                                FROM sw.t_job_steps JS
                                    INNER JOIN sw.t_jobs
                                        ON JS.job = sw.t_jobs.job
                                WHERE JS.start >= CURRENT_TIMESTAMP - make_interval(mins => _holdoffWindowMinutes) AND
                                      JS.step <= _maxStepNumToThrottle AND
                                      JS.state = 4
                                GROUP BY sw.t_jobs.storage_server
                            ) LookupQ
                        WHERE (Running_Steps_Recently_Started >= _maxSimultaneousJobCount)
                        ) ServerQ
            ON ServerQ.storage_server = CJS.storage_server
        WHERE CJS.step <= _maxStepNumToThrottle AND
              (NOT tool IN ('Sequest', 'Results_Transfer') OR _throttleAllStepTools > 0)
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    End If;

    ---------------------------------------------------
    -- Look for any active job steps running on the same machine as this manager
    -- Exclude any jobs in Tmp_CandidateJobSteps that correspond to a dataset
    -- that has a job step that started recently on this machine
    ---------------------------------------------------
    --
    UPDATE Tmp_CandidateJobSteps
    SET Association_Type = 109
    FROM Tmp_CandidateJobSteps CJS

    /********************************************************************************
    ** This UPDATE query includes the target table name in the FROM clause
    ** The WHERE clause needs to have a self join to the target table, for example:
    **   UPDATE Tmp_CandidateJobSteps
    **   SET ...
    **   FROM source
    **   WHERE source.id = Tmp_CandidateJobSteps.id;
    ********************************************************************************/

                           ToDo: Fix this query

         INNER JOIN ( SELECT J.dataset_id,
                             LP.machine
                      FROM sw.t_job_steps JS
                           INNER JOIN sw.t_jobs J
                             ON JS.job = J.job
                           INNER JOIN sw.t_local_processors LP
                             ON JS.processor = LP.processor_name
                      WHERE JS.state = 4 AND
                            JS.start >= CURRENT_TIMESTAMP - INTERVAL '10 minutes'
                     ) RecentStartQ
           ON CJS.dataset_id = RecentStartQ.dataset_id And
              CJS.machine = RecentStartQ.machine
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    ---------------------------------------------------
    -- If _infoLevel = 0, remove candidates with non-viable association types
    -- otherwise keep everything
    ---------------------------------------------------
    --

    -- Assure that any jobs with a Next_Try before now have an association type over 10
    --
    UPDATE Tmp_CandidateJobSteps
    SET Association_Type = 20
    WHERE Association_Type < _associationTypeIgnoreThreshold And Next_Try > CURRENT_TIMESTAMP
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _infoLevel = 0 Then
        DELETE FROM Tmp_CandidateJobSteps
        WHERE Association_Type > _associationTypeIgnoreThreshold
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
    Else
        -- See if any jobs have Association_Type 99
        -- They are assigned to specific processors, but not to this processor
        If Exists (SELECT * FROM Tmp_CandidateJobSteps WHERE Association_Type = 99) Then
            -- Update the state to 103 for jobs associated with another processor, but not this processor
            UPDATE Tmp_CandidateJobSteps
            SET Association_Type = 103,
                Alternate_Specific_Processor = LJP.Alternate_Processor +
                         CASE WHEN Alternate_Processor_Count > 1
                                               THEN ' and others'
                                               ELSE ''
                                         End If;
            FROM Tmp_CandidateJobSteps CJS

            /********************************************************************************
            ** This UPDATE query includes the target table name in the FROM clause
            ** The WHERE clause needs to have a self join to the target table, for example:
            **   UPDATE Tmp_CandidateJobSteps
            **   SET ...
            **   FROM source
            **   WHERE source.id = Tmp_CandidateJobSteps.id;
            ********************************************************************************/

                                   ToDo: Fix this query

                 INNER JOIN ( SELECT job,
                                     MIN(processor) AS Alternate_Processor,
                                     COUNT(*) AS Alternate_Processor_Count
                              FROM sw.t_local_job_processors
                              WHERE processor <> _processorName
                              GROUP BY job
                            ) LJP
                   ON CJS.job = LJP.job
            WHERE CJS.Association_Type = 99 AND
                  NOT EXISTS ( SELECT job
                               FROM sw.t_local_job_processors
                               WHERE processor = _processorName )

            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        End If;

    End If;

    ---------------------------------------------------
    -- If no tools available, bail
    ---------------------------------------------------
    --
    If Not Exists (SELECT * FROM Tmp_CandidateJobSteps) Then
        _message := 'No candidates presently available';
        _returnCode := _jobNotAvailableErrorCode;

        DROP TABLE Tmp_CandidateJobSteps;
        RETURN;
    End If;

    If _infoLevel > 1 Then
        RAISE INFO '%, RequestStepTaskXML: Start transaction', public.timestamp_text_immutable(clock_timestamp());
    End If;

    BEGIN

        ---------------------------------------------------
        -- Get best step candidate in order of preference:
        --   Assignment priority (prefer directly associated jobs to general pool)
        --   Job-Tool priority
        --   Overall job priority
        --   Later steps over earlier steps
        --   Job number
        ---------------------------------------------------
        --

        -- This is set to 1 if the assigned job had state 9 and thus the manager is checking the status of a job step already running remotely

        SELECT JS.job,
               JS.step,
               CJS.Machine,
               CASE WHEN JS.state = 9 THEN 1 ELSE 0 END
        INTO _job, _step, _machine, _jobIsRunningRemote
        FROM
            sw.t_job_steps JS INNER JOIN
            Tmp_CandidateJobSteps CJS ON CJS.job = JS.job AND CJS.step = JS.step
        WHERE JS.state IN (2, 9, 11) And CJS.Association_Type <= _associationTypeIgnoreThreshold
        ORDER BY Seq
        LIMIT 1;

        If FOUND Then
            _jobAssigned := true;
        End If;

        _jobIsRunningRemote := Coalesce(_jobIsRunningRemote, 0);

        ---------------------------------------------------
        -- If a job step was found (_job <> 0) and if _infoLevel is 0,
        -- update the step state to Running
        ---------------------------------------------------
        --
        If _jobAssigned AND _infoLevel = 0 Then
        --<e>
            /* Declare _debugMsg text;
                _debugMsg := format('Assigned job %s, step %s; remoteInfoID=%s, jobIsRunningRemote=%s, setting Remote_Start to %s'
                                    _job, _step, _remoteInfoId, _jobIsRunningRemote,
                                    CASE WHEN _remoteInfoId > 1 AND _jobIsRunningRemote = 0 THEN Cast(CURRENT_TIMESTAMP as text)
                                         WHEN _remoteInfoId > 1 AND _jobIsRunningRemote = 1 THEN 'existing Remote_Start value'
                                         ELSE 'Null'
                                    END
                                    );

                Call public.post_log_entry ('Debug', _debugMsg, 'Request_Step_Task_XML', 'sw');
            */

            UPDATE sw.t_job_steps
            SET
                state = 4,
                processor = _processorName,
                start = CURRENT_TIMESTAMP,
                finish = Null,
                actual_cpu_load = CASE WHEN _remoteInfoId > 1 THEN 0 ELSE cpu_load END,
                next_try =        CASE WHEN _remoteInfoId > 1 AND _jobIsRunningRemote = 1 THEN next_try
                                       ELSE CURRENT_TIMESTAMP + INTERVAL '30 seconds'
                                  END,
                Remote_Info_ID =  CASE WHEN _remoteInfoID <= 1 THEN 1 ELSE _remoteInfoID END,
                Retry_Count =     CASE WHEN _remoteInfoId > 1 AND _jobIsRunningRemote = 1 THEN Retry_Count
                                  ELSE 0
                                  END,
                Remote_Start =    CASE WHEN _remoteInfoId > 1 AND _jobIsRunningRemote = 0 THEN CURRENT_TIMESTAMP
                                       WHEN _remoteInfoId > 1 AND _jobIsRunningRemote = 1 THEN Remote_Start
                                       ELSE NULL
                                  END,
                Remote_Finish =   CASE WHEN _remoteInfoId > 1 AND _jobIsRunningRemote = 0 THEN Null
                                       WHEN _remoteInfoId > 1 AND _jobIsRunningRemote = 1 THEN Remote_Finish
                                       ELSE NULL
                                  END,
                Remote_Progress = CASE WHEN _remoteInfoId > 1 AND _jobIsRunningRemote = 0 THEN 0
                                       WHEN _remoteInfoId > 1 AND _jobIsRunningRemote = 1 THEN Remote_Progress
                                       ELSE NULL
                                  END,
                Completion_Code = 0,
                Completion_Message = CASE WHEN Coalesce(Completion_Code, 0) > 0 THEN '' ELSE Null END,
                Evaluation_Code =    CASE WHEN Evaluation_Code Is Null THEN Null ELSE 0 END,
                Evaluation_Message = CASE WHEN Evaluation_Code Is Null THEN Null ELSE '' END
            WHERE Job = _job AND
                  Step = _step

        End If;
    END;

    COMMIT;

    If _infoLevel > 1 Then
        RAISE INFO '%, RequestStepTaskXML: Transaction committed', public.timestamp_text_immutable(clock_timestamp());
    End If;

    If _jobAssigned AND _infoLevel = 0 And _remoteInfoID <= 1 Then
    --<f>
        ---------------------------------------------------
        -- Update CPU loading for this processor's machine
        ---------------------------------------------------
        --
        UPDATE sw.t_machines
        SET cpus_available = total_cpus - CPUQ.CPUs_Busy
        FROM sw.t_machines Target

        /********************************************************************************
        ** This UPDATE query includes the target table name in the FROM clause
        ** The WHERE clause needs to have a self join to the target table, for example:
        **   UPDATE sw.t_machines
        **   SET ...
        **   FROM source
        **   WHERE source.id = sw.t_machines.id;
        ********************************************************************************/

                               ToDo: Fix this query

             INNER JOIN ( SELECT LP.Machine,
                                 SUM(CASE
                                         WHEN _jobIsRunningRemote > 0 AND
                                              JS.Step = _step THEN 0
                                         WHEN ST.Uses_All_Cores > 0 AND
                                              JS.Actual_CPU_Load = JS.CPU_Load THEN Coalesce(M.Total_CPUs, JS.CPU_Load)
                                         ELSE JS.Actual_CPU_Load
                                     End If;) AS CPUs_Busy
                          FROM sw.t_job_steps JS
                               INNER JOIN sw.t_local_processors LP
                                 ON JS.processor = LP.processor_name
                               INNER JOIN sw.t_step_tools ST
                                 ON ST.step_tool = JS.tool
                               INNER JOIN sw.t_machines M
                                 ON LP.machine = M.machine
                          WHERE LP.machine = _machine AND
                                JS.state = 4
                          GROUP BY LP.machine
                      ) CPUQ
               ON CPUQ.machine = Target.machine
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        COMMIT;

    End If; --<f>

    If _jobAssigned Then

        If _infoLevel = 0 And _jobIsRunningRemote = 0 Then
            ---------------------------------------------------
            -- Add entry to sw.t_job_step_processing_log
            -- However, skip this step if checking the status of a remote job
            ---------------------------------------------------

            INSERT INTO sw.t_job_step_processing_log (job, step, processor, Remote_Info_ID)
            VALUES (_job, _step, _processorName, _remoteInfoID)
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;
        End If;

        If _infoLevel > 1 Then
            RAISE INFO '%, RequestStepTaskXML: Call get_job_step_params_xml', public.timestamp_text_immutable(clock_timestamp());
        End If;

        ---------------------------------------------------
        -- Job was assigned; return parameters in XML
        ---------------------------------------------------
        --
        Call sw.get_job_step_params_xml (
                                _job,
                                _step,
                                _parameters output,
                                _message => _message,
                                _jobIsRunningRemote => _jobIsRunningRemote,
                                _debugMode => CASE _infoLevel WHEN > 0 THEN true ELSE false END);

        If _infoLevel <> 0 And char_length(_message) = 0 Then
            _message := 'Job ' || _job::text || ', Step ' || _step::text || ' would be assigned to ' || _processorName;
        End If;
    Else
        ---------------------------------------------------
        -- No job step found; update _myError and _message
        ---------------------------------------------------
        --
        _returnCode := _jobNotAvailableErrorCode;
        _message := 'No available jobs';

        If _cpuLoadExceeded > 0 Then
            _message := _message || ' (note: one or more step tools would exceed the available CPU load)';
        End If;
    End If;

    ---------------------------------------------------
    -- Dump candidate list if _infoLevel is non-zero
    ---------------------------------------------------
    --
    If _infoLevel > 0 Then
        If _infoLevel > 1 Then
            RAISE INFO '%, RequestStepTaskXML: Preview results', public.timestamp_text_immutable(clock_timestamp());
        End If;

        -- Preview the next _jobCountToPreview available jobs

        -- ToDo: Update this to use RAISE INFO

        SELECT CJS.Seq,
               CASE CJS.Association_Type
                   WHEN 1 Then   'Exclusive Association'
                   WHEN 2 Then   'Specific Association'
                   WHEN 3 THEN   'Non-associated'
                   WHEN 4 THEN   'Non-associated Generic'
                   WHEN 5 THEN   'Results_Transfer task (specific to this processor''s server)'
                   WHEN 6 THEN   'Results_Transfer task (null storage_server)'
                   WHEN 20 THEN  'Time earlier than next_try value'
                   WHEN 99 THEN  'Logic error: this should have been updated to 103'
                   WHEN 100 THEN 'Invalid: Not recognized'
                   WHEN 101 THEN 'Invalid: CPUs all busy'
                   WHEN 102 THEN 'Invalid: Archive in progress'
                   WHEN 103 THEN 'Invalid: job associated with ' || Alternate_Specific_Processor
                   WHEN 104 THEN 'Invalid: Storage Server has had ' || _maxSimultaneousJobCount::text || ' job steps start within the last ' || _holdoffWindowMinutes::text  || ' minutes'
                   WHEN 105 THEN 'Invalid: Not enough memory available (' || memory_usage_mb::text|| ' > ' || _availableMemoryMB::text || ', see sw.t_job_steps.memory_usage_mb)'
                   WHEN 106 THEN 'Invalid: Results_transfer task must run on ' || CJS.Storage_Server
                   WHEN 107 THEN 'Invalid: Remote server already running ' || _maxSimultaneousRunningRemoteSteps::text || ' job steps; limit reached'
                   WHEN 108 THEN 'Invalid: Manager not configured to access remote server for running job step'
                   WHEN 109 THEN 'Invalid: Another manager on this processor''s server recently started processing this dataset'
                   ELSE          'Warning: Unknown association type'
               END AS Association_Type,
               CJS.Tool_Priority,
               CJS.Job_Priority,
               CJS.job,
               CJS.step As Step,
               CJS.state,
               CJS.tool,
               J.dataset,
               JS.next_try,
               JS.remote_info_id,
               _remoteInfoID AS Proc_Remote_Info_ID,
               _processorName AS Processor
        FROM Tmp_CandidateJobSteps CJS
             INNER JOIN sw.t_jobs J
               ON CJS.job = J.job
             INNER JOIN sw.t_job_steps JS
               ON CJS.job = JS.job AND CJS.step = JS.step
        ORDER BY Seq
        LIMIT _jobCountToPreview;
    End If;

    DROP TABLE Tmp_CandidateJobSteps;
END
$$;

COMMENT ON PROCEDURE sw.request_step_task_xml IS 'RequestStepTaskXML';
