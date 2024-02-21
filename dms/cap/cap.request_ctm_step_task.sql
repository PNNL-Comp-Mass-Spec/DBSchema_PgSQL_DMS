--
-- Name: request_ctm_step_task(text, integer, refcursor, text, text, integer, text, integer, integer); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.request_ctm_step_task(IN _processorname text, INOUT _jobnumber integer DEFAULT 0, INOUT _results refcursor DEFAULT '_results'::refcursor, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infolevel integer DEFAULT 0, IN _managerversion text DEFAULT ''::text, IN _jobcounttopreview integer DEFAULT 10, IN _serverperspectiveenabled integer DEFAULT 0)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Look for capture task job step that is appropriate for the given Capture task manager
**      If found, step is assigned to caller
**
**      Task assignment is based on:
**        Assignment restrictions:
**          Job not in hold state
**          Processor on storage machine (for step tools that require it)
**          Bionet access (for step tools that reqire it)
**          Maximum simultaneous captures for instrument (for step tools that reqire it)
**        Job-Tool priority
**        Job priority
**        Job number
**        Step Number
**
**  Arguments:
**    _processorName                Capture task manager name
**    _jobNumber                    Capture task job number assigned; 0 if no job available
**    _results                      Cursor for retrieving the job parameters
**    _message                      Status message (if an error)
**    _returnCode                   Return code (if an error)
**    _infoLevel                    0 to request a task, 1 to preview the capture task job that would be returned; 2 to include details on the available capture tasks
**    _managerVersion               Capture task manager version (stored in cap.t_local_processors)
**    _jobCountToPreview            The number of capture task jobs to preview
**    _serverPerspectiveEnabled     When 0, manager parameter 'perspective' is 'client', meaning the manager will use paths of the form \\proto-5\Exact04\2012_1
**                                  When 1, manager parameter 'perspective' is 'server', meaning the manager will use paths of the form E:\Exact04\2012_1
**                                  The Capture Task Manager does not set the value for this parameter, meaning it is always 0
**
**  To test this procedure, use an anonymous code block:

    DO
    LANGUAGE plpgsql
    $$
    DECLARE
        _jobNumber int;
        _results refcursor;
        _message text;
        _returnCode text;
        _jobParams record;
        _itemsShown int = 0;
        _formatSpecifier text;
    BEGIN
        CALL cap.request_ctm_step_task(
                    _processorName     => 'Proto-3_CTM',
                    _jobNumber         => _jobNumber,
                    _results           => _results,
                    _message           => _message,
                    _returnCode        => _returnCode,
                    _infoLevel         => 2,
                    _managerVersion    => '',
                    _jobCountToPreview => 10
                );

        RAISE INFO '';
        RAISE INFO 'Capture task job parameters';

        _formatSpecifier := '%-22s %-30s';

        WHILE NOT _results IS NULL
        LOOP
            FETCH NEXT FROM _results
            INTO _jobParams;

            If Not FOUND Or _itemsShown > 10 Then
                 EXIT;
            End If;

            RAISE INFO '%', format(_formatSpecifier,  _jobParams.Parameter || ':', _jobParams.Value);

            _itemsShown := _itemsShown + 1;
        END LOOP;
    END
    $$;

