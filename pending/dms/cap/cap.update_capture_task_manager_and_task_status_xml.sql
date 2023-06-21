--
CREATE OR REPLACE PROCEDURE cap.update_capture_task_manager_and_task_status_xml
(
    _managerStatusXML text = '',
    _infoLevel int = 0,
    _logProcessorNames boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Update processor status from concatenated list of XML status messages
**
**  Arguments:
**    _managerStatusXML     Manager status XML
**    _infoLevel            0 to update tables; 1 to view debug messages and update the tables; 2 to preview the data but not update tables, 3 to ignore _managerStatusXML, use test data, and update tables, 4 to ignore _managerStatusXML, use test data, and not update tables
**    _logProcessorNames    true to log the names of updated processors (in cap.T_Log_Entries)
**    _message              Output message
**    _returnCode           Return code
**
**  Auth:   grk
**  Date:   08/20/2009 grk - Initial release
**          08/29/2009 mem - Now converting Duration_Minutes to Duration_Hours
**                         - Added Try/Catch error handling
**          08/31/2009 mem - Switched to running a bulk Insert and bulk Update instead of a Delete then Bulk Insert
**          05/04/2015 mem - Added Process_ID
**          02/23/2016 mem - Add set XACT_ABORT on
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          07/06/2017 mem - Allow Status_Date and Last_Start_Time to be UTC-based
**                           Use Try_Cast to convert from varchar to numbers
**                           Add parameter _debugMode
**          08/01/2017 mem - Use THROW if not authorized
**          09/19/2018 mem - Add parameter _logProcessorNames
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _statusInfoCount int;
    _updateCount int;
    _insertCount int;
    _statusMessageInfo text := '';
    _statusXML xml;
    _updatedProcessors text;
    _logMessage text;

    _formatSpecifier text := '%-15s %-15s %-20s %-20s %-5s %-11s %-10s %-20s %-20s %-15s %-15s %-10s %-10s %-5s %-50s';

    _infoHead text;
    _infoHeadSeparator text;
    _infoData text;
    _previewData record;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    _infoLevel := Coalesce(_infoLevel, 0);
    _logProcessorNames := Coalesce(_logProcessorNames, false);

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
        -- Extract parameters from XML input
        ---------------------------------------------------

        If _infoLevel >= 3 Then
            -- Use test data
            _statusXML := '<StatusInfo>
                             <Root><Manager><MgrName>TestManager1</MgrName><MgrStatus>Stopped</MgrStatus><LastUpdate>8/20/2009 10:39:21 AM</LastUpdate><LastStartTime>8/20/2009 10:39:20 AM</LastStartTime><CPUUtilization>100.0</CPUUtilization><FreeMemoryMB>490.0</FreeMemoryMB><ProcessID>5555</ProcessID><RecentErrorMessages><ErrMsg>Error 1</ErrMsg><ErrMsg>Error 2</ErrMsg><ErrMsg>Error 3</ErrMsg></RecentErrorMessages></Manager><Task><Tool /><Status>No Task</Status><Duration>0.00</Duration><DurationMinutes>0.0</DurationMinutes><Progress>0.00</Progress><CurrentOperation /><TaskDetails><Status>No Task</Status><Job>0</Job><Step>0</Step><Dataset /><MostRecentLogMessage>Closing manager.</MostRecentLogMessage><MostRecentJobInfo /><SpectrumCount>0</SpectrumCount></TaskDetails></Task></Root>
                             <Root><Manager><MgrName>TestManager1</MgrName><MgrStatus>Running</MgrStatus><LastUpdate>8/20/2009 10:39:31 AM</LastUpdate><LastStartTime>8/20/2009 10:39:20 AM</LastStartTime><CPUUtilization>100.0</CPUUtilization><FreeMemoryMB>490.0</FreeMemoryMB><ProcessID>5555</ProcessID><RecentErrorMessages><ErrMsg>Error 1</ErrMsg><ErrMsg>Error 2</ErrMsg><ErrMsg>Error 3</ErrMsg></RecentErrorMessages></Manager><Task><Tool /><Status>No Task</Status><Duration>0.00</Duration><DurationMinutes>0.0</DurationMinutes><Progress>0.00</Progress><CurrentOperation /><TaskDetails><Status>No Task</Status><Job>0</Job><Step>0</Step><Dataset /><MostRecentLogMessage>Closing manager.</MostRecentLogMessage><MostRecentJobInfo /><SpectrumCount>0</SpectrumCount></TaskDetails></Task></Root>
                             <Root><Manager><MgrName>TestManager2</MgrName><MgrStatus>Running</MgrStatus><LastUpdate>8/20/2009 10:39:35 AM</LastUpdate><LastStartTime>8/20/2009 10:23:11 AM</LastStartTime><CPUUtilization>28.0</CPUUtilization><FreeMemoryMB>402.0</FreeMemoryMB><ProcessID>4444</ProcessID><RecentErrorMessages><ErrMsg>Error 10</ErrMsg></RecentErrorMessages></Manager><Task><Tool>Sequest, Step 3</Tool><Status>Running</Status><Duration>0.27</Duration><DurationMinutes>16.4</DurationMinutes><Progress>8.34</Progress><CurrentOperation /><TaskDetails><Status>Running Tool</Status><Job>525282</Job><Step>3</Step><Dataset>Mcq_CynoLung_norm_11_7Apr08_Phoenix_08-03-01</Dataset><MostRecentLogMessage /><MostRecentJobInfo>Job 525282; Sequest, Step 3; Mcq_CynoLung_norm_11_7Apr08_Phoenix_08-03-01; 8/20/2009 10:23:11 AM</MostRecentJobInfo><SpectrumCount>26897</SpectrumCount></TaskDetails></Task></Root>
                             <Root><Manager><MgrName>TestManager3</MgrName><MgrStatus>Running</MgrStatus><LastUpdate>8/20/2009 10:39:30 AM</LastUpdate><LastStartTime>8/19/2009 10:02:28 PM</LastStartTime><CPUUtilization>14.0</CPUUtilization><FreeMemoryMB>3054.0</FreeMemoryMB><ProcessID>3333</ProcessID><RecentErrorMessages><ErrMsg /></RecentErrorMessages></Manager><Task><Tool>Sequest, Step 3</Tool><Status>Running</Status><Duration>12.62</Duration><DurationMinutes>757.0</DurationMinutes><Progress>74.46</Progress><CurrentOperation /><TaskDetails><Status>Running Tool</Status><Job>525235</Job><Step>3</Step><Dataset>PL-1_pro_B_5Aug09_Owl_09-05-10</Dataset><MostRecentLogMessage /><MostRecentJobInfo>Job 525235; Sequest, Step 3; PL-1_pro_B_5Aug09_Owl_09-05-10; 8/19/2009 10:02:28 PM</MostRecentJobInfo><SpectrumCount>50229</SpectrumCount></TaskDetails></Task></Root>
                             <Root><Manager><MgrName>TestManager4</MgrName><MgrStatus>Stopped</MgrStatus><LastUpdate>8/20/2009 10:39:23 AM</LastUpdate><LastStartTime>8/20/2009 10:39:22 AM</LastStartTime><CPUUtilization>25.0</CPUUtilization><FreeMemoryMB>917.0</FreeMemoryMB><ProcessID>2222</ProcessID><RecentErrorMessages><ErrMsg>8/18/2009 02:44:31, Pub-02-2: No spectra files created, Job 524793, Dataset QC_Shew_09_02-pt5-e_18Aug09_Griffin_09-07-13</ErrMsg></RecentErrorMessages></Manager><Task><Tool /><Status>No Task</Status><Duration>0.00</Duration><DurationMinutes>0.0</DurationMinutes><Progress>0.00</Progress><CurrentOperation /><TaskDetails><Status>No Task</Status><Job>0</Job><Step>0</Step><Dataset /><MostRecentLogMessage>Closing manager.</MostRecentLogMessage><MostRecentJobInfo /><SpectrumCount>0</SpectrumCount></TaskDetails></Task></Root>
                             <Root><Manager><MgrName>TestManager5</MgrName><MgrStatus>Running</MgrStatus><LastUpdate>8/20/2009 10:39:31 AM</LastUpdate><LastStartTime>8/20/2009 10:24:05 AM</LastStartTime><CPUUtilization>30.0</CPUUtilization><FreeMemoryMB>415.0</FreeMemoryMB><ProcessID>1111</ProcessID><RecentErrorMessages><ErrMsg>Error 11</ErrMsg></RecentErrorMessages></Manager><Task><Tool>Sequest, Step 3</Tool><Status>Running</Status><Duration>0.26</Duration><DurationMinutes>15.4</DurationMinutes><Progress>9.88</Progress><CurrentOperation /><TaskDetails><Status>Running Tool</Status><Job>525283</Job><Step>3</Step><Dataset>Mcq_CynoLung_norm_12_7Apr08_Phoenix_08-03-01</Dataset><MostRecentLogMessage /><MostRecentJobInfo>Job 525283; Sequest, Step 3; Mcq_CynoLung_norm_12_7Apr08_Phoenix_08-03-01; 8/20/2009 10:24:05 AM</MostRecentJobInfo><SpectrumCount>27664</SpectrumCount></TaskDetails></Task></Root>
                             <Root><Manager><MgrName>TestManager6</MgrName><MgrStatus>Running</MgrStatus><LastUpdate>8/20/2009 10:39:30 AM</LastUpdate><LastStartTime>8/19/2009 10:24:32 PM</LastStartTime><CPUUtilization>33.0</CPUUtilization><FreeMemoryMB>1133.0</FreeMemoryMB><ProcessID>6666</ProcessID><RecentErrorMessages><ErrMsg /></RecentErrorMessages></Manager><Task><Tool>Sequest, Step 3</Tool><Status>Running</Status><Duration>12.25</Duration><DurationMinutes>735.0</DurationMinutes><Progress>81.81</Progress><CurrentOperation /><TaskDetails><Status>Running Tool</Status><Job>525236</Job><Step>3</Step><Dataset>PL-1_pro_A_5Aug09_Owl_09-05-10</Dataset><MostRecentLogMessage /><MostRecentJobInfo>Job 525236; Sequest, Step 3; PL-1_pro_A_5Aug09_Owl_09-05-10; 8/19/2009 10:24:32 PM</MostRecentJobInfo><SpectrumCount>44321</SpectrumCount></TaskDetails></Task></Root>
                           </StatusInfo>'::XML As StatusXML;
        Else
            -- We must surround the status XML with <StatusInfo></StatusInfo> so that the XML will be rooted, as required by XMLTABLE()
            _statusXML := format('<StatusInfo>%s</StatusInfo>', _managerStatusXML)::XML;
        End If;

        ---------------------------------------------------
        -- Temporary table to hold processor status messages
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_Processor_Status_Info (
            Processor_Name text,
            Mgr_Status text,
            Status_Date text, -- timestamp
            Status_Date_Value timestamp NULL,
            Last_Start_Time text, -- timestamp
            Last_Start_Time_Value timestamp,
            CPU_Utilization text, -- numeric
            Free_Memory_MB text, -- numeric
            Process_ID text, -- int
            Most_Recent_Error_Message text,
            Step_Tool text,
            Task_Status text,
            Duration_Minutes text, -- numeric
            Progress text, -- numeric
            Current_Operation text,
            Task_Detail_Status text,
            Job text, -- int
            Job_Step text, -- int
            Dataset text,
            Most_Recent_Log_Message text,
            Most_Recent_Job_Info text,
            Spectrum_Count text, -- int
            Monitor_Processor boolean,
            Remote_Status_Location text
        );

        CREATE INDEX IX_Tmp_Processor_Status_Info_Processor_Name ON Tmp_Processor_Status_Info (Processor_Name)

        ---------------------------------------------------
        -- Load status messages into temp table
        ---------------------------------------------------

        WITH Src (StatusXML) AS (SELECT _statusXML)
        INSERT INTO Tmp_Processor_Status_Info(
                          Processor_Name,
                          Mgr_Status,
                          Status_Date,
                          Last_Start_Time,
                          CPU_Utilization,
                          Free_Memory_MB,
                          Process_ID,
                          Most_Recent_Error_Message,
                          Step_Tool,
                          Task_Status,
                          Duration_Minutes,
                          Progress,
                          Current_Operation,
                          Task_Detail_Status,
                          Job,
                          Job_Step,
                          Dataset,
                          Most_Recent_Log_Message,
                          Most_Recent_Job_Info,
                          Spectrum_Count,
                          Monitor_Processor,
                          Remote_Status_Location)
        SELECT ManagerInfoQ.Processor_Name, ManagerInfoQ.Mgr_Status, ManagerInfoQ.Status_Date,
               ManagerInfoQ.Last_Start_Time, ManagerInfoQ.CPU_Utilization,
               ManagerInfoQ.Free_Memory_MB, ManagerInfoQ.Process_ID,
               RecentErrorMessageQ.Most_Recent_Error_Message,
               TaskQ.Tool, TaskQ.Task_Status, TaskQ.Duration_Minutes, TaskQ.Progress, TaskQ.Current_Operation,
               TaskDetailQ.Task_Detail_Status, TaskDetailQ.Job, TaskDetailQ.Job_Step, TaskDetailQ.Dataset,
               TaskDetailQ.Most_Recent_Log_Message, TaskDetailQ.Most_Recent_Job_Info, TaskDetailQ.Spectrum_Count,
               true As Monitor_Processor,
               '' As Remote_Status_Location
        FROM ( SELECT xmltable.*
               FROM Src,
                    XMLTABLE('//StatusInfo/Root/Manager'
                              PASSING Src.StatusXML
                              COLUMNS Processor_Name            citext PATH 'MgrName',
                                      Mgr_Status                citext PATH 'MgrStatus',
                                      Status_Date               citext PATH 'LastUpdate',
                                      Last_Start_Time           citext PATH 'LastStartTime',
                                      CPU_Utilization           citext PATH 'CPUUtilization',
                                      Free_Memory_MB            citext PATH 'FreeMemoryMB',
                                      Process_ID                citext PATH 'ProcessID'
                            )
             ) ManagerInfoQ
             LEFT OUTER JOIN
                 ( SELECT xmltable.*
                   FROM Src,
                        XMLTABLE('//StatusInfo/Root/Manager/RecentErrorMessages'
                                 PASSING Src.StatusXML
                                 COLUMNS Processor_Name            citext PATH '../MgrName',
                                         Status_Date               citext PATH '../LastUpdate',
                                         Most_Recent_Error_Message citext PATH 'ErrMsg[1]'      -- If there are multiple recent error messages, only select the first one
                                )
                 ) RecentErrorMessageQ
                 ON ManagerInfoQ.Processor_Name = RecentErrorMessageQ.Processor_Name AND
                    ManagerInfoQ.Status_Date = RecentErrorMessageQ.Status_Date
             LEFT OUTER JOIN
                 ( SELECT xmltable.*
                   FROM Src,
                     XMLTABLE('//StatusInfo/Root/Task'
                              PASSING Src.StatusXML
                              COLUMNS Processor_Name            citext PATH '../Manager/MgrName',
                                      Status_Date               citext PATH '../Manager/LastUpdate',
                                      Step_Tool                 citext PATH 'Tool',
                                      Task_Status               citext PATH 'Status',
                                      Duration_Minutes          citext PATH 'DurationMinutes',
                                      Progress                  citext PATH 'Progress',
                                      Current_Operation         citext PATH 'CurrentOperation'
                             )
                 ) TaskQ
                 ON ManagerInfoQ.Processor_Name = TaskQ.Processor_Name AND
                    ManagerInfoQ.Status_Date = TaskQ.Status_Date
            LEFT OUTER JOIN
                 ( SELECT xmltable.*
                   FROM Src,
                     XMLTABLE('//StatusInfo/Root/Task/TaskDetails'
                              PASSING Src.StatusXML
                              COLUMNS Processor_Name            citext PATH '../../Manager/MgrName',
                                      Status_Date               citext PATH '../../Manager/LastUpdate',
                                      Task_Detail_Status        citext PATH 'Status',
                                      Job                       citext PATH 'Job',
                                      Job_Step                  citext PATH 'Step',
                                      Dataset                   citext PATH 'Dataset',
                                      Most_Recent_Log_Message   citext PATH 'MostRecentLogMessage',
                                      Most_Recent_Job_Info      citext PATH 'MostRecentJobInfo',
                                      Spectrum_Count            citext PATH 'SpectrumCount'
                              )
                 ) TaskDetailQ
                ON ManagerInfoQ.Processor_Name = TaskDetailQ.Processor_Name AND
                   ManagerInfoQ.Status_Date = TaskDetailQ.Status_Date
        ORDER BY ManagerInfoQ.Processor_Name, ManagerInfoQ.Status_Date;
        --
        GET DIAGNOSTICS _statusInfoCount = ROW_COUNT;

        _statusMessageInfo := format('Status info count: %s', _statusInfoCount);

        If _infoLevel > 0 Then

            RAISE INFO '';

            _infoHead := format(_formatSpecifier,
                                'Processor_Name',
                                'Mgr_Status',
                                'Status_Date',
                                'Last_Start_Time',
                                'CPU_%',
                                'Free_Mem_MB',
                                'Process_ID',
                                'Most_Recent_Error',
                                'Step_Tool',
                                'Task_Status',
                                'Duration_Min',
                                'Progress',
                                'Job',
                                'Step',
                                'Dataset'
                            );

            _infoHeadSeparator := format(_formatSpecifier,
                                '---------------',
                                '---------------',
                                '-------------------------',
                                '-------------------------',
                                '-----',
                                '-----------',
                                '----------',
                                '--------------------',
                                '--------------------',
                                '---------------',
                                '---------------',
                                '----------',
                                '----------',
                                '-----',
                                '--------------------------------------------------'
                            );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Processor_Name,
                       Mgr_Status,
                       Status_Date,
                       Last_Start_Time,
                       CPU_Utilization,
                       Free_Memory_MB,
                       Process_ID,
                       Most_Recent_Error_Message,
                       Step_Tool,
                       Task_Status,
                       Duration_Minutes,
                       Progress,
                       Job,
                       Job_Step,
                       Dataset
                FROM Tmp_Processor_Status_Info
                ORDER BY Processor_Name
            LOOP
                _infoData := format(_formatSpecifier,
                                        _previewData.Processor_Name,
                                        _previewData.Mgr_Status,
                                        _previewData.Status_Date,
                                        _previewData.Last_Start_Time,
                                        _previewData.CPU_Utilization,
                                        _previewData.Free_Memory_MB,
                                        _previewData.Process_ID,
                                        _previewData.Most_Recent_Error_Message,
                                        _previewData.Step_Tool,
                                        _previewData.Task_Status,
                                        _previewData.Duration_Minutes,
                                        _previewData.Progress,
                                        _previewData.Job,
                                        _previewData.Job_Step,
                                        _previewData.Dataset
                                );

                RAISE INFO '%', _infoData;

            END LOOP;

        End If;

        If _infoLevel IN (2, 4) Then
            _message := _statusMessageInfo;
            DROP TABLE Tmp_Processor_Status_Info;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Populate columns Status_Date_Value and Last_Start_Time_Value
        -- Note that UTC-based dates will end in Z and must be in the form:
        -- 2017-07-06T08:27:52Z
        ---------------------------------------------------

        -- Old: Compute the difference for our time zone vs. UTC, in hours
        --
        -- SELECT Abs(extract( timezone from CURRENT_TIMESTAMP) / 3600)
        -- INTO _hourOffset;

        -- Convert from text-based UTC date to local timestamp
        --
        UPDATE Tmp_Processor_Status_Info
        SET Status_Date_Value     = public.try_cast(Status_Date,     null::timestamp),
            Last_Start_Time_Value = public.try_cast(Last_Start_Time, null::timestamp);

        ---------------------------------------------------
        -- Update status for existing processors
        ---------------------------------------------------

        UPDATE cap.t_processor_status Target
        SET mgr_status = Src.mgr_status,
            status_date = Status_Date_Value,
            last_start_time = Src.Last_Start_Time_Value,
            cpu_utilization = public.try_cast(Src.cpu_utilization, null::real),
            free_memory_mb = public.try_cast(Src.free_memory_mb, null::real),
            process_id = public.try_cast(Src.process_id, null::int),
            step_tool = Src.step_tool,
            task_status = Src.task_status,
            duration_hours = Coalesce(public.try_cast(Src.Duration_Minutes, null::real) / 60.0, 0),
            progress = Coalesce(public.try_cast(Src.progress, null::real), 0),
            current_operation = Src.current_operation,
            task_detail_status = Src.task_detail_status,
            job = public.try_cast(Src.job, null::int),
            job_step = public.try_cast(Src.job_step, null::int),
            dataset = Src.dataset,
            spectrum_count = public.try_cast(Src.spectrum_count, null::int),
            most_recent_error_message = CASE WHEN Src.most_recent_error_message <> ''
                                        THEN Src.most_recent_error_message
                                        ELSE Target.Most_Recent_Error_Message
                                        END,
            Most_Recent_Log_Message = CASE WHEN Src.Most_Recent_Log_Message <> ''
                                      THEN Src.Most_Recent_Log_Message
                                      ELSE Target.Most_Recent_Log_Message
                                      END,
            Most_Recent_Job_Info = CASE WHEN Src.Most_Recent_Job_Info <> ''
                                   THEN Src.Most_Recent_Job_Info
                                   ELSE Target.Most_Recent_Job_Info
                                   END
        FROM Tmp_Processor_Status_Info Src
        WHERE Src.Processor_Name = Target.Processor_Name;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        _statusMessageInfo := format('%s, Preserved: %s', _statusMessageInfo, _updateCount);

        ---------------------------------------------------
        -- Add missing processors to cap.t_processor_status
        ---------------------------------------------------

        INSERT INTO cap.t_processor_status (
            processor_name,
            mgr_status,
            status_date,
            last_start_time,
            cpu_utilization,
            free_memory_mb,
            process_id,
            most_recent_error_message,
            step_tool,
            task_status,
            duration_hours,
            progress,
            current_operation,
            task_detail_status,
            job,
            job_step,
            dataset,
            most_recent_log_message,
            most_recent_job_info,
            spectrum_count,
            monitor_processor,
            remote_status_location
        )
        SELECT Src.processor_name,
               Src.mgr_status,
               Src.Status_Date_Value,
               Src.Last_Start_Time_Value,
               public.try_cast(Src.cpu_utilization, null::real),
               public.try_cast(Src.free_memory_mb, null::real),
               public.try_cast(Src.process_id, null::int),
               Src.most_recent_error_message,
               Src.step_tool,
               Src.task_status,
               Coalesce(public.try_cast(Src.Duration_Minutes, null::real) / 60.0, 0),
               Coalesce(public.try_cast(Src.progress, null::real), 0),
               Src.current_operation,
               Src.task_detail_status,
               public.try_cast(Src.job, null::int),
               public.try_cast(Src.job_step, null::int),
               Src.dataset,
               Src.most_recent_log_message,
               Src.most_recent_job_info,
               public.try_cast(Src.spectrum_count, null::int),
               CASE WHEN Src.monitor_processor THEN 1 ELSE 0 END,
               Src.remote_status_location
        FROM Tmp_Processor_Status_Info Src
             LEFT OUTER JOIN cap.t_processor_status Target
               ON Src.processor_name = Target.processor_name
        WHERE Target.processor_name IS NULL;
        --
        GET DIAGNOSTICS _insertCount = ROW_COUNT;

        _statusMessageInfo := format('%s, Inserted: %s', _statusMessageInfo, _insertCount);

        If _logProcessorNames Then

            SELECT string_agg(Processor_Name, ', ' ORDER BY Processor_Name)
            INTO _updatedProcessors
            FROM Tmp_Processor_Status_Info;

            _logMessage := format('%s, processors %s', _statusMessageInfo, _updatedProcessors);

            CALL public.post_log_entry ('Debug', _logMessage, 'Update_Capture_Task_Manager_And_Task_Status_XML', 'cap');
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
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;

    If _returnCode = '' Then
        _message := _statusMessageInfo;
    Else
        _message := format('Error storing info, code %s', _returnCode);
    End If;

    DROP TABLE Tmp_Processor_Status_Info;
END
$$;

COMMENT ON PROCEDURE cap.update_capture_task_manager_and_task_status_xml IS 'UpdateManagerAndTaskStatusXML';
