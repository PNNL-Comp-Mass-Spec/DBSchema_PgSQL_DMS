--
-- Name: update_manager_and_task_status(text, text, timestamp without time zone, timestamp without time zone, real, real, integer, integer, real, text, text, text, real, real, text, text, integer, integer, text, text, text, integer, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.update_manager_and_task_status(IN _mgrname text, IN _mgrstatus text, IN _lastupdate timestamp without time zone, IN _laststarttime timestamp without time zone, IN _cpuutilization real, IN _freememorymb real, IN _processid integer DEFAULT NULL::integer, IN _progrunnerprocessid integer DEFAULT NULL::integer, IN _progrunnercoreusage real DEFAULT NULL::real, IN _mostrecenterrormessage text DEFAULT ''::text, IN _steptool text DEFAULT ''::text, IN _taskstatus text DEFAULT ''::text, IN _durationhours real DEFAULT NULL::real, IN _progress real DEFAULT NULL::real, IN _currentoperation text DEFAULT ''::text, IN _taskdetailstatus text DEFAULT ''::text, IN _job integer DEFAULT 0, IN _jobstep integer DEFAULT 0, IN _dataset text DEFAULT ''::text, IN _mostrecentlogmessage text DEFAULT ''::text, IN _mostrecentjobinfo text DEFAULT ''::text, IN _spectrumcount integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Log the current status of the given analysis manager, updating table sw.t_processor_status
**
**      Manager status is typically stored in the database using sw.Update_Manager_And_Task_Status_XML,
**      which is called by the StatusMessageDBUpdater
**      (running at \\proto-5\DMS_Programs\StatusMessageDBUpdater)
**
**      The StatusMessageDBUpdater caches the status messages from the managers, then
**      periodically calls Update_Manager_And_Task_Status_XML to update T_Processor_Status
**
**      However, if the message broker stops working, running analysis managers
**      will set LogStatusToBrokerDB to true, meaning calls to WriteStatusFile
**      will cascade into method LogStatus, which will call this procedure
**
**  Arguments:
**    -- Manager Info --
**    _mgrName                  Manager name
**    _mgrStatus                Manager status
**    _lastUpdate               Last update time
**    _lastStartTime            Last start time
**    _cpuUtilization           CPU Utilization
**    _freeMemoryMB             Free memory, in MB
**    _processID                Manager's process ID
**    _progRunnerProcessID      Program runner process ID (if an external program is being run by the manager)
**    _progRunnerCoreUsage      Program runner core usage
**    _mostRecentErrorMessage   Most recently logged error message
**
**    -- Task Info --
**    _stepTool                 Step tool for the current step task
**    _taskStatus               Job task status (typically 'No Task' or 'Running')
**    _durationHours            Runtime, in hours, for the current step task
**    _progress                 Progress (% complete); value between 0 and 100
**    _currentOperation         Description of the current work being performed
**
**    -- Task Detail Info --
**    _taskDetailStatus         Additional description of the current operation
**    _job                      Job number if processing a job step, otherwise 0
**    _jobStep                  Step number
**    _dataset                  Dataset name
**    _mostRecentLogMessage     Most recent log message
**    _mostRecentJobInfo        Most recent job info, for example: Job 2191592; MSGFPlus (MSGFPlus_MzML_NoRefine); QC_Mam_23_01_60min_b_Bane_09Jun23_WBEH-23-05-11; 2023-06-09 13:44:02
**    _spectrumCount            Total number of spectra that need to be processed (or have been generated). For SEQUEST, this is the DTA count
**
**  Auth:   mem
**  Date:   03/24/2009 mem - Initial version
**          03/26/2009 mem - Added parameter _mostRecentJobInfo
**          03/31/2009 mem - Added parameter _dSScanCount
**          04/09/2009 grk - _message needs to be initialized to '' inside body of sproc
**          06/26/2009 mem - Expanded to support the new status fields
**          08/29/2009 mem - Commented out the update code to disable the functionality of this procedure (superseded by Update_Manager_And_Task_Status_XML, which is called by StatusMessageDBUpdater)
**          05/04/2015 mem - Added Process_ID
**          11/20/2015 mem - Added Prog_Runner_Process_ID and Prog_Runner_Core_Usage
**          08/25/2022 mem - Re-enabled the functionality of this procedure
**                         - Replaced int parameters _mgrStatusCode, _taskStatusCode, and _taskDetailStatusCode
**                           with string parameters _mgrStatus, _taskStatus, and _taskDetailStatus
**          08/14/2023 mem - Ported to PostgreSQL
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**
*****************************************************/
DECLARE
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _mgrName                := Trim(Coalesce(_mgrName, ''));
    _mgrStatus              := Trim(Coalesce(_mgrStatus, 'Stopped'));
    _lastUpdate             := Coalesce(_lastUpdate, CURRENT_TIMESTAMP);
    _mostRecentErrorMessage := Trim(Coalesce(_mostRecentErrorMessage, ''));

    _stepTool               := Trim(Coalesce(_stepTool, ''));
    _taskStatus             := Trim(Coalesce(_taskStatus, 'No Task'));
    _currentOperation       := Trim(Coalesce(_currentOperation, ''));

    _taskDetailStatus       := Trim(Coalesce(_taskDetailStatus, 'No Task'));
    _dataset                := Trim(Coalesce(_dataset, ''));
    _mostRecentLogMessage   := Trim(Coalesce(_mostRecentLogMessage, ''));
    _mostRecentJobInfo      := Trim(Coalesce(_mostRecentJobInfo, ''));
    _spectrumCount          := Coalesce(_spectrumCount, 0);

    If char_length(_mgrName) = 0 Then
        _message := 'Processor name is empty; unable to continue';
        RETURN;
    End If;

    -- Check whether this processor is missing from sw.t_processor_status
    If Not Exists (SELECT processor_name FROM sw.t_processor_status WHERE processor_name = _mgrName) Then
        -- Processor is missing; add it
        INSERT INTO sw.t_processor_status (processor_name, mgr_status, task_status, Task_Detail_Status)
        VALUES (_mgrName, _mgrStatus, _taskStatus, _taskDetailStatus);
    End If;

    UPDATE sw.t_processor_status
    SET remote_manager = '',
        mgr_status = _mgrStatus,
        status_date = _lastUpdate,
        last_start_time = _lastStartTime,
        cpu_utilization = _cpuUtilization,
        free_memory_mb = _freeMemoryMB,
        process_id = _processID,
        prog_runner_process_id = _progRunnerProcessID,
        prog_runner_core_usage = _progRunnerCoreUsage,
        Most_Recent_Error_Message = CASE WHEN _mostRecentErrorMessage <> '' THEN _mostRecentErrorMessage ELSE Most_Recent_Error_Message END,
        Step_Tool = _stepTool,
        Task_Status = _taskStatus,
        Duration_Hours = _durationHours,
        Progress = _progress,
        Current_Operation = _currentOperation,
        Task_Detail_Status = _taskDetailStatus,
        Job = _job,
        Job_Step = _jobStep,
        Dataset = _dataset,
        Most_Recent_Log_Message =   CASE WHEN _mostRecentLogMessage <> ''   THEN _mostRecentLogMessage   ELSE Most_Recent_Log_Message END,
        Most_Recent_Job_Info =      CASE WHEN _mostRecentJobInfo <> ''      THEN _mostRecentJobInfo      ELSE Most_Recent_Job_Info END,
        Spectrum_Count = _spectrumCount
    WHERE Processor_Name = _mgrName;

END
$$;


ALTER PROCEDURE sw.update_manager_and_task_status(IN _mgrname text, IN _mgrstatus text, IN _lastupdate timestamp without time zone, IN _laststarttime timestamp without time zone, IN _cpuutilization real, IN _freememorymb real, IN _processid integer, IN _progrunnerprocessid integer, IN _progrunnercoreusage real, IN _mostrecenterrormessage text, IN _steptool text, IN _taskstatus text, IN _durationhours real, IN _progress real, IN _currentoperation text, IN _taskdetailstatus text, IN _job integer, IN _jobstep integer, IN _dataset text, IN _mostrecentlogmessage text, IN _mostrecentjobinfo text, IN _spectrumcount integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_manager_and_task_status(IN _mgrname text, IN _mgrstatus text, IN _lastupdate timestamp without time zone, IN _laststarttime timestamp without time zone, IN _cpuutilization real, IN _freememorymb real, IN _processid integer, IN _progrunnerprocessid integer, IN _progrunnercoreusage real, IN _mostrecenterrormessage text, IN _steptool text, IN _taskstatus text, IN _durationhours real, IN _progress real, IN _currentoperation text, IN _taskdetailstatus text, IN _job integer, IN _jobstep integer, IN _dataset text, IN _mostrecentlogmessage text, IN _mostrecentjobinfo text, IN _spectrumcount integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.update_manager_and_task_status(IN _mgrname text, IN _mgrstatus text, IN _lastupdate timestamp without time zone, IN _laststarttime timestamp without time zone, IN _cpuutilization real, IN _freememorymb real, IN _processid integer, IN _progrunnerprocessid integer, IN _progrunnercoreusage real, IN _mostrecenterrormessage text, IN _steptool text, IN _taskstatus text, IN _durationhours real, IN _progress real, IN _currentoperation text, IN _taskdetailstatus text, IN _job integer, IN _jobstep integer, IN _dataset text, IN _mostrecentlogmessage text, IN _mostrecentjobinfo text, IN _spectrumcount integer, INOUT _message text, INOUT _returncode text) IS 'UpdateManagerAndTaskStatus';