**
**  Auth:   grk
**  Date:   09/15/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          01/11/2010 grk - Capture task job must be in new or busy states
**          01/20/2010 grk - Added logic for instrument/processor assignment
**          02/01/2010 grk - Added instrumentation for more logging of reject requests
**          03/12/2010 grk - Fixed problem with inadvertent throttling of step tools that aren't subject to it
**          03/21/2011 mem - Switched t_tasks.State test from State IN (1,2) to State < 100
**          04/12/2011 mem - Now making an entry in T_task_Step_Processing_Log for each capture task job step assigned
**          05/18/2011 mem - No longer making an entry in T_task_Request_Log for every request
**                         - Now showing the top _jobCountToPreview candidate steps when _infoLevel is > 0
**          07/26/2012 mem - Added parameter _serverPerspectiveEnabled
**          09/17/2012 mem - Now returning metadata for step tool DatasetQuality instead of step tool DatasetInfo
**          02/25/2013 mem - Now returning the Machine name when _infoLevel > 0
**          09/24/2014 mem - Removed reference to Machine in t_task_steps
**          11/05/2015 mem - Consider column Enabled when checking T_Processor_Instrument for _processorName
**          01/11/2016 mem - When looking for running capture task jobs for each instrument, now ignoring job steps that started over 18 hours ago
**          01/27/2017 mem - Show additional information when _infoOnly is true
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          07/01/2017 mem - Improve info displayed when _infoOnly and no capture task jobs are available
**          08/01/2017 mem - Use THROW if not authorized
**          06/12/2018 mem - Update code formatting
**          01/31/2020 mem - Add _returnCode, which duplicates the integer returned by this procedure; _returnCode is varchar for compatibility with Postgres error codes
**          06/07/2023 mem - Renamed _infoOnly to _infoLevel and Ported to PostgreSQL
**          06/11/2023 mem - Add missing variable _nameWithSchema
**          07/11/2023 mem - Use COUNT(TS.job) and COUNT(processor_name) instead of COUNT(*)
**          09/07/2023 mem - Align assignment statements
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          10/27/2023 mem - Apply a row-level lock to cap.t_task_steps using FOR UPDATE
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _processorNameMatch citext;
    _machine citext;
    _numTools int;
    _processorAssignmentCount int;

    _debugMessage text;
    _jobNotAvailableErrorCode text := 'U5301';

    _numCandidates int;
    _step int;
    _stepTool text;
    _jobAssigned boolean := false;
    _machineLockedStepTools text;
    _excludeCaptureTasks boolean := false;
    _candidateJobStepsToRetrieve int := 25;
    _processorLockedToInstrument boolean := false;
    _jobInfo record;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;

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

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs; clear the outputs
        ---------------------------------------------------

        _processorName            := Trim(Coalesce(_processorName, ''));
        _jobNumber                := 0;
        _infoLevel                := Coalesce(_infoLevel, 0);
        _managerVersion           := Trim(Coalesce(_managerVersion, ''));
        _jobCountToPreview        := Coalesce(_jobCountToPreview, 10);
        _serverPerspectiveEnabled := Coalesce(_serverPerspectiveEnabled, 0);

        If _jobCountToPreview > _candidateJobStepsToRetrieve Then
            _candidateJobStepsToRetrieve := _jobCountToPreview;
        End If;

        ---------------------------------------------------
        -- The capture task manager expects a non-zero
        -- return value if no capture task jobs are available
        -- Code 'U5301' is used for this
        ---------------------------------------------------

        If _infoLevel > 1 Then
            RAISE INFO '';
            RAISE INFO '%, Request_CTM_Step_Task: Starting; make sure this is a valid processor', public.timestamp_text_immutable(clock_timestamp());
        End If;

        _currentLocation := 'Query cap.t_local_processors';

        ---------------------------------------------------
        -- Make sure this is a valid processor
        -- (and capitalize it according to cap.t_local_processors)
        ---------------------------------------------------

        SELECT machine,
               processor_name
        INTO _machine, _processorNameMatch
        FROM cap.t_local_processors
        WHERE processor_name = _processorName::citext;

        -- Check if no processor found?
        If Not FOUND Then
            _message := format('Processor not defined in cap.t_local_processors: %s', _processorName);
            _returnCode := _jobNotAvailableErrorCode;

            RAISE WARNING '%', _message;

            RETURN;
        End If;

        _processorName := _processorNameMatch;

        ---------------------------------------------------
        -- Show processor name and machine if _infoLevel is non-zero
        ---------------------------------------------------

        If _infoLevel <> 0 Then
            RAISE INFO 'Processor %, Machine %', _processorName, _machine;
        End If;

        ---------------------------------------------------
        -- Update processor's request timestamp
        -- (to show when the processor was most recently active)
        ---------------------------------------------------

        If _infoLevel = 0 Then
            _currentLocation := 'Update cap.t_local_processors';

            UPDATE cap.t_local_processors
            SET latest_request = CURRENT_TIMESTAMP,
                manager_version = CASE WHEN _managerVersion = ''
                                       THEN manager_version
                                       ELSE _managerVersion
                                  END
            WHERE processor_name = _processorName;

            If _managerVersion = '' Then
                RAISE WARNING 'Manager version is an empty string; updated latest_request in cap.t_local_processors but left manager_version unchanged';
            End If;
        End If;

        ---------------------------------------------------
        -- Get list of step tools currently assigned to processor
        -- active tools that are presently handled by this processor
        -- (don't use tools that require bionet if processor machine doesn't have it)
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_AvailableProcessorTools (
            Tool_Name text,
            Tool_Priority int,
            Only_On_Storage_Server text,
            Instrument_Capacity_Limited text,
            Bionet_OK text,
            Processor_Assignment_Applies text
        );

        _currentLocation := 'Populate Tmp_AvailableProcessorTools';

        INSERT INTO Tmp_AvailableProcessorTools( Tool_Name,
                                                 Tool_Priority,
                                                 Only_On_Storage_Server,
                                                 Instrument_Capacity_Limited,
                                                 Bionet_OK,
                                                 Processor_Assignment_Applies )
        SELECT ProcTool.Tool_Name,
               ProcTool.Priority,
               ST.Only_On_Storage_Server,
               ST.Instrument_Capacity_Limited,
               CASE
                   WHEN Bionet_Required = 'Y' AND
                        Bionet_Available <> 'Y' THEN 'N'
                   ELSE 'Y'
               END AS Bionet_OK,
               ST.processor_assignment_applies
        FROM cap.t_local_processors LP
             INNER JOIN cap.t_processor_tool ProcTool
               ON LP.processor_name = ProcTool.processor_name
             INNER JOIN cap.t_step_tools ST
               ON ProcTool.tool_name = ST.step_tool
             INNER JOIN cap.t_machines M
               ON LP.machine = M.machine
        WHERE ProcTool.enabled > 0 AND
              LP.state = 'E' AND
              LP.processor_name = _processorName;

        If _infoLevel > 1 Then
            SELECT string_agg(Tool_Name, ', ' ORDER BY Tool_Name)
            INTO _debugMessage
            FROM Tmp_AvailableProcessorTools;

            RAISE INFO 'Tools enabled for this processor: %', _debugMessage;
        End If;

        ---------------------------------------------------
        -- Bail out if no tools available, and _infoLevel is 0
        ---------------------------------------------------

        SELECT COUNT(*)
        INTO _numTools
        FROM Tmp_AvailableProcessorTools;

        If _infoLevel = 0 And _numTools = 0 Then
            _message := format('No tools presently available for processor "%s"', _processorName);
            _returnCode := _jobNotAvailableErrorCode;

            DROP TABLE Tmp_AvailableProcessorTools;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Get a list of instruments and their current loading
        -- (steps in busy state that have step tools that are
        --  instrument capacity limited tools, summed by Instrument)
        --
        -- Ignore capture task job steps that started over 18 hours ago; they're probably stalled
        --
        -- In practice, the only step tool that is instrument-capacity limited is DatasetCapture
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_InstrumentLoading (
            Instrument text,
            Captures_In_Progress int,
            Max_Simultaneous_Captures int,
            Available_Capacity int
        );

        _currentLocation := 'Populate Tmp_InstrumentLoading';

        INSERT INTO Tmp_InstrumentLoading( Instrument,
                                           Captures_In_Progress,
                                           Max_Simultaneous_Captures,
                                           Available_Capacity )
        SELECT T.Instrument,
               COUNT(TS.job) AS Captures_In_Progress,
               T.Max_Simultaneous_Captures,
               T.Max_Simultaneous_Captures - COUNT(TS.job) AS Available_Capacity
        FROM cap.t_task_steps TS
             INNER JOIN cap.t_step_tools ST
               ON TS.Tool = ST.step_tool
             INNER JOIN cap.t_tasks T
               ON TS.Job = T.Job
        WHERE TS.State = 4 AND
              ST.instrument_capacity_limited = 'Y' AND
              TS.Start >= CURRENT_TIMESTAMP - Interval '18 hours'
        GROUP BY T.Instrument, T.Max_Simultaneous_Captures;

        ---------------------------------------------------
        -- Is processor assigned to any instrument?
        ---------------------------------------------------

        SELECT COUNT(processor_name)
        INTO _processorAssignmentCount
        FROM cap.t_processor_instrument
        WHERE processor_name = _processorName AND
              enabled > 0;

        ---------------------------------------------------
        -- Get list of instruments that have processor assignments
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_InstrumentProcessor (
            Instrument text,
            Assigned_To_This_Processor int,
            Assigned_To_Any_Processor int
        );

        _currentLocation := 'Populate Tmp_InstrumentProcessor';

        INSERT INTO Tmp_InstrumentProcessor( Instrument,
                                             Assigned_To_This_Processor,
                                             Assigned_To_Any_Processor )
        SELECT Instrument_Name AS Instrument,
               SUM(CASE
                       WHEN Processor_Name = _processorName::citext THEN 1
                       ELSE 0
                   END) AS Assigned_To_This_Processor,
               SUM(1) AS Assigned_To_Any_Processor
        FROM cap.t_processor_instrument
        WHERE enabled = 1
        GROUP BY instrument_name;

        If _processorAssignmentCount = 0 And _serverPerspectiveEnabled <> 0 Then
            -- The capture task managers running on the Proto-x servers have perspective = 'server'
            -- During dataset capture, if perspective='server', the manager will use dataset paths of the form E:\Exact04\2012_1
            --   In contrast, CTM's with  perspective='client' will use dataset paths of the form \\proto-5\Exact04\2012_1
            -- Therefore, capture tasks that occur on the Proto-x servers should be limited to instruments whose data is stored on the same server as the CTM
            --   This is accomplished via one or more mapping rows in table cap.t_processor_instrument
            -- If a capture task manager running on a Proto-x server has the DatasetCapture tool enabled, yet does not have an entry in cap.t_processor_instrument,
            --   we do not allow capture tasks to be assigned (to thus avoid drive path problems)
            _excludeCaptureTasks := true;

            If _infoLevel > 0 Then
                RAISE INFO 'Note: setting _excludeCaptureTasks to true because this processor does not have any entries in cap.t_processor_instrument, yet _serverPerspectiveEnabled is 1';
            End If;
        End If;

        If Exists (SELECT Instrument FROM Tmp_InstrumentProcessor WHERE Assigned_To_This_Processor > 0) Then
            _processorLockedToInstrument := true;

            If _infoLevel > 1 Then
                SELECT string_agg(Instrument_Name, ', ' ORDER BY Instrument)
                INTO _debugMessage
                FROM Tmp_InstrumentProcessor;

                RAISE INFO 'Instruments locked to this processor: %', _debugMessage;
            End If;
        End If;

        ---------------------------------------------------
        -- Table to hold capture task job step candidates
        -- for possible assignment
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_CandidateJobSteps (
            Seq int NOT NULL GENERATED ALWAYS AS IDENTITY,
            Job int,
            Step int,
            Job_Priority int,
            Tool text,
            Tool_Priority int
        );

        _currentLocation := 'Populate Tmp_CandidateJobSteps';

        ---------------------------------------------------
        -- Get list of viable capture task job steps,
        -- organized by processor, in order of assignment priority
        ---------------------------------------------------

        INSERT INTO Tmp_CandidateJobSteps( Job,
                                           Step,
                                           Job_Priority,
                                           Tool,
                                           Tool_Priority )
        SELECT T.Job,
               TS.Step,
               T.Priority,
               TS.Tool,
               APT.Tool_Priority
        FROM cap.t_task_steps TS
             INNER JOIN cap.t_tasks T
               ON TS.Job = T.Job
             INNER JOIN Tmp_AvailableProcessorTools APT
               ON TS.Tool = APT.Tool_Name
             LEFT OUTER JOIN Tmp_InstrumentProcessor IP
               ON IP.Instrument = T.Instrument
             LEFT OUTER JOIN Tmp_InstrumentLoading IL
               ON IL.Instrument = T.Instrument
        WHERE CURRENT_TIMESTAMP > TS.Next_Try AND
              TS.State = 2 AND
              APT.Bionet_OK = 'Y' AND
              T.State < 100 AND
              NOT (APT.Only_On_Storage_Server = 'Y' AND Storage_Server <> _machine) AND
              NOT (_excludeCaptureTasks AND TS.Tool = 'DatasetCapture') AND
              (APT.Instrument_Capacity_Limited = 'N'  OR (NOT Coalesce(IL.Available_Capacity, 1) < 1)) AND
              (APT.Processor_Assignment_Applies = 'N' OR (
                 (_processorAssignmentCount > 0 AND Coalesce(IP.Assigned_To_This_Processor, 0) > 0) OR
                 (_processorAssignmentCount = 0 AND Coalesce(IP.Assigned_To_Any_Processor,  0) = 0)))
        ORDER BY APT.Tool_Priority, T.Priority, T.Job, TS.Step
        LIMIT _candidateJobStepsToRetrieve;
        --
        GET DIAGNOSTICS _numCandidates = ROW_COUNT;

        ---------------------------------------------------
        -- Bail out if no steps available, and _infoLevel = 0
        ---------------------------------------------------

        If _infoLevel = 0 And _numCandidates = 0 Then
            _message := 'No candidates presently available';
            _returnCode := _jobNotAvailableErrorCode;

            DROP TABLE Tmp_AvailableProcessorTools;
            DROP TABLE Tmp_InstrumentLoading;
            DROP TABLE Tmp_InstrumentProcessor;
            DROP TABLE Tmp_CandidateJobSteps;

            RETURN;
        End If;

        ---------------------------------------------------
        -- Try to assign step
        ---------------------------------------------------

        If _infoLevel > 1 Then
            RAISE INFO '%, Request_CTM_Step_Task: look for available step', public.timestamp_text_immutable(clock_timestamp());
        End If;

        _currentLocation := 'Find best step candidate';

        BEGIN
            ---------------------------------------------------
            -- Get best step candidate in order of preference:
            --   Assignment priority (prefer directly associated capture task jobs to general pool)
            --   Job-Tool priority
            --   Overall job priority
            --   Later steps over earler steps
            --   Job number
            ---------------------------------------------------

            SELECT TS.Job,
                   TS.Step,
                   TS.Tool
            INTO _jobNumber, _step, _stepTool
            FROM cap.t_task_steps TS
                 INNER JOIN Tmp_CandidateJobSteps CJS
                   ON CJS.Job = TS.Job AND
                      CJS.Step = TS.Step
            WHERE TS.State = 2
            ORDER BY Seq
            LIMIT 1
            FOR UPDATE;         -- Lock the row to prevent other managers from selecting this capture task job

            If FOUND Then
                _jobAssigned := true;

                If _infoLevel > 0 Then
                    RAISE INFO 'Would assign Capture Task Job %, Step %', _jobNumber, _step;
                End If;
            End If;

            ---------------------------------------------------
            -- If a capture task job step was assigned and
            -- if _infoLevel is 0, update the step state to Running
            ---------------------------------------------------

            If _jobAssigned And _infoLevel = 0 Then
                _currentLocation := 'Update State and Processor in cap.t_task_steps';

                UPDATE cap.t_task_steps
                SET State = 4,
                    Processor = _processorName,
                    Start = CURRENT_TIMESTAMP,
                    Finish = NULL
                WHERE Job = _jobNumber AND
                      Step = _step;
            End If;

        END;

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
        DROP TABLE IF EXISTS Tmp_InstrumentLoading;
        DROP TABLE IF EXISTS Tmp_InstrumentProcessor;
        DROP TABLE IF EXISTS Tmp_CandidateJobSteps;

        RETURN;
    END;

    If _jobAssigned And _infoLevel = 0 Then
        _currentLocation := 'Commit since _jobAssigned is true';
        COMMIT;
    End If;

    BEGIN
        ---------------------------------------------------
        -- Temp table to hold capture task job parameters
        ---------------------------------------------------

        DROP TABLE IF EXISTS Tmp_JobParamsTable;

        CREATE TEMP TABLE Tmp_JobParamsTable (
            Section text,
            Name text,
            Value text
        );

        If _jobAssigned Then

            If _infoLevel = 0 Then
                ---------------------------------------------------
                -- Add entry to T_task_Step_Processing_Log
                ---------------------------------------------------

                _currentLocation := 'Add entry to T_task_Step_Processing_Log';

                INSERT INTO cap.t_task_step_processing_log (job, step, processor)
                VALUES (_jobNumber, _step, _processorName);
            End If;

            If _infoLevel > 1 Then
                RAISE INFO '%, Request_CTM_Step_Task: Query cap.get_task_step_params', public.timestamp_text_immutable(clock_timestamp());
            End If;

            ---------------------------------------------------
            -- Capture task job was assigned; get step parameters
            ---------------------------------------------------

            _currentLocation := 'Populate Tmp_JobParamsTable';

            INSERT INTO Tmp_JobParamsTable (Section, Name, Value)
            SELECT Src.Section, Src.Name, Src.Value
            FROM cap.get_task_step_params(_jobNumber, _step) Src;

        Else
            ---------------------------------------------------
            -- No capture task job steps found; update _message and _returnCode
            ---------------------------------------------------

            _message := 'No available capture task jobs';
            _returnCode := _jobNotAvailableErrorCode;

            If _infoLevel > 1 Then
                RAISE INFO '%', _message;
            End If;
        End If;

        ---------------------------------------------------
        -- Dump candidate list if _infoLevel is non-zero
        ---------------------------------------------------

        If _infoLevel <> 0 Then
            If _infoLevel > 1 Then
                RAISE INFO '%, Request_CTM_Step_Task: Preview results', public.timestamp_text_immutable(clock_timestamp());
            End If;

            _currentLocation := 'Populate _machineLockedStepTools';

            SELECT string_agg(step_tool, ', ' ORDER BY step_tool)
            INTO _machineLockedStepTools
            FROM cap.t_step_tools
            WHERE only_on_storage_server = 'Y';

            -- Preview the next _jobCountToPreview available capture task jobs

            RAISE INFO '';

            If Exists (SELECT Job FROM Tmp_CandidateJobSteps) Then

                _currentLocation := 'Show candidate job steps';

                RAISE INFO 'Candidate capture task job steps for %', _processorName;

                _formatSpecifier := '%-10s %-5s %-20s %-6s %-14s %-14s %-80s';

                _infoHead := format(_formatSpecifier,
                                    'Job',
                                    'Step',
                                    'Tool',
                                    'Seq',
                                    'Tool_Priority',
                                    'Job_Priority',
                                    'Dataset'
                                   );

                _infoHeadSeparator := format(_formatSpecifier,
                                             '----------',
                                             '-----',
                                             '--------------------',
                                             '------',
                                             '--------------',
                                             '--------------',
                                             '--------------------------------------------------------------------------------'
                                            );

                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _jobInfo IN
                    SELECT CJS.Job, CJS.Step, CJS.Tool,
                           CJS.Seq, T.Priority,
                           CJS.Job_Priority, T.Dataset
                    FROM Tmp_CandidateJobSteps CJS
                         INNER JOIN cap.t_tasks T
                           ON CJS.Job = T.Job
                    ORDER BY Seq
                    LIMIT _jobCountToPreview
                LOOP
                    RAISE INFO '%', format(_formatSpecifier,
                                           _jobInfo.Job,
                                           _jobInfo.Step,
                                           _jobInfo.Tool,
                                           _jobInfo.Seq,
                                           _jobInfo.Priority,
                                           _jobInfo.Job_Priority,
                                           _jobInfo.Dataset);
                END LOOP;
            Else
                RAISE INFO 'No candidate capture task job steps found for % (capture task jobs with step tools % only assigned if dataset stored on %)',
                                _processorName, _machineLockedStepTools, _machine;

                If _processorLockedToInstrument THEN
                    RAISE INFO 'Note: Processor locked to instrument';
                End If;

            End If;

            ---------------------------------------------------
            -- Dump candidate list if the info level is 2 or higher
            ---------------------------------------------------

            If _infoLevel >= 2 Then

                _currentLocation := 'Show results from request_ctm_step_task_explanation';

                _formatSpecifier := '%-80s %-80s';

                _infoHead := format(_formatSpecifier,
                                    'Parameter',
                                    'Value'
                                   );

                _infoHeadSeparator := format(_formatSpecifier,
                                             '--------------------------------------------------------------------------------',
                                             '--------------------------------------------------------------------------------'
                                            );

                RAISE INFO '';
                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _jobInfo IN
                    SELECT Parameter, Value
                    FROM cap.request_ctm_step_task_explanation(_processorName, _processorAssignmentCount, _machine)
                LOOP
                    RAISE INFO '%', format(_formatSpecifier,
                                           _jobInfo.Parameter,
                                           _jobInfo.Value);

                END LOOP;
            End If;

        End If;

        ---------------------------------------------------
        -- Output capture task job parameters as resultset
        ---------------------------------------------------

        Open _results For
            SELECT Name AS Parameter,
                   Value
            FROM Tmp_JobParamsTable;

        DROP TABLE Tmp_AvailableProcessorTools;
        DROP TABLE Tmp_InstrumentLoading;
        DROP TABLE Tmp_InstrumentProcessor;
        DROP TABLE Tmp_CandidateJobSteps;

        -- Note: do not drop Tmp_JobParamsTable since the _results cursor still needs to reference it

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
        DROP TABLE IF EXISTS Tmp_InstrumentLoading;
        DROP TABLE IF EXISTS Tmp_InstrumentProcessor;
        DROP TABLE IF EXISTS Tmp_CandidateJobSteps;
    END;

END
$_$;


ALTER PROCEDURE cap.request_ctm_step_task(IN _processorname text, INOUT _jobnumber integer, INOUT _results refcursor, INOUT _message text, INOUT _returncode text, IN _infolevel integer, IN _managerversion text, IN _jobcounttopreview integer, IN _serverperspectiveenabled integer) OWNER TO d3l243;

--
-- Name: PROCEDURE request_ctm_step_task(IN _processorname text, INOUT _jobnumber integer, INOUT _results refcursor, INOUT _message text, INOUT _returncode text, IN _infolevel integer, IN _managerversion text, IN _jobcounttopreview integer, IN _serverperspectiveenabled integer); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.request_ctm_step_task(IN _processorname text, INOUT _jobnumber integer, INOUT _results refcursor, INOUT _message text, INOUT _returncode text, IN _infolevel integer, IN _managerversion text, IN _jobcounttopreview integer, IN _serverperspectiveenabled integer) IS 'RequestCTMStepTask or RequestStepTask';

