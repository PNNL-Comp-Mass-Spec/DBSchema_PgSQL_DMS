--
-- Name: request_step_task_xml(text, integer, text, text, text, integer, text, text, integer, boolean, boolean, integer, boolean, boolean); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.request_step_task_xml(IN _processorname text, INOUT _job integer DEFAULT 0, INOUT _parameters text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infolevel integer DEFAULT 0, IN _analysismanagerversion text DEFAULT ''::text, IN _remoteinfo text DEFAULT ''::text, IN _jobcounttopreview integer DEFAULT 10, IN _usebigbangquery boolean DEFAULT true, IN _throttlebystarttime boolean DEFAULT false, IN _maxstepnumtothrottle integer DEFAULT 10, IN _throttleallsteptools boolean DEFAULT false, IN _logspusage boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Looks for analysis job step that is appropriate for the given Analysis manager
**      If found, step is assigned to caller
**
**      Job assignment is based on:
**        Assignment type:
**          Exclusively associated steps ('Exclusive Association', aka Association_Type=1):
**          Directly associated steps ('Specific Association', aka Association_Type=2):
**          Directly associated steps (Generic) ('Specific Association', aka Association_Type=2):
**          Non-associated steps ('Non-associated', aka Association_Type=3):
**          Generic processing steps ('Non-associated Generic', aka Association_Type=4):
**          No processing load available on machine, aka Association_Type=101 (disqualified)
**          Transfer tool steps for jobs that are in the midst of an archive operation, aka Association_Type=102 (disqualified)
**          Specifically assigned to alternate processor, aka Association_Type=103 (disqualified)
**          Too many recently started job steps for the given tool, aka Association_Type=104 (disqualified)
**        Job-Tool priority
**        Job priority
**        Job number
**        Step Number
**        Max_Job_Priority for the step tool associated with a manager
**        Next_Try
**
**  Arguments:
**    _processorName            Name of the processor (aka manager) requesting a job
**    _job                      Output: Job number assigned; 0 if no job available
**    _parameters               Output: job step parameters (as XML)
**    _message                  Output message
**    _infoLevel                Set to 1 to preview the job that would be returned; if 2, show additional messages
**    _analysisManagerVersion   Used to update T_Local_Processors (ignored if an empty string)
**    _remoteInfo               Provided by managers that stage jobs to run remotely; used to assure that we don't stage too many jobs at once and to assure that we only check remote progress using a manager that has the same remote info as a job step
**    _jobCountToPreview        The number of jobs to preview when _infoLevel >= 1
**    _useBigBangQuery          Ignored and always set to true by this procedure (When true, uses a single, large query to find candidate steps, which can be very expensive if there is a large number of active jobs (i.e. over 10,000 active jobs))
**    _throttleByStartTime      Set to true to limit the number of job steps that can start simultaneously on a given storage server (to avoid overloading the disk and network I/O on the server); this is no longer a necessity because copying of large files uses lock files (effective January 2013)
**    _maxStepNumToThrottle     Only used if _throttleByStartTime is true
**    _throttleAllStepTools     Only used if _throttleByStartTime is true; when false, will not throttle SEQUEST or Results_Transfer steps
**
**  Example usage:
**    Call sw.request_step_task_xml ('Monroe_Analysis', _infoLevel => 1, _jobCountToPreview => 5);
**    Call sw.request_step_task_xml ('Monroe_Analysis', _infoLevel => 1, _jobCountToPreview => 5, _throttleByStartTime => true, _maxStepNumToThrottle => 10);
**    Call sw.request_step_task_xml ('Monroe_Analysis', _infoLevel => 1, _jobCountToPreview => 5);
**    Call sw.request_step_task_xml ('Monroe_Analysis', _infoLevel => 1, _logSPUsage => true);
**    Call sw.request_step_task_xml ('Monroe_Analysis', _infoLevel => 0, _analysisManagerVersion => '2.4.8433.27230');
**
**  Auth:   grk
**  Date:   08/23/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          12/03/2008 grk - Included processor-tool priority in assignement logic
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
**          08/20/2010 mem - No longer ordering by step number Descending prior to job number; this caused problems choosing the next appropriate SEQUEST job since SEQUEST_DTARefinery jobs run SEQUEST as step 4 while normal SEQUEST jobs run SEQUEST as step 3
**                         - Sort order is now: Association_Type, Tool_Priority, Job Priority, Favor Results_Transfer steps, Job, Step
**          09/09/2010 mem - Bumped _maxStepNumToThrottle up to 10
**                         - Added parameter _throttleAllStepTools, defaulting to 0 (meaning we will not throttle SEQUEST or Results_Transfer steps)
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
**                           Pass _jobIsRunningRemote to Get_Job_Step_Params_XML
**          05/15/2017 mem - Consider MonitorRunningRemote when looking for candidate jobs
**          05/16/2017 mem - Do not update T_Job_Step_Processing_Log if checking the status of a remotely running job
**          05/18/2017 mem - Add parameter _remoteInfo
**          05/22/2017 mem - Limit assignment of RunningRemote jobs to managers with the same RemoteInfoID as the job
**          05/23/2017 mem - Update Remote_Start, Remote_Finish, and Remote_Progress
**          05/26/2017 mem - Treat state 9 (Running_Remote) as having a CPU_Load of 0
**          06/08/2017 mem - Remove use of column MonitorRunningRemote in T_Machines since _remoteInfo replaces it
**          06/16/2017 mem - Restrict access using verify_sp_authorized
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
**          06/09/2023 mem - Ported to PostgreSQL
**          06/11/2023 mem - Add missing variable _nameWithSchema
**          06/23/2023 mem - Add missing underscore to column Processor_ID
**          07/11/2023 mem - Use COUNT(step) and COUNT(processor) instead of COUNT(*)
**          08/08/2023 mem - Include the schema name when calling procedure get_remote_info_id
**          09/07/2023 mem - Align assignment statements
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _jobAssigned boolean := false;
    _xmlParameters xml;
    _updatedAvailableCpuCount boolean := false;
    _candidateJobStepsToRetrieve int := 15;
    _holdoffWindowMinutes int;
    _maxSimultaneousJobCount int;
    _remoteInfoID int := 0;
    _maxSimultaneousRunningRemoteSteps int := 0;
    _runningRemoteLimitReached int := 0;
    _jobNotAvailableErrorCode text := 'U5301';
    _machine text;
    _availableCPUs int;
    _availableMemoryMB int;
    _processorState char;
    _processorID int;
    _enabled int;
    _processToolGroup text;
    _processorDoesGP boolean := false;
    _stepsRunningRemotely int := 0;
    _processorGP int;
    _cpuLoadExceeded int := 0;
    _associationTypeIgnoreThreshold int := 10;
    _step int := 0;
    _jobIsRunningRemote int := 0;

    _toolInfo      record;
    _remoteJobInfo record;
    _jobInfo       record;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _infoData text;

    _currentLocation text := 'Start';
    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

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

    _holdoffWindowMinutes := 3               ; -- Typically 3
    _maxSimultaneousJobCount := 75           ; -- Increased from 10 to 75 on 4/25/2013
    _useBigBangQuery := true                 ; -- Always forced by this procedure to be true

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs; clear the outputs
        ---------------------------------------------------

        _processorName          := Trim(Coalesce(_processorName, ''));
        _job                    := 0;
        _parameters             := '';
        _infoLevel              := Coalesce(_infoLevel, 0);
        _analysisManagerVersion := Trim(Coalesce(_analysisManagerVersion, ''));
        _remoteInfo             := Trim(Coalesce(_remoteInfo, ''));
        _jobCountToPreview      := Coalesce(_jobCountToPreview, 10);

        If _jobCountToPreview <= 0 Then
            _jobCountToPreview := 10;
        End If;

        _useBigBangQuery        := Coalesce(_useBigBangQuery, true);
        _throttleByStartTime    := Coalesce(_throttleByStartTime, false);
        _maxStepNumToThrottle   := Coalesce(_maxStepNumToThrottle, 10);
        _throttleAllStepTools   := Coalesce(_throttleAllStepTools, false);

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

        If _infoLevel > 1 Then
            RAISE INFO '%, Request_Step_Task_XML: Starting; make sure this is a valid processor', public.timestamp_text_immutable(clock_timestamp());
        End If;

        _currentLocation := 'Query sw.t_local_processors';

        ---------------------------------------------------
        -- Make sure this is a valid processor (and capitalize it according to sw.t_local_processors)
        ---------------------------------------------------

        -- Prior to February 2015, in view v_get_pipeline_processors, gp_groups was computed using:
        -- 'SUM(CASE WHEN PGA.Available_For_General_Processing = 'Y' THEN 1 ELSE 0 END) AS GP_Groups'
        -- with PGA representing
        -- 'INNER JOIN dbo.T_Analysis_Job_Processor_Group PGA ON PGM.Group_ID = PGA.ID'
        --
        -- Since processor groups were deprecated in 2015, gp_groups is now computed as 'sum(1) AS GP_Groups'
        --
        -- The above information relates to the following query because, prior to May 2015,
        -- _processorDoesGP was computed using '_processorDoesGP = t_local_processors.gp_groups',
        -- since gp_groups keeps track of the number of groups that the processor is a member of
        -- and is updated by procedure sw.import_processors()
        --
        -- Since 2015, _processorDoesGP has always been true for all processors

        SELECT true,
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

            _message := format('Processor not defined in sw.t_local_processors: %s', _processorName);
            _returnCode := _jobNotAvailableErrorCode;

            INSERT INTO sw.t_sp_usage( posted_by,
                                       processor_id,
                                       calling_user )
            VALUES('Request_Step_Task_XML',
                   NULL,
                   format('%s (Invalid processor: %s)', session_user, _processorName));

            RETURN;
        End If;

        ---------------------------------------------------
        -- Update processor's request timestamp
        -- (to show when the processor was most recently active)
        ---------------------------------------------------

        If _infoLevel = 0 Then
            _currentLocation := 'Update sw.t_local_processors';

            UPDATE sw.t_local_processors
            SET latest_request = CURRENT_TIMESTAMP,
                manager_version = CASE WHEN char_length(_analysisManagerVersion) = 0
                                       THEN manager_version
                                       ELSE _analysisManagerVersion
                                  END
            WHERE processor_name = _processorName;

            If char_length(_analysisManagerVersion) = 0 Then
                RAISE WARNING 'Manager version is an empty string; updated latest_request in sw.t_local_processors but left manager_version unchanged';
            End If;

            If Not Coalesce(_logSPUsage, false) Then
                INSERT INTO sw.t_sp_usage ( posted_by,
                                            processor_id,
                                            calling_user )
                VALUES ('Request_Step_Task_XML', _processorID, session_user);
            End If;

        End If;

        ---------------------------------------------------
        -- Abort if not enabled in sw.t_local_processors
        ---------------------------------------------------

        If _processorState <> 'E' Then
            _message := format('Processor is not enabled in sw.t_local_processors: %s', _processorName);
            _returnCode := _jobNotAvailableErrorCode;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Make sure this processor's machine is in sw.t_machines
        ---------------------------------------------------

        If Not Exists (SELECT * FROM sw.t_machines Where machine = _machine) Then
            _message := format('Machine "%s" is not present in sw.t_machines (but is defined in sw.t_local_processors for processor "%s")', _machine, _processorName);
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
        End If;

        If _enabled <= 0 Then
            _message := format('Machine "%s" is in a disabled tool group; no tasks will be assigned to manager %s', _machine, _processorName);
            _returnCode := _jobNotAvailableErrorCode;
            RETURN;
        End If;

        If _infoLevel > 0 Then

            ---------------------------------------------------
            -- Get list of step tools currently assigned to processor
            ---------------------------------------------------

            CREATE TEMP TABLE Tmp_AvailableProcessorTools
            (
                Processor_Tool_Group text,
                Tool_Name text,
                CPU_Load int,
                Memory_Usage_MB int,
                Tool_Priority int,
                GP int,                    -- 1 when tool is designated as a "Generic Processing" tool, meaning it ignores processor groups
                Max_Job_Priority int,
                Exceeds_Available_CPU_Load int NOT NULL,
                Exceeds_Available_Memory int NOT NULL
            );

            _currentLocation := 'Populate Tmp_AvailableProcessorTools';

            INSERT INTO Tmp_AvailableProcessorTools (
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
                  PTGD.enabled > 0;

            -- Preview the tools for this processor (as defined in Tmp_AvailableProcessorTools, which we just populated)

            _currentLocation := 'Show the tools associated with this processor';

            RAISE INFO '';
            RAISE INFO 'Step tools associated with manager %', _processorName;

            _formatSpecifier := '%-45s %-25s %-8s %-15s %-13s %-16s %-10s %-14s %-15s %-16s %-26s %-24s %-27s';

            _infoHead := format(_formatSpecifier,
                                'Processor_Tool_Group',
                                'Tool_Name',
                                'CPU_Load',
                                'Memory_Usage_MB',
                                'Tool_Priority',
                                'Max_Job_Priority',
                                'Total_CPUs',
                                'CPUs_Available',
                                'Total_Memory_MB',
                                'Memory_Available',
                                'Exceeds_Available_CPU_Load',
                                'Exceeds_Available_Memory',
                                'Processor_Does_General_Proc'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '---------------------------------------------',
                                         '-------------------------',
                                         '--------',
                                         '---------------',
                                         '-------------',
                                         '----------------',
                                         '----------',
                                         '--------------',
                                         '---------------',
                                         '----------------',
                                         '--------------------------',
                                         '------------------------',
                                         '---------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _toolInfo IN
                SELECT PT.Processor_Tool_Group,
                       PT.Tool_Name,
                       PT.CPU_Load,
                       PT.Memory_Usage_MB,
                       PT.Tool_Priority,
                       PT.Max_Job_Priority,
                       MachineQ.Total_CPUs,
                       MachineQ.CPUs_Available,
                       MachineQ.Total_Memory_MB,
                       MachineQ.Memory_Available,
                       PT.Exceeds_Available_CPU_Load,
                       PT.Exceeds_Available_Memory,
                       CASE WHEN _processorDoesGP THEN 'Yes' ELSE 'No' END AS Processor_Does_General_Proc
                FROM Tmp_AvailableProcessorTools PT
                     CROSS JOIN ( SELECT M.total_cpus,
                                         M.cpus_available,
                                         M.total_memory_mb,
                                         M.memory_available
                                  FROM sw.t_local_processors LP
                                     INNER JOIN sw.t_machines M
                                       ON LP.machine = M.machine
                                  WHERE LP.processor_name = _processorName ) MachineQ
                ORDER BY PT.Tool_Name
            LOOP
                _infoData := format(_formatSpecifier,
                                    _toolInfo.Processor_Tool_Group,
                                    _toolInfo.Tool_Name,
                                    _toolInfo.CPU_Load,
                                    _toolInfo.Memory_Usage_MB,
                                    _toolInfo.Tool_Priority,
                                    _toolInfo.Max_Job_Priority,
                                    _toolInfo.Total_CPUs,
                                    _toolInfo.CPUs_Available,
                                    _toolInfo.Total_Memory_MB,
                                    _toolInfo.Memory_Available,
                                    _toolInfo.Exceeds_Available_CPU_Load,
                                    _toolInfo.Exceeds_Available_Memory,
                                    _toolInfo.Processor_Does_General_Proc
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            DROP TABLE Tmp_AvailableProcessorTools;

        End If;

        If _remoteInfo <> '' Then

            ---------------------------------------------------
            -- Get list of job steps that are currently RunningRemote
            -- on the remote server associated with this manager
            ---------------------------------------------------

            _remoteInfoID := sw.get_remote_info_id(_remoteInfo, _infoOnly => true);

            -- Note that _remoteInfoID=1 means the _remoteInfo is 'Unknown'

            If _remoteInfoID > 1 Then
                If _infoLevel > 0 Then
                    RAISE INFO '_remoteInfoID is % for %', _remoteInfoID, _remoteInfo;
                End If;

                SELECT COUNT(step)
                INTO _stepsRunningRemotely
                FROM sw.t_job_steps
                WHERE state IN (4, 9) AND remote_info_id = _remoteInfoID;

                If _stepsRunningRemotely > 0 Then
                    SELECT max_running_job_steps
                    INTO _maxSimultaneousRunningRemoteSteps
                    FROM sw.t_remote_info
                    WHERE remote_info_id = _remoteInfoID;

                    If _stepsRunningRemotely >= Coalesce(_maxSimultaneousRunningRemoteSteps, 1) Then
                        _runningRemoteLimitReached := 1;
                    End If;
                End If;

                If _infoLevel > 0 Then

                    -- Preview RunningRemote tasks on the remote host associated with this manager

                    _currentLocation := 'Show running remote tasks';

                    RAISE INFO 'Running remote tasks on the remote host associated with manager %', _processorName;

                    _formatSpecifier := '%-14s %-65s %-15s %-9s %-21s %-11s %-10s %-5s %-20s %-20s %-80s';

                    _infoHead := format(_formatSpecifier,
                                        'Remote_Info_ID',
                                        'Remote_Info',
                                        'Most_Recent_Job',
                                        'Last_Used',
                                        'Max_Running_Job_Steps',
                                        'Job',
                                        'State_Name',
                                        'State',
                                        'Start',
                                        'Finish',
                                        'Dataset'
                                       );

                    _infoHeadSeparator := format(_formatSpecifier,
                                                 '--------------',
                                                 '-----------------------------------------------------------------',
                                                 '---------------',
                                                 '---------',
                                                 '---------------------',
                                                 '-----------',
                                                 '----------',
                                                 '-----',
                                                 '--------------------',
                                                 '--------------------',
                                                 '--------------------------------------------------------------------------------'
                                                );

                    RAISE INFO '%', _infoHead;
                    RAISE INFO '%', _infoHeadSeparator;

                    FOR _remoteJobInfo IN
                        SELECT RemoteInfo.Remote_Info_ID,
                               Left(RemoteInfo.Remote_Info, 65),
                               RemoteInfo.Most_Recent_Job,
                               RemoteInfo.Last_Used,
                               RemoteInfo.Max_Running_Job_Steps,
                               JS.Job,
                               JS.StateName,
                               JS.State,
                               JS.Start,
                               JS.Finish,
                               JS.Dataset
                        FROM sw.t_remote_info RemoteInfo
                             INNER JOIN V_Job_Steps JS
                               ON RemoteInfo.remote_info_id = JS.remote_info_id
                        WHERE RemoteInfo.remote_info_id = _remoteInfoID AND
                              JS.State IN (4, 9)
                        ORDER BY Job, Step
                    LOOP
                        _infoData := format(_formatSpecifier,
                                            _remoteJobInfo.Remote_Info_ID,
                                            _remoteJobInfo.Remote_Info,
                                            _remoteJobInfo.Most_Recent_Job,
                                            _remoteJobInfo.Last_Used,
                                            _remoteJobInfo.Max_Running_Job_Steps,
                                            _remoteJobInfo.Job,
                                            _remoteJobInfo.StateName,
                                            _remoteJobInfo.State,
                                            _remoteJobInfo.Start,
                                            _remoteJobInfo.Finish,
                                            _remoteJobInfo.Dataset
                                           );

                        RAISE INFO '%', _infoData;
                    END LOOP;

                End If;

            Else
                If _infoLevel > 0 Then
                    RAISE INFO 'Could not resolve % to Remote_Info_ID', _remoteInfo;
                End If;
            End If;

        End If;

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
            Association_Type int NOT NULL,          -- Valid types are: 1=Exclusive Association, 2=Specific Association, 3=Non-associated, 4=Non-Associated Generic, etc.
            Machine text,
            Alternate_Specific_Processor text,      -- This field is only used if _infoLevel is non-zero and if jobs exist with Association_Type 103
            Storage_Server text,
            Dataset_ID int,
            Next_Try timestamp
        );

        If _infoLevel > 1 Then
            RAISE INFO '%, Request_Step_Task_XML: Populate Tmp_CandidateJobSteps', public.timestamp_text_immutable(clock_timestamp());
        End If;

        ---------------------------------------------------
        -- Look for available Results_Transfer steps
        -- Only assign a Results_Transfer step to a manager running on the job's storage server
        ---------------------------------------------------

        If Exists (SELECT *
                   FROM sw.t_local_processors LP
                        INNER JOIN sw.t_machines M
                          ON LP.machine = M.machine
                        INNER JOIN sw.t_processor_tool_group_details PTGD
                          ON LP.proc_tool_mgr_id = PTGD.mgr_id AND
                             M.proc_tool_group_id = PTGD.group_id
                   WHERE LP.Processor_Name = _processorName And
                         PTGD.enabled > 0 And
                         PTGD.tool_name = 'Results_Transfer') Then

            _currentLocation := 'Populate Tmp_CandidateJobSteps: Look for Results_Transfer candidates';

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
            SELECT
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
                        -- The archive_busy flag in sw.t_jobs is updated by Sync_Job_Info
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
            LIMIT _candidateJobStepsToRetrieve;

            If Not FOUND And _infoLevel <> 0 Then
                _currentLocation := 'Populate Tmp_CandidateJobSteps: Look for Results_Transfer tasks that need to be handled by another storage server';

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
                SELECT
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
                LIMIT _candidateJobStepsToRetrieve;
            End If;

        End If;

        ---------------------------------------------------
        -- Get list of viable job step assignments organized
        -- by processor in order of assignment priority
        ---------------------------------------------------

        If _useBigBangQuery Or _infoLevel <> 0 Then

            _currentLocation := 'Populate Tmp_CandidateJobSteps using all-in-one query';

            ------------------------------------------------------------------------------------
            -- Big-bang query
            -- This query can be very expensive if there is a large number of active jobs
            -- and SQL Server gets confused about which indices to use (more likely on SQL Server 2005)
            --
            -- This can lead to huge "lock request/sec" rates, particularly when there are
            -- thouands of jobs in sw.t_jobs with state <> 8 and steps with state IN (2, 9)
            ------------------------------------------------------------------------------------

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
            SELECT
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

                    ---------------------------------------------------
                    -- Deprecated in May 2015:
                    --
                    -- WHEN (Processor_GP > 0 AND Tool_GP = 'Y' AND JS.job IN (SELECT job FROM sw.t_local_job_processors WHERE processor = Processor_Name))
                    --     -- Directly associated steps (Generic) ('Specific Association', aka Association_Type=2):
                    --     THEN 2
                    -- WHEN (Processor_GP > 0 AND Tool_GP = 'Y')
                    --     -- Generic processing steps ('Non-associated Generic', aka Association_Type=4):
                    --     THEN 4
                    -- WHEN (Processor_GP > 0 AND Tool_GP = 'N' AND JS.job IN (SELECT job FROM sw.t_local_job_processors WHERE processor = Processor_Name))
                    --     -- Directly associated steps ('Specific Association', aka Association_Type=2):
                    --     THEN 2
                    -- WHEN (Processor_GP > 0 AND Tool_GP = 'N' AND NOT JS.job IN (SELECT job FROM sw.t_local_job_processors WHERE processor <> Processor_Name AND general_processing = 0))
                    --     -- Non-associated steps ('Non-associated', aka Association_Type=3):
                    --     THEN 3
                    -- WHEN (Processor_GP = 0 AND Tool_GP = 'N' AND JS.job IN (SELECT job FROM sw.t_local_job_processors WHERE processor = Processor_Name AND general_processing = 0))
                    --     -- Exclusively associated steps ('Exclusive Association', aka Association_Type=1):
                    --     THEN 1
                    ---------------------------------------------------

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
                                     LP.Processor_ID,
                                     PTGD.Tool_Name,
                                     PTGD.priority AS Tool_Priority,
                                     PTGD.Max_Job_Priority,

                                     ---------------------------------------------------
                                     -- Deprecated in May 2015:
                                     --
                                     -- LP.gp_groups AS Processor_GP,
                                     -- ST.available_for_general_processing AS Tool_GP,
                                     ---------------------------------------------------

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
            LIMIT _candidateJobStepsToRetrieve;

        Else
            _currentLocation := 'Populate Tmp_CandidateJobSteps using multi-step query';

            ---------------------------------------------------
            -- Deprecated in May 2015:
            --
            -- Lookup the GP_Groups count for this processor
            --
            -- SELECT LP.gp_groups
            -- INTO _processorGP
            -- FROM sw.t_machines M
            --     INNER JOIN sw.t_local_processors LP
            --         ON M.machine = LP.machine
            --     INNER JOIN sw.t_processor_tool_group_details PTGD
            --         ON LP.proc_tool_mgr_id = PTGD.mgr_id AND
            --         M.proc_tool_group_id = PTGD.group_id
            --     INNER JOIN sw.t_step_tools ST
            --         ON PTGD.tool_name = ST.step_tool
            -- WHERE PTGD.enabled > 0 AND
            --       LP.processor_name = _processorName;
            --
            -- _processorGP := Coalesce(_processorGP, 0);
            --
            -- If _processorGP = 0 Then
            --
            --     -- Processor does not do general processing
            --     --
            --     INSERT INTO Tmp_CandidateJobSteps (
            --         job,
            --         step,
            --         state,
            --         Job_Priority,
            --         tool,
            --         Tool_Priority,
            --         storage_server,
            --         dataset_id,
            --         machine,
            --         Association_Type,
            --         next_try
            --     )
            --     SELECT
            --         JS.job,
            --         step,
            --         state,
            --         J.priority AS Job_Priority,
            --         tool,
            --         Tool_Priority,
            --         J.storage_server,
            --         J.dataset_id,
            --         TP.machine,
            --         1 AS Association_Type,
            --         JS.next_try
            --     FROM ( SELECT TJ.job,
            --                   TJ.priority,        -- Job_Priority
            --                   TJ.archive_busy,
            --                   TJ.storage_server,
            --                   TJ.dataset_id
            --            FROM sw.t_jobs TJ
            --        WHERE TJ.state <> 8 ) J
            --        INNER JOIN sw.t_job_steps JS
            --            ON J.job = JS.job
            --          INNER JOIN (    -- Viable processors/step tools combinations (with CPU loading and processor group information)
            --                       SELECT LP.processor_name,
            --                              LP.processor_id AS Processor_ID,
            --                              PTGD.tool_name,
            --                              PTGD.priority AS Tool_Priority,
            --                              LP.gp_groups AS Processor_GP,
            --                              ST.available_for_general_processing AS Tool_GP,
            --                              M.cpus_available,
            --                              ST.cpu_load,
            --                              M.memory_available,
            --                              M.machine
            --                       FROM sw.t_machines M
            --                            INNER JOIN sw.t_local_processors LP
            --                              ON M.machine = LP.machine
            --                            INNER JOIN sw.t_processor_tool_group_details PTGD
            --                              ON LP.proc_tool_mgr_id = PTGD.mgr_id AND
            --                                 M.proc_tool_group_id = PTGD.group_id
            --                            INNER JOIN sw.t_step_tools ST
            --                              ON PTGD.tool_name = ST.step_tool
            --                       WHERE PTGD.enabled > 0 AND
            --         LP.processor_name = _processorName AND
            --         PTGD.tool_name <> 'Results_Transfer'        -- Candidate Result_Transfer steps were found above
            --                     ) TP
            --            ON TP.tool_name = JS.tool
            --     WHERE (TP.cpus_available >= CASE WHEN JS.state = 9 THEN 0 ELSE TP.cpu_load END) AND
            --           CURRENT_TIMESTAMP > JS.next_try AND
            --           (JS.state In (2, 11) OR JS.state = 9 AND JS.remote_info_id = _remoteInfoId) AND
            --           TP.memory_available >= JS.memory_usage_mb AND
            --           NOT (tool = 'Results_Transfer' AND J.archive_busy = 1) AND
            --           NOT EXISTS (SELECT * FROM sw.t_local_processor_job_step_exclusion JSE WHERE JSE.processor_id = TP.processor_id And JSE.step = JS.step) AND
            --           -- Exclusively associated steps ('Exclusive Association', aka Association_Type=1):
            --           -- (Processor_GP = 0 AND Tool_GP = 'N' AND JS.job IN (SELECT job FROM sw.t_local_job_processors WHERE processor = Processor_Name AND general_processing = 0))
            --     ORDER BY
            --         Association_Type,
            --         Tool_Priority,
            --         J.Priority,    -- Job_Priority
            --         CASE WHEN tool = 'Results_Transfer' Then 10    -- Give Results_Transfer steps priority so that they run first and are grouped by Job
            --             ELSE 0
            --         End If; DESC,
            --         Job,
            --         Step
            --     LIMIT _candidateJobStepsToRetrieve;
            --
            -- Else
            ---------------------------------------------------

            -- Processor does do general processing
            --
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
            SELECT
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
                                     LP.Processor_ID,
                                     PTGD.Tool_Name,
                                     PTGD.priority AS Tool_Priority,
                                     PTGD.Max_Job_Priority,

                                     ---------------------------------------------------
                                     -- Deprecated in May 2015:
                                     --
                                     -- ST.available_for_general_processing AS Tool_GP,
                                     ---------------------------------------------------

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

                    -- To improve query speed remove the Case Statement above and uncomment the following series of tests
                    -- AND
                    -- (
                    --     -- Directly associated steps (Generic) ('Specific Association', aka Association_Type=2):
                    --     -- Type 2
                    --     (Tool_GP = 'Y' AND JS.job IN (SELECT job FROM sw.t_local_job_processors WHERE processor = Processor_Name)) OR
                    --
                    --     -- Generic processing steps ('Non-associated Generic', aka Association_Type=4):
                    --     -- Type 4
                    --     (Tool_GP = 'Y') OR
                    --
                    --     -- Directly associated steps ('Specific Association', aka Association_Type=2):
                    --     -- Type 2
                    --     (Tool_GP = 'N' AND JS.job IN (SELECT job FROM sw.t_local_job_processors WHERE processor = Processor_Name)) OR
                    --
                    --     -- Non-associated steps ('Non-associated', aka Association_Type=3):
                    --     -- Type 3
                    --     (Tool_GP = 'N' AND NOT JS.job IN (SELECT job FROM sw.t_local_job_processors WHERE processor <> Processor_Name AND general_processing = 0))
                    -- )

            ORDER BY
                Association_Type,
                Tool_Priority,
                J.Priority,        -- Job_Priority
                CASE WHEN Tool = 'Results_Transfer' Then 10    -- Give Results_Transfer steps priority so that they run first and are grouped by job
                    ELSE 0
                END DESC,
                Job,
                Step
            LIMIT _candidateJobStepsToRetrieve;

            -- The following line is commented out since processor groups were deprecated:
            -- End If;

        End If;

        ---------------------------------------------------
        -- Check for jobs with Association_Type 101
        ---------------------------------------------------

        If _infoLevel > 1 Then
            RAISE INFO '%, Request_Step_Task_XML: Check for jobs with Association_Type 101', public.timestamp_text_immutable(clock_timestamp());
        End If;

        If Exists (SELECT * FROM Tmp_CandidateJobSteps WHERE Association_Type = 101) Then
            _cpuLoadExceeded := 1;
        End If;

        ---------------------------------------------------
        -- Check for storage servers for which too many
        -- steps have recently started (and are still running)
        --
        -- As of January 2013, this is no longer a necessity because copying of large files uses lock files
        ---------------------------------------------------

        If _throttleByStartTime Then

            _currentLocation := 'Check for servers that need to be throttled';

            If _infoLevel > 1 Then
                RAISE INFO '%, Request_Step_Task_XML: Check for servers that need to be throttled', public.timestamp_text_immutable(clock_timestamp());
            End If;

            -- The following query counts the number of job steps that recently started,
            -- grouping by storage server, and only examining steps numbers <= _maxStepNumToThrottle

            -- If _throttleAllStepTools is false, it excludes SEQUEST and Results_Transfer steps
            -- It then looks for storage servers where too many steps have recently started (count >= _maxSimultaneousJobCount)
            -- We then link those results into Tmp_CandidateJobSteps via Storage_Server
            -- If any matches are found, Association_Type is updated to 104 so that the given candidate(s) will be excluded
            --
            UPDATE Tmp_CandidateJobSteps CJS
            SET Association_Type = 104
            FROM ( -- Look for Storage Servers with too many recently started tasks
                   SELECT Storage_Server
                   FROM (  -- Look for running steps that started within the last _holdoffWindow minutes
                           -- Group by storage server
                           -- Only examine steps <= _maxStepNumToThrottle
                           SELECT sw.t_jobs.storage_server,
                                   COUNT(JS.step) AS Running_Steps_Recently_Started
                           FROM sw.t_job_steps JS
                               INNER JOIN sw.t_jobs
                                   ON JS.job = sw.t_jobs.job
                           WHERE JS.start >= CURRENT_TIMESTAMP - make_interval(mins => _holdoffWindowMinutes) AND
                                 JS.step <= _maxStepNumToThrottle AND
                                 JS.state = 4
                           GROUP BY sw.t_jobs.storage_server
                       ) LookupQ
                   WHERE Running_Steps_Recently_Started >= _maxSimultaneousJobCount
                   ) ServerQ
            WHERE ServerQ.storage_server = CJS.storage_server AND
                  CJS.step <= _maxStepNumToThrottle AND
                  (NOT tool IN ('SEQUEST', 'Results_Transfer') OR _throttleAllStepTools);

        End If;

        ---------------------------------------------------
        -- Look for any active job steps running on the same machine as this manager
        -- Exclude any jobs in Tmp_CandidateJobSteps that correspond to a dataset
        -- that has a job step that started recently on this machine
        ---------------------------------------------------

        UPDATE Tmp_CandidateJobSteps CJS
        SET Association_Type = 109
        FROM ( SELECT J.dataset_id,
                                 LP.machine
                          FROM sw.t_job_steps JS
                               INNER JOIN sw.t_jobs J
                                 ON JS.job = J.job
                               INNER JOIN sw.t_local_processors LP
                                 ON JS.processor = LP.processor_name
                          WHERE JS.state = 4 AND
                                JS.start >= CURRENT_TIMESTAMP - INTERVAL '10 minutes'
                         ) RecentStartQ
        WHERE CJS.dataset_id = RecentStartQ.dataset_id AND
              CJS.machine = RecentStartQ.machine;

        ---------------------------------------------------
        -- If _infoLevel = 0, remove candidates with non-viable association types
        -- otherwise keep everything
        ---------------------------------------------------

        -- Assure that any jobs with a Next_Try before now have an association type over 10

        UPDATE Tmp_CandidateJobSteps
        SET Association_Type = 20
        WHERE Association_Type < _associationTypeIgnoreThreshold And Next_Try > CURRENT_TIMESTAMP;

        If _infoLevel = 0 Then
            DELETE FROM Tmp_CandidateJobSteps
            WHERE Association_Type > _associationTypeIgnoreThreshold;
        Else
            -- See if any jobs have Association_Type 99
            -- They are assigned to specific processors, but not to this processor
            If Exists (SELECT * FROM Tmp_CandidateJobSteps WHERE Association_Type = 99) Then
                -- Update the state to 103 for jobs associated with another processor, but not this processor
                UPDATE Tmp_CandidateJobSteps CJS
                SET Association_Type = 103,
                    Alternate_Specific_Processor = format('%s%s',
                                                          LJP.Alternate_Processor,
                                                          CASE WHEN Alternate_Processor_Count > 1
                                                               THEN ' and others'
                                                               ELSE ''
                                                          END)
                FROM ( SELECT job,
                              MIN(processor) AS Alternate_Processor,
                              COUNT(processor) AS Alternate_Processor_Count
                       FROM sw.t_local_job_processors
                       WHERE processor <> _processorName
                       GROUP BY job
                     ) LJP
                WHERE CJS.job = LJP.job AND
                      CJS.Association_Type = 99 AND
                      NOT EXISTS ( SELECT job
                                   FROM sw.t_local_job_processors
                                   WHERE processor = _processorName );
            End If;

        End If;

        ---------------------------------------------------
        -- If no tools available, bail
        ---------------------------------------------------

        If Not Exists (SELECT * FROM Tmp_CandidateJobSteps) Then
            _message := 'No candidates presently available';
            _returnCode := _jobNotAvailableErrorCode;

            DROP TABLE Tmp_CandidateJobSteps;
            RETURN;
        End If;

        If _infoLevel > 1 Then
            RAISE INFO '%, Request_Step_Task_XML: Start transaction', public.timestamp_text_immutable(clock_timestamp());
        End If;

        _currentLocation := 'Find the best candidate job step';

        ---------------------------------------------------
        -- Get best step candidate in order of preference:
        --   Assignment priority (prefer directly associated jobs to general pool)
        --   Job-Tool priority
        --   Overall job priority
        --   Later steps over earlier steps
        --   Job number
        ---------------------------------------------------

        -- _jobIsRunningRemote is set to 1 if the assigned job had state 9 and thus the manager is checking the status of a job step already running remotely

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

        If _jobAssigned And _infoLevel = 0 Then

            _currentLocation := 'Update State and Processor in sw.t_job_steps';

            -- Declare _debugMsg text;
            --  _debugMsg := format('Assigned job %s, step %s; remoteInfoID=%s, jobIsRunningRemote=%s, setting Remote_Start to %s'
            --                      _job, _step, _remoteInfoId, _jobIsRunningRemote,
            --                      CASE WHEN _remoteInfoId > 1 AND _jobIsRunningRemote = 0 THEN Cast(CURRENT_TIMESTAMP As text)
            --                           WHEN _remoteInfoId > 1 AND _jobIsRunningRemote = 1 THEN 'existing Remote_Start value'
            --                           ELSE 'Null'
            --                      END
            --                      );
            --
            --  CALL public.post_log_entry ('Debug', _debugMsg, 'Request_Step_Task_XML', 'sw');

            UPDATE sw.t_job_steps
            SET state = 4,
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
                  Step = _step;

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => _currentLocation, _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        If _infoLevel > 0 Then
            RAISE WARNING 'Exception: %', _message;
        End If;

        DROP TABLE IF EXISTS Tmp_AvailableProcessorTools;
        DROP TABLE IF EXISTS Tmp_CandidateJobSteps;

        RETURN;
    END;

    If _jobAssigned And _infoLevel = 0 Then
        _currentLocation := 'Commit since _jobAssigned is true';
        COMMIT;
    End If;

    BEGIN

        If _infoLevel > 1 Then
            RAISE INFO '%, Request_Step_Task_XML: Transaction committed', public.timestamp_text_immutable(clock_timestamp());
        End If;

        If _jobAssigned And _infoLevel = 0 And _remoteInfoID <= 1 Then

            _currentLocation := 'Update CPU loading for this processor''s machine';

            ---------------------------------------------------
            -- Update CPU loading for this processor's machine
            ---------------------------------------------------

            UPDATE sw.t_machines Target
            SET cpus_available = total_cpus - CPUQ.CPUs_Busy
            FROM ( SELECT LP.Machine,
                          SUM(CASE
                                  WHEN _jobIsRunningRemote > 0 AND
                                       JS.Step = _step THEN 0
                                  WHEN ST.Uses_All_Cores > 0 AND
                                       JS.Actual_CPU_Load = JS.CPU_Load THEN Coalesce(M.Total_CPUs, JS.CPU_Load)
                                  ELSE JS.Actual_CPU_Load
                              END) AS CPUs_Busy
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
            WHERE CPUQ.machine = Target.machine;

            _updatedAvailableCpuCount := true;
        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => _currentLocation, _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        If _infoLevel > 0 Then
            RAISE WARNING 'Exception: %', _message;
        End If;

        DROP TABLE IF EXISTS Tmp_CandidateJobSteps;

        RETURN;
    END;

    If _updatedAvailableCpuCount Then
        _currentLocation := 'Commit since t_machines was updated';
        COMMIT;
    End If;


    BEGIN
        If _jobAssigned Then

            _currentLocation := 'Update t_job_step_processing_log';

            If _infoLevel = 0 And _jobIsRunningRemote = 0 Then
                ---------------------------------------------------
                -- Add entry to sw.t_job_step_processing_log
                -- However, skip this step if checking the status of a remote job
                ---------------------------------------------------

                INSERT INTO sw.t_job_step_processing_log (job, step, processor, Remote_Info_ID)
                VALUES (_job, _step, _processorName, _remoteInfoID);
            End If;

            If _infoLevel > 1 Then
                RAISE INFO '%, Request_Step_Task_XML: Call sw.get_job_step_params_xml', public.timestamp_text_immutable(clock_timestamp());
            End If;

            _currentLocation := 'Call sw.get_job_step_params_xml() to obtain job parameters';

            ---------------------------------------------------
            -- Job was assigned; obtain XML job parameters
            ---------------------------------------------------

            _xmlParameters := sw.get_job_step_params_xml (
                                            _job,
                                            _step,
                                            _jobIsRunningRemote => _jobIsRunningRemote);

            _parameters := _xmlParameters::text;
        Else
            ---------------------------------------------------
            -- No job step found; update _returnCode and _message
            ---------------------------------------------------

            _returnCode := _jobNotAvailableErrorCode;
            _message := 'No available jobs';

            If _cpuLoadExceeded > 0 Then
                _message := format('%s (note: one or more step tools would exceed the available CPU load)', _message);
            End If;
        End If;

        ---------------------------------------------------
        -- Dump candidate list if _infoLevel is non-zero
        ---------------------------------------------------

        If _infoLevel > 0 Then
            _currentLocation := 'Preview list of candidate jobs';

            If _infoLevel > 1 Then
                RAISE INFO '%, Request_Step_Task_XML: Preview results', public.timestamp_text_immutable(clock_timestamp());
            End If;

            -- Preview the next _jobCountToPreview available jobs

            RAISE INFO '';

            If Exists (Select * From Tmp_CandidateJobSteps) Then

                _currentLocation := 'Show candidate job steps';

                RAISE INFO 'Candidate job steps for %', _processorName;

                _formatSpecifier := '%-10s %-5s %-20s %-6s %-95s %-14s %-14s %-20s %-80s %-15s %-20s';

                _currentLocation := 'Show candidate job steps: construct header';

                _infoHead := format(_formatSpecifier,
                                    'Job',
                                    'Step',
                                    'Tool',
                                    'Seq',
                                    'Association_Type',
                                    'Tool_Priority',
                                    'Job_Priority',
                                    'Next_Try',
                                    'Dataset',
                                    'Remote_Info_ID',
                                    'Proc_Remote_Info_ID'
                                   );

                _currentLocation := 'Show candidate job steps: construct separator';

                _infoHeadSeparator := format(_formatSpecifier,
                                             '----------',
                                             '-----',
                                             '--------------------',
                                             '------',
                                             '-----------------------------------------------------------------------------------------------',
                                             '--------------',
                                             '--------------',
                                             '--------------------',
                                             '--------------------------------------------------------------------------------',
                                             '---------------',
                                             '--------------------'
                                            );

                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _jobInfo IN
                    SELECT CJS.Job,
                           CJS.Step,
                           CJS.Tool,
                           CJS.Seq,
                           CASE CJS.Association_Type
                               WHEN   1 THEN        'Exclusive Association'
                               WHEN   2 THEN        'Specific Association'
                               WHEN   3 THEN        'Non-associated'
                               WHEN   4 THEN        'Non-associated Generic'
                               WHEN   5 THEN        'Results_Transfer task (specific to this processor''s server)'
                               WHEN   6 THEN        'Results_Transfer task (null storage_server)'
                               WHEN  20 THEN        'Time earlier than next_try value'
                               WHEN  99 THEN        'Logic error: this should have been updated to 103'
                               WHEN 100 THEN        'Invalid: Not recognized'
                               WHEN 101 THEN        'Invalid: CPUs all busy'
                               WHEN 102 THEN        'Invalid: Archive in progress'
                               WHEN 103 THEN format('Invalid: job associated with %s', CJS.Alternate_Specific_Processor)
                               WHEN 104 THEN format('Invalid: Storage Server has had %s job steps start within the last %s minutes', _maxSimultaneousJobCount, _holdoffWindowMinutes)
                               WHEN 105 THEN format('Invalid: Not enough memory available (%s > %s, see sw.t_job_steps.memory_usage_mb)', JS.memory_usage_mb, _availableMemoryMB)
                               WHEN 106 THEN format('Invalid: Results_transfer task must run on %s', CJS.Storage_Server)
                               WHEN 107 THEN format('Invalid: Remote server already running %s job steps; limit reached', _maxSimultaneousRunningRemoteSteps)
                               WHEN 108 THEN        'Invalid: Manager not configured to access remote server for running job step'
                               WHEN 109 THEN        'Invalid: Another manager on this processor''s server recently started processing this dataset'
                               ELSE                 'Warning: Unknown association type'
                           END AS Association_Type,
                           CJS.Tool_Priority,
                           CJS.Job_Priority,
                           JS.Next_Try,
                           J.Dataset,
                           JS.Remote_Info_ID
                    FROM Tmp_CandidateJobSteps CJS
                         INNER JOIN sw.t_jobs J
                           ON CJS.job = J.job
                         INNER JOIN sw.t_job_steps JS
                           ON CJS.job = JS.job AND CJS.step = JS.step
                    ORDER BY Seq
                    LIMIT _jobCountToPreview
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _jobInfo.Job,
                                        _jobInfo.Step,
                                        _jobInfo.Tool,
                                        _jobInfo.Seq,
                                        _jobInfo.Association_Type,
                                        _jobInfo.Tool_Priority,
                                        _jobInfo.Job_Priority,
                                        _jobInfo.Next_Try,
                                        _jobInfo.Dataset,
                                        _jobInfo.Remote_Info_ID,
                                        _remoteInfoID
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;
            Else
                RAISE INFO 'No candidate job steps found for %', _processorName;
            End If;

        End If;

        DROP TABLE Tmp_CandidateJobSteps;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => _currentLocation, _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        If _infoLevel > 0 Then
            RAISE WARNING 'Exception: %', _message;
        End If;

        DROP TABLE IF EXISTS Tmp_CandidateJobSteps;
    END;

END
$$;


ALTER PROCEDURE sw.request_step_task_xml(IN _processorname text, INOUT _job integer, INOUT _parameters text, INOUT _message text, INOUT _returncode text, IN _infolevel integer, IN _analysismanagerversion text, IN _remoteinfo text, IN _jobcounttopreview integer, IN _usebigbangquery boolean, IN _throttlebystarttime boolean, IN _maxstepnumtothrottle integer, IN _throttleallsteptools boolean, IN _logspusage boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE request_step_task_xml(IN _processorname text, INOUT _job integer, INOUT _parameters text, INOUT _message text, INOUT _returncode text, IN _infolevel integer, IN _analysismanagerversion text, IN _remoteinfo text, IN _jobcounttopreview integer, IN _usebigbangquery boolean, IN _throttlebystarttime boolean, IN _maxstepnumtothrottle integer, IN _throttleallsteptools boolean, IN _logspusage boolean); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.request_step_task_xml(IN _processorname text, INOUT _job integer, INOUT _parameters text, INOUT _message text, INOUT _returncode text, IN _infolevel integer, IN _analysismanagerversion text, IN _remoteinfo text, IN _jobcounttopreview integer, IN _usebigbangquery boolean, IN _throttlebystarttime boolean, IN _maxstepnumtothrottle integer, IN _throttleallsteptools boolean, IN _logspusage boolean) IS 'RequestStepTaskXML';

