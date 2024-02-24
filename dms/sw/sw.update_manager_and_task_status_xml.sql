--
-- Name: update_manager_and_task_status_xml(text, integer, boolean, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.update_manager_and_task_status_xml(IN _managerstatusxml text DEFAULT ''::text, IN _infolevel integer DEFAULT 0, IN _logprocessornames boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update processor status in sw.t_processor_status using the concatenated list of XML status messages in _managerStatusXML
**
**  Arguments:
**    _managerStatusXML     Manager status XML
**    _infoLevel            Info level modes:
**                            0: Update sw.t_processor_status
**                            1: View debug messages and update sw.t_processor_status
**                            2: Preview updates
**                            3: Ignore _managerStatusXML, use test XML, and update sw.t_processor_status
**                            4: Ignore _managerStatusXML, use test XML, and preview updates
**    _logProcessorNames    When true, log the names of updated processors (in sw.t_log_entries)
**    _message              Status message
**    _returnCode           Return code
**
**  Example XML in _managerStatusXML
**      <Root><Manager><MgrName>Proto-3_Analysis-1</MgrName><RemoteMgrName /><MgrStatus>Stopped</MgrStatus><!--Local status log time: 2023-08-14 04:14:04 PM--><!--Local last start time: 2023-08-14 04:14:03 PM--><LastUpdate>2023-08-14T23:14:04.210Z</LastUpdate><LastStartTime>2023-08-14T23:14:03.757Z</LastStartTime><CPUUtilization>0.0</CPUUtilization><FreeMemoryMB>43095.9</FreeMemoryMB><ProcessID>9252</ProcessID><ProgRunnerProcessID>0</ProgRunnerProcessID>   <ProgRunnerCoreUsage>0.00</ProgRunnerCoreUsage><RecentErrorMessages><ErrMsg /></RecentErrorMessages></Manager><Task><Tool /><Status>No Task</Status><Duration>0.00</Duration><DurationMinutes>0.0</DurationMinutes><Progress>0.00</Progress><CurrentOperation /><TaskDetails><Status>No Task</Status><Job>0</Job><Step>0</Step><Dataset /><WorkDirPath /><MostRecentLogMessage>Closing manager.</MostRecentLogMessage><MostRecentJobInfo>Job 2211481; Results_Transfer (MASIC_Finnigan); Blank_01_14Aug23_Remus_WBEH-CoAnn-23-07-09; 2023-08-14 12:12:07</MostRecentJobInfo><SpectrumCount>0</SpectrumCount></TaskDetails></Task></Root>
**      <Root><Manager><MgrName>Proto-3_Analysis-2</MgrName><RemoteMgrName /><MgrStatus>Stopped</MgrStatus><!--Local status log time: 2023-08-14 04:14:04 PM--><!--Local last start time: 2023-08-14 04:14:03 PM--><LastUpdate>2023-08-14T23:14:04.414Z</LastUpdate><LastStartTime>2023-08-14T23:14:03.960Z</LastStartTime><CPUUtilization>0.0</CPUUtilization><FreeMemoryMB>43094.6</FreeMemoryMB><ProcessID>9824</ProcessID><ProgRunnerProcessID>0</ProgRunnerProcessID>   <ProgRunnerCoreUsage>0.00</ProgRunnerCoreUsage><RecentErrorMessages><ErrMsg /></RecentErrorMessages></Manager><Task><Tool /><Status>No Task</Status><Duration>0.00</Duration><DurationMinutes>0.0</DurationMinutes><Progress>0.00</Progress><CurrentOperation /><TaskDetails><Status>No Task</Status><Job>0</Job><Step>0</Step><Dataset /><WorkDirPath /><MostRecentLogMessage>Closing manager.</MostRecentLogMessage><MostRecentJobInfo>Job 2211495; Results_Transfer (MASIC_Finnigan); 51920_PhoHet_TMT_01_f17_14Au23_Remus_WBEH-CoAnn-23-07-09; 2023-08-14 15:39:42</MostRecentJobInfo><SpectrumCount>0</SpectrumCount></TaskDetails></Task></Root>
**      <Root><Manager><MgrName>Proto-5_Analysis-1</MgrName><RemoteMgrName /><MgrStatus>Stopped</MgrStatus><!--Local status log time: 2023-08-14 04:14:03 PM--><!--Local last start time: 2023-08-14 04:14:02 PM--><LastUpdate>2023-08-14T23:14:03.570Z</LastUpdate><LastStartTime>2023-08-14T23:14:02.655Z</LastStartTime><CPUUtilization>0.0</CPUUtilization><FreeMemoryMB>13121.9</FreeMemoryMB><ProcessID>3564</ProcessID><ProgRunnerProcessID>0</ProgRunnerProcessID>   <ProgRunnerCoreUsage>0.00</ProgRunnerCoreUsage><RecentErrorMessages><ErrMsg /></RecentErrorMessages></Manager><Task><Tool /><Status>No Task</Status><Duration>0.00</Duration><DurationMinutes>0.0</DurationMinutes><Progress>0.00</Progress><CurrentOperation /><TaskDetails><Status>No Task</Status><Job>0</Job><Step>0</Step><Dataset /><WorkDirPath /><MostRecentLogMessage>Closing manager.</MostRecentLogMessage><MostRecentJobInfo /><SpectrumCount>0</SpectrumCount></TaskDetails></Task></Root>
**      <Root><Manager><MgrName>Pub-12-8</MgrName>          <RemoteMgrName /><MgrStatus>Running</MgrStatus><!--Local status log time: 2023-08-14 04:14:09 PM--><!--Local last start time: 2023-08-14 02:47:06 PM--><LastUpdate>2023-08-14T23:14:09.301Z</LastUpdate><LastStartTime>2023-08-14T21:47:06.964Z</LastStartTime><CPUUtilization>6.0</CPUUtilization><FreeMemoryMB>26660.6</FreeMemoryMB><ProcessID>2444</ProcessID><ProgRunnerProcessID>5724</ProgRunnerProcessID><ProgRunnerCoreUsage>1.01</ProgRunnerCoreUsage><RecentErrorMessages><ErrMsg /></RecentErrorMessages></Manager><Task><Tool>Decon2LS_V2, Step 1</Tool><Status>Running</Status><Duration>1.45</Duration><DurationMinutes>87.0</DurationMinutes><Progress>28.90</Progress><CurrentOperation /><TaskDetails><Status>Running Tool</Status><Job>2211490</Job><Step>1</Step><Dataset>QC_Mam_23_01_R1_14Aug23_Oak_WBEH-CoAnn-23-07-10</Dataset><WorkDirPath>G:\DMS_WorkDir8</WorkDirPath><MostRecentLogMessage /><MostRecentJobInfo>Job 2211490; Decon2LS_V2, Step 1; QC_Mam_23_01_R1_14Aug23_Oak_WBEH-CoAnn-23-07-10; 2023-08-14 02:47:06 PM</MostRecentJobInfo><SpectrumCount>0</SpectrumCount></TaskDetails></Task><ProgRunnerCoreUsage Count="10"><CoreUsageSample Date="2023-08-14 04:09:10 PM">1.0</CoreUsageSample><CoreUsageSample Date="2023-08-14 04:09:41 PM">1.0</CoreUsageSample><CoreUsageSample Date="2023-08-14 04:10:12 PM">1.1</CoreUsageSample><CoreUsageSample Date="2023-08-14 04:10:44 PM">1.0</CoreUsageSample><CoreUsageSample Date="2023-08-14 04:11:15 PM">1.0</CoreUsageSample><CoreUsageSample Date="2023-08-14 04:11:46 PM">1.0</CoreUsageSample><CoreUsageSample Date="2023-08-14 04:12:17 PM">1.0</CoreUsageSample><CoreUsageSample Date="2023-08-14 04:12:48 PM">1.0</CoreUsageSample><CoreUsageSample Date="2023-08-14 04:13:19 PM">1.0</CoreUsageSample><CoreUsageSample Date="2023-08-14 04:13:51 PM">1.0</CoreUsageSample></ProgRunnerCoreUsage></Root>
**
**  Auth:   grk
**  Date:   08/20/2009 grk - Initial release
**          08/29/2009 mem - Now converting Duration_Minutes to Duration_Hours
**                         - Added Try/Catch error handling
**          08/31/2009 mem - Switched to running a bulk Insert and bulk Update instead of a Delete then Bulk Insert
**          05/04/2015 mem - Added Process_ID
**          11/20/2015 mem - Added Prog_Runner_Process_ID and Prog_Runner_Core_Usage
**                         - Added parameter _debugMode
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/22/2017 mem - Replace Remote_Status_Location with Remote_Manager
**          05/23/2017 mem - Update fewer status fields if Remote_Manager is not empty
**                         - Change _debugMode to recognize various values
**          06/15/2017 mem - Use Cast and Try_Cast
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          07/06/2017 mem - Allow Status_Date and Last_Start_Time to be UTC-based
**                           Use Try_Cast to convert from varchar to numbers
**          08/01/2017 mem - Use THROW if not authorized
**          09/19/2018 mem - Add parameter _logProcessorNames
**          08/14/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**          09/11/2023 mem - Use schema name with try_cast
**          09/29/2023 mem - Keep track of the current location in the procedure
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _currentLocation text := 'Start';
    _statusInfoCount int;
    _updateCount int;
    _insertCount int;
    _statusMessageInfo text := '';
    _statusXML xml;
    _updatedProcessors text;
    _logMessage text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

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
        -- Validate the inputs
        ---------------------------------------------------

        _statusXML         := public.try_cast(_managerStatusXML, null::xml);
        _infoLevel         := Coalesce(_infoLevel, 0);
        _logProcessorNames := Coalesce(_logProcessorNames, false);

        ---------------------------------------------------
        -- Extract parameters from XML input
        ---------------------------------------------------

        _currentLocation := 'Store _managerStatusXML in _paramXML';

        If _infoLevel >= 3 Then
            RAISE INFO '';
            RAISE INFO 'Overriding XML in _statusXML using Test Data';

            _statusXML := '<StatusInfo>
                             <Root><Manager><MgrName>TestManager1</MgrName><RemoteMgrName /><MgrStatus>Stopped</MgrStatus><!--Local status log time: 2023-08-14 04:14:04 PM--><!--Local last start time: 2023-08-14 04:14:03 PM--><LastUpdate>2023-08-14T23:14:04.210Z</LastUpdate><LastStartTime>2023-08-14T23:14:03.757Z</LastStartTime><CPUUtilization>0.0</CPUUtilization><FreeMemoryMB>43095.9</FreeMemoryMB><ProcessID>9252</ProcessID><ProgRunnerProcessID>0</ProgRunnerProcessID><ProgRunnerCoreUsage>0.00</ProgRunnerCoreUsage><RecentErrorMessages><ErrMsg /></RecentErrorMessages></Manager><Task><Tool /><Status>No Task</Status><Duration>0.00</Duration><DurationMinutes>0.0</DurationMinutes><Progress>0.00</Progress><CurrentOperation /><TaskDetails><Status>No Task</Status><Job>0</Job><Step>0</Step><Dataset /><WorkDirPath /><MostRecentLogMessage>Closing manager.</MostRecentLogMessage><MostRecentJobInfo>Job 2211481; Results_Transfer (MASIC_Finnigan); Blank_01_14Aug23_Remus_WBEH-CoAnn-23-07-09; 2023-08-14 12:12:07</MostRecentJobInfo><SpectrumCount>0</SpectrumCount></TaskDetails></Task></Root>
                             <Root><Manager><MgrName>TestManager2</MgrName><RemoteMgrName /><MgrStatus>Stopped</MgrStatus><!--Local status log time: 2023-08-14 04:14:04 PM--><!--Local last start time: 2023-08-14 04:14:03 PM--><LastUpdate>2023-08-14T23:14:04.414Z</LastUpdate><LastStartTime>2023-08-14T23:14:03.960Z</LastStartTime><CPUUtilization>0.0</CPUUtilization><FreeMemoryMB>43094.6</FreeMemoryMB><ProcessID>9824</ProcessID><ProgRunnerProcessID>0</ProgRunnerProcessID><ProgRunnerCoreUsage>0.00</ProgRunnerCoreUsage><RecentErrorMessages><ErrMsg /></RecentErrorMessages></Manager><Task><Tool /><Status>No Task</Status><Duration>0.00</Duration><DurationMinutes>0.0</DurationMinutes><Progress>0.00</Progress><CurrentOperation /><TaskDetails><Status>No Task</Status><Job>0</Job><Step>0</Step><Dataset /><WorkDirPath /><MostRecentLogMessage>Closing manager.</MostRecentLogMessage><MostRecentJobInfo>Job 2211495; Results_Transfer (MASIC_Finnigan); 51920_PhoHet_TMT_01_f17_14Au23_Remus_WBEH-CoAnn-23-07-09; 2023-08-14 15:39:42</MostRecentJobInfo><SpectrumCount>0</SpectrumCount></TaskDetails></Task></Root>
                             <Root><Manager><MgrName>TestManager3</MgrName><RemoteMgrName /><MgrStatus>Stopped</MgrStatus><!--Local status log time: 2023-08-14 04:14:03 PM--><!--Local last start time: 2023-08-14 04:14:02 PM--><LastUpdate>2023-08-14T23:14:03.570Z</LastUpdate><LastStartTime>2023-08-14T23:14:02.655Z</LastStartTime><CPUUtilization>0.0</CPUUtilization><FreeMemoryMB>13121.9</FreeMemoryMB><ProcessID>3564</ProcessID><ProgRunnerProcessID>0</ProgRunnerProcessID><ProgRunnerCoreUsage>0.00</ProgRunnerCoreUsage><RecentErrorMessages><ErrMsg /></RecentErrorMessages></Manager><Task><Tool /><Status>No Task</Status><Duration>0.00</Duration><DurationMinutes>0.0</DurationMinutes><Progress>0.00</Progress><CurrentOperation /><TaskDetails><Status>No Task</Status><Job>0</Job><Step>0</Step><Dataset /><WorkDirPath /><MostRecentLogMessage>Closing manager.</MostRecentLogMessage><MostRecentJobInfo /><SpectrumCount>0</SpectrumCount></TaskDetails></Task></Root>
                             <Root><Manager><MgrName>TestManager4</MgrName><RemoteMgrName /><MgrStatus>Running</MgrStatus><!--Local status log time: 2023-08-14 04:14:09 PM--><!--Local last start time: 2023-08-14 02:47:06 PM--><LastUpdate>2023-08-14T23:14:09.301Z</LastUpdate><LastStartTime>2023-08-14T21:47:06.964Z</LastStartTime><CPUUtilization>6.0</CPUUtilization><FreeMemoryMB>26660.6</FreeMemoryMB><ProcessID>2444</ProcessID><ProgRunnerProcessID>5724</ProgRunnerProcessID><ProgRunnerCoreUsage>1.01</ProgRunnerCoreUsage><RecentErrorMessages><ErrMsg /></RecentErrorMessages></Manager><Task><Tool>Decon2LS_V2, Step 1</Tool><Status>Running</Status><Duration>1.45</Duration><DurationMinutes>87.0</DurationMinutes><Progress>28.90</Progress><CurrentOperation /><TaskDetails><Status>Running Tool</Status><Job>2211490</Job><Step>1</Step><Dataset>QC_Mam_23_01_R1_14Aug23_Oak_WBEH-CoAnn-23-07-10</Dataset><WorkDirPath>G:\DMS_WorkDir8</WorkDirPath><MostRecentLogMessage /><MostRecentJobInfo>Job 2211490; Decon2LS_V2, Step 1; QC_Mam_23_01_R1_14Aug23_Oak_WBEH-CoAnn-23-07-10; 2023-08-14 02:47:06 PM</MostRecentJobInfo><SpectrumCount>0</SpectrumCount></TaskDetails></Task><ProgRunnerCoreUsage Count="10"><CoreUsageSample Date="2023-08-14 04:09:10 PM">1.0</CoreUsageSample><CoreUsageSample Date="2023-08-14 04:09:41 PM">1.0</CoreUsageSample><CoreUsageSample Date="2023-08-14 04:10:12 PM">1.1</CoreUsageSample><CoreUsageSample Date="2023-08-14 04:10:44 PM">1.0</CoreUsageSample><CoreUsageSample Date="2023-08-14 04:11:15 PM">1.0</CoreUsageSample><CoreUsageSample Date="2023-08-14 04:11:46 PM">1.0</CoreUsageSample><CoreUsageSample Date="2023-08-14 04:12:17 PM">1.0</CoreUsageSample><CoreUsageSample Date="2023-08-14 04:12:48 PM">1.0</CoreUsageSample><CoreUsageSample Date="2023-08-14 04:13:19 PM">1.0</CoreUsageSample><CoreUsageSample Date="2023-08-14 04:13:51 PM">1.0</CoreUsageSample></ProgRunnerCoreUsage></Root>
                             <Root><Manager><MgrName>TestManager5</MgrName><RemoteMgrName>PrismWeb2</RemoteMgrName><MgrStatus>Running</MgrStatus><LastUpdate>5/20/2017 8:52:30 AM</LastUpdate><LastStartTime>5/20/2017 9:32:30 AM</LastStartTime><CPUUtilization>53.0</CPUUtilization><FreeMemoryMB>11323.0</FreeMemoryMB><ProcessID>436</ProcessID><ProgRunnerProcessID>3030</ProgRunnerProcessID><ProgRunnerCoreUsage>12</ProgRunnerCoreUsage><RecentErrorMessages><ErrMsg /></RecentErrorMessages></Manager><Task><Tool>MSGFPlus, Step 3</Tool><Status>Running</Status><Duration>1.5</Duration><DurationMinutes>90.0</DurationMinutes><Progress>23</Progress><CurrentOperation /><TaskDetails><Status>Running Tool</Status><Job>1451054</Job><Step>3</Step><Dataset>QC_Mam_16_01_pt7_B5c_10May17_Bane_REP-16-02-02</Dataset><MostRecentLogMessage /><MostRecentJobInfo>Job 1451054; MSGFPlus, Step 3; QC_Mam_16_01_pt7_B5c_10May17_Bane_REP-16-02-02; 5/22/2017 8:00:00 AM</MostRecentJobInfo><SpectrumCount>31221</SpectrumCount></TaskDetails></Task></Root>
                           </StatusInfo>'::XML AS StatusXML;
        Else
            -- We must surround the status XML with <StatusInfo></StatusInfo> so that the XML will be rooted, as required by XMLTABLE()
            _statusXML := format('<StatusInfo>%s</StatusInfo>', _managerStatusXML)::XML;
        End If;

        ---------------------------------------------------
        -- Temporary table to hold processor status messages
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_Processor_Status_Info (
            Processor_Name text,
            Remote_Manager text,
            Mgr_Status text,
            Status_Date text,               -- timestamp
            Status_Date_Value timestamp NULL,
            Last_Start_Time text,           -- timestamp
            Last_Start_Time_Value timestamp,
            CPU_Utilization text,           -- real
            Free_Memory_MB text,            -- real
            Process_ID text,                -- int
            Prog_Runner_Process_ID text,    -- int
            Prog_Runner_Core_Usage text,    -- real
            Most_Recent_Error_Message text,
            Step_Tool text,
            Task_Status text,
            Duration_Minutes text,          -- real
            Progress text,                  -- real
            Current_Operation text,
            Task_Detail_Status text,
            Job text,                       -- int
            Job_Step text,                  -- int
            Dataset text,
            Most_Recent_Log_Message text,
            Most_Recent_Job_Info text,
            Spectrum_Count text,            -- int
            IsNew boolean
        );

        CREATE INDEX IX_Tmp_Processor_Status_Info_Processor_Name ON Tmp_Processor_Status_Info (Processor_Name);

        ---------------------------------------------------
        -- Load status messages into temp table
        ---------------------------------------------------

        _currentLocation := 'Populate temp table Tmp_Processor_Status_Info';

        WITH Src (StatusXML) AS (SELECT _statusXML)
        INSERT INTO Tmp_Processor_Status_Info( Processor_Name,
                                               Remote_Manager,
                                               Mgr_Status,
                                               Status_Date,
                                               Last_Start_Time,
                                               CPU_Utilization,
                                               Free_Memory_MB,
                                               Process_ID,
                                               Prog_Runner_Process_ID,
                                               Prog_Runner_Core_Usage,
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
                                               IsNew )
        SELECT ManagerInfoQ.Processor_Name, ManagerInfoQ.Remote_Manager, ManagerInfoQ.Mgr_Status, ManagerInfoQ.Status_Date,
               ManagerInfoQ.Last_Start_Time, ManagerInfoQ.CPU_Utilization,
               ManagerInfoQ.Free_Memory_MB, ManagerInfoQ.Process_ID,
               ManagerInfoQ.Prog_Runner_Process_ID, ManagerInfoQ.Prog_Runner_Core_Usage,
               RecentErrorMessageQ.Most_Recent_Error_Message,
               TaskQ.Step_Tool, TaskQ.Task_Status, TaskQ.Duration_Minutes, TaskQ.Progress, TaskQ.Current_Operation,
               TaskDetailQ.Task_Detail_Status, TaskDetailQ.Job, TaskDetailQ.Job_Step, TaskDetailQ.Dataset,
               TaskDetailQ.Most_Recent_Log_Message, TaskDetailQ.Most_Recent_Job_Info, TaskDetailQ.Spectrum_Count,
               true AS IsNew
        FROM ( SELECT xmltable.*
               FROM Src,
                    XMLTABLE('//StatusInfo/Root/Manager'
                              PASSING Src.StatusXML
                              COLUMNS Processor_Name            citext PATH 'MgrName',
                                      Remote_Manager            citext PATH 'RemoteMgrName',
                                      Mgr_Status                citext PATH 'MgrStatus',
                                      Status_Date               citext PATH 'LastUpdate',
                                      Last_Start_Time           citext PATH 'LastStartTime',
                                      CPU_Utilization           citext PATH 'CPUUtilization',
                                      Free_Memory_MB            citext PATH 'FreeMemoryMB',
                                      Process_ID                citext PATH 'ProcessID',
                                      Prog_Runner_Process_ID    citext PATH 'ProgRunnerProcessID',
                                      Prog_Runner_Core_Usage    citext PATH 'ProgRunnerCoreUsage'
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

        -- Make sure Remote_Manager is defined

        UPDATE Tmp_Processor_Status_Info
        SET Remote_Manager = ''
        WHERE Remote_Manager IS NULL;

        -- Change the IsNew flag to false for known processors

        UPDATE Tmp_Processor_Status_Info
        SET IsNew = false
        FROM sw.t_processor_status PS
        WHERE PS.processor_name = Tmp_Processor_Status_Info.processor_name;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        _statusMessageInfo := format('Status info count: %s', _updateCount);

        If _infoLevel > 0 Then

            RAISE INFO '';

            _formatSpecifier := '%-20s %-15s %-15s %-25s %-25s %-5s %-11s %-10s %-22s %-22s %-17s %-30s %-15s %-15s %-9s %-50s %-25s %-10s %-5s %-80s';

            _infoHead := format(_formatSpecifier,
                                'Processor_Name',
                                'Remote_Manager',
                                'Mgr_Status',
                                'Status_Date',
                                'Last_Start_Time',
                                'CPU_%',
                                'Free_Mem_MB',
                                'Process_ID',
                                'Prog_Runner_Process_ID',
                                'Prog_Runner_Core_Usage',
                                'Most_Recent_Error',
                                'Step_Tool',
                                'Task_Status',
                                'Duration_Min',
                                'Progress',
                                'Current_Operation',
                                'Task_Detail_Status',
                                'Job',
                                'Step',
                                'Dataset'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '--------------------',
                                         '---------------',
                                         '---------------',
                                         '-------------------------',
                                         '-------------------------',
                                         '-----',
                                         '-----------',
                                         '----------',
                                         '----------------------',
                                         '----------------------',
                                         '-----------------',
                                         '------------------------------',
                                         '---------------',
                                         '---------------',
                                         '---------',
                                         '--------------------------------------------------',
                                         '-------------------------',
                                         '----------',
                                         '-----',
                                         '--------------------------------------------------------------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Processor_Name,
                       Remote_Manager,
                       Mgr_Status,
                       Status_Date,         -- Text-based date/time (from _managerStatusXML)
                       Last_Start_Time,     -- Text-based date/time (from _managerStatusXML)
                       CPU_Utilization,
                       Free_Memory_MB,
                       Process_ID,
                       Prog_Runner_Process_ID,
                       Prog_Runner_Core_Usage,
                       Most_Recent_Error_Message,
                       Step_Tool,
                       Task_Status,
                       Duration_Minutes,
                       Progress,
                       Current_Operation,
                       Task_Detail_Status,
                       Job,
                       Job_Step,
                       Dataset
                FROM Tmp_Processor_Status_Info
                ORDER BY Processor_Name
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Processor_Name,
                                    _previewData.Remote_Manager,
                                    _previewData.Mgr_Status,
                                    _previewData.Status_Date,
                                    _previewData.Last_Start_Time,
                                    _previewData.CPU_Utilization,
                                    _previewData.Free_Memory_MB,
                                    _previewData.Process_ID,
                                    _previewData.Prog_Runner_Process_ID,
                                    _previewData.Prog_Runner_Core_Usage,
                                    _previewData.Most_Recent_Error_Message,
                                    _previewData.Step_Tool,
                                    _previewData.Task_Status,
                                    _previewData.Duration_Minutes,
                                    _previewData.Progress,
                                    _previewData.Current_Operation,
                                    _previewData.Task_Detail_Status,
                                    _previewData.Job,
                                    _previewData.Job_Step,
                                    _previewData.Dataset
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

        If _infoLevel = 2 Or _infoLevel >= 4 Then
            _message := _statusMessageInfo;
            RAISE INFO '%', _message;

            DROP TABLE Tmp_Processor_Status_Info;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Populate columns Status_Date_Value and Last_Start_Time_Value
        -- Note that UTC-based dates will end in Z and must be in the form:
        -- 2017-07-06T08:27:52Z
        ---------------------------------------------------

        _currentLocation := 'Populate columns Status_Date_Value and Last_Start_Time_Value';

        -- Old: Compute the difference for our time zone vs. UTC, in hours
        --
        -- SELECT Abs(Extract(timezone from CURRENT_TIMESTAMP) / 3600)
        -- INTO _hourOffset;

        -- Convert from text-based UTC date to local timestamp

        UPDATE Tmp_Processor_Status_Info
        SET Status_Date_Value     = public.try_cast(Status_Date,     null::timestamp),
            Last_Start_Time_Value = public.try_cast(Last_Start_Time, null::timestamp);

        ---------------------------------------------------
        -- Update status for existing processors
        ---------------------------------------------------

        _currentLocation := 'Update status for existing processors that have Remote_Manager defined';

        -- First update managers with a Remote_Manager defined

        UPDATE sw.t_processor_status Target
        SET remote_manager = Src.remote_manager,
            mgr_status = Src.mgr_status,
            status_date = Src.Status_Date_Value,
            step_tool = Src.step_tool,
            task_status = Src.task_status,
            current_operation = Src.current_operation,
            task_detail_status = Src.task_detail_status,
            job = public.try_cast(Src.job, null::int),
            job_step = public.try_cast(Src.job_step, null::int),
            dataset = Src.dataset,
            spectrum_count = public.try_cast(Src.spectrum_count, null::int)
        FROM Tmp_Processor_Status_Info Src
        WHERE Src.Processor_Name = Target.Processor_Name AND Src.Remote_Manager <> '';
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        _statusMessageInfo := format('%s, PreservedA: %s', _statusMessageInfo, _updateCount);

        _currentLocation := 'Update status for existing processors that do not contact a remote manager';

        -- Next update managers where Remote_Manager is empty

        UPDATE sw.t_processor_status Target
        SET remote_manager = Src.remote_manager,
            mgr_status = Src.mgr_status,
            status_date = Src.Status_Date_Value,
            last_start_time = Src.Last_Start_Time_Value,
            cpu_utilization = public.try_cast(Src.cpu_utilization, null::real),
            free_memory_mb = public.try_cast(Src.free_memory_mb, null::real),
            process_id = public.try_cast(Src.process_id, null::int),
            prog_runner_process_id = public.try_cast(Src.prog_runner_process_id, null::int),
            prog_runner_core_usage = public.try_cast(Src.prog_runner_core_usage, null::real),
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
        WHERE Src.Processor_Name = Target.Processor_Name AND Src.Remote_Manager = '';
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        _statusMessageInfo := format('%s, PreservedB: %s', _statusMessageInfo, _updateCount);

        ---------------------------------------------------
        -- Add missing processors to sw.t_processor_status
        ---------------------------------------------------

        _currentLocation := 'Add missing processors';

        -- Add managers with a Remote_Manager defined

        INSERT INTO sw.t_processor_status (
            processor_name,
            remote_manager,
            mgr_status,
            status_date,
            step_tool,
            task_status,
            current_operation,
            task_detail_status,
            job,
            job_step,
            dataset,
            spectrum_count,
            monitor_processor
        )
        SELECT Src.processor_name,
            Src.remote_manager,
            Src.mgr_status,
            Src.Status_Date_Value,
            Src.step_tool,
            Src.task_status,
            Src.current_operation,
            Src.task_detail_status,
            public.try_cast(Src.job, null::int),
            public.try_cast(Src.job_step, null::int),
            Src.dataset,
            public.try_cast(Src.spectrum_count, null::int),
            1 AS Monitor_Processor
        FROM sw.t_processor_status Target
            INNER JOIN Tmp_Processor_Status_Info Src
                ON Src.processor_name = Target.processor_name
        WHERE Src.IsNew AND Src.remote_manager <> '' AND Target.processor_name IS NULL;
        --
        GET DIAGNOSTICS _insertCount = ROW_COUNT;

        _statusMessageInfo := format('%s, InsertedA: %s', _statusMessageInfo, _insertCount);

        -- Add managers where Remote_Manager is empty

        INSERT INTO sw.t_processor_status (
            processor_name,
            remote_manager,
            mgr_status,
            status_date,
            last_start_time,
            cpu_utilization,
            free_memory_mb,
            process_id,
            prog_runner_process_id,
            prog_runner_core_usage,
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
            monitor_processor
        )
        SELECT Src.processor_name,
            Src.remote_manager,
            Src.mgr_status,
            Src.Status_Date_Value,
            Src.Last_Start_Time_Value,
            public.try_cast(Src.cpu_utilization, null::real),
            public.try_cast(Src.free_memory_mb, null::real),
            public.try_cast(Src.process_id, null::int),
            public.try_cast(Src.prog_runner_process_id, null::int),
            public.try_cast(Src.prog_runner_core_usage, null::real),
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
            1 AS Monitor_Processor
        FROM Tmp_Processor_Status_Info Src
            LEFT OUTER JOIN sw.t_processor_status Target
            ON Src.processor_name = Target.processor_name
        WHERE Src.IsNew AND Src.remote_manager = '' AND Target.processor_name IS NULL;
        --
        GET DIAGNOSTICS _insertCount = ROW_COUNT;

        _statusMessageInfo := format('%s, InsertedB: %s', _statusMessageInfo, _insertCount);

        If _logProcessorNames Then

            _currentLocation := 'Log status messages';

            SELECT string_agg(Processor_Name, ', ' ORDER BY Processor_Name)
            INTO _updatedProcessors
            FROM Tmp_Processor_Status_Info;

            _logMessage := format('%s; Processors: %s', _statusMessageInfo, _updatedProcessors);

            CALL public.post_log_entry ('Debug', _logMessage, 'Update_Manager_And_Task_Status_XML', 'sw');
        End If;

        _message := _statusMessageInfo;

        DROP TABLE Tmp_Processor_Status_Info;
        RETURN;

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

        If _infoLevel > 1 Then
            RAISE WARNING '%', _message;
        End If;
    END;

    _message := format('Error storing info, code %s', _returnCode);

    DROP TABLE IF EXISTS Tmp_Processor_Status_Info;
END
$$;


ALTER PROCEDURE sw.update_manager_and_task_status_xml(IN _managerstatusxml text, IN _infolevel integer, IN _logprocessornames boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_manager_and_task_status_xml(IN _managerstatusxml text, IN _infolevel integer, IN _logprocessornames boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.update_manager_and_task_status_xml(IN _managerstatusxml text, IN _infolevel integer, IN _logprocessornames boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateManagerAndTaskStatusXML';

