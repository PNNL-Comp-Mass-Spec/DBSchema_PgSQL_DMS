--
CREATE OR REPLACE PROCEDURE sw.update_manager_and_task_status
(
    _mgrName text,
    _mgrStatus text,
    _lastUpdate timestamp,
    _lastStartTime timestamp,
    _cPUUtilization real,
    _freeMemoryMB real,
    _processID int = null,
    _progRunnerProcessID int = null,
    _progRunnerCoreUsage real = null,
    _mostRecentErrorMessage text = '',
    -- Task    items
    _stepTool text,
    _taskStatus text,
    _durationHours real,
    _progress real,
    _currentOperation text,
    -- Task detail items
    _taskDetailStatus text,
    _job int,
    _jobStep int,
    _dataset text,
    _mostRecentLogMessage text = '',
    _mostRecentJobInfo text = '',
    _spectrumCount int=0,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Logs the current status of the given analysis manager
**
**      Manager status is typically stored in the database using UpdateManagerAndTaskStatusXML,
**      which is called by the StatusMessageDBUpdater
**      (running at \\proto-5\DMS_Programs\StatusMessageDBUpdater)
**
**      The StatusMessageDBUpdater caches the status messages from the managers, then
**      periodically calls UpdateManagerAndTaskStatusXML to update T_Processor_Status
**
**      However, if the message broker stops working, running analysis managers
**      will set LogStatusToBrokerDB to true, meaning calls to WriteStatusFile
**      will cascade into method LogStatus, which will call this procedure
**
**  Arguments:
**    _spectrumCount   The total number of spectra that need to be processed (or have been generated).  For Sequest, this is the DTA count
**
**  Auth:   mem
**  Date:   03/24/2009 mem - Initial version
**          03/26/2009 mem - Added parameter _mostRecentJobInfo
**          03/31/2009 mem - Added parameter _dSScanCount
**          04/09/2009 grk - _message needs to be initialized to '' inside body of sproc
**          06/26/2009 mem - Expanded to support the new status fields
**          08/29/2009 mem - Commented out the update code to disable the functionality of this procedure (superseded by UpdateManagerAndTaskStatusXML, which is called by StatusMessageDBUpdater)
**          05/04/2015 mem - Added Process_ID
**          11/20/2015 mem - Added ProgRunner_ProcessID and ProgRunner_CoreUsage
**          08/25/2022 mem - Re-enabled the functionality of this procedure
**                         - Replaced int parameters _mgrStatusCode, _taskStatusCode, and _taskDetailStatusCode
**                           with string parameters _mgrStatus, _taskStatus, and _taskDetailStatus
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
BEGIN
    _message := '';
    _returnCode:= '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _mgrName := Coalesce(_mgrName, '');
    _mgrStatus := Coalesce(_mgrStatus, 'Stopped');
    _lastUpdate := Coalesce(_lastUpdate, CURRENT_TIMESTAMP);
    _mostRecentErrorMessage := Coalesce(_mostRecentErrorMessage, '');

    _stepTool := Coalesce(_stepTool, '');
    _taskStatus := Coalesce(_taskStatus, 'No Task');
    _currentOperation := Coalesce(_currentOperation, '');

    _taskDetailStatus := Coalesce(_taskDetailStatus, 'No Task');
    _dataset := Coalesce(_dataset, '');
    _mostRecentLogMessage := Coalesce(_mostRecentLogMessage, '');
    _mostRecentJobInfo := Coalesce(_mostRecentJobInfo, '');
    _spectrumCount := Coalesce(_spectrumCount, 0);

    _message := '';
    _returnCode:= '';

    If char_length(_mgrName) = 0 Then
        _message := 'Processor name is empty; unable to continue';
        RETURN;
    End If;

    -- Check whether this processor is missing from sw.t_processor_status
    If Not Exists (SELECT * FROM sw.t_processor_status WHERE processor_name = _mgrName) Then
        -- Processor is missing; add it
        INSERT INTO sw.t_processor_status (processor_name, mgr_status, task_status, Task_Detail_Status)
        VALUES (_mgrName, _mgrStatus, _taskStatus, _taskDetailStatus)
    End If;

    UPDATE sw.t_processor_status
    SET
        remote_manager = '',
        mgr_status = _mgrStatus,
        status_date = _lastUpdate,
        last_start_time = _lastStartTime,
        cpu_utilization = _cPUUtilization,
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
    WHERE Processor_Name = _mgrName

END
$$;

COMMENT ON PROCEDURE sw.update_manager_and_task_status IS 'UpdateManagerAndTaskStatus';
