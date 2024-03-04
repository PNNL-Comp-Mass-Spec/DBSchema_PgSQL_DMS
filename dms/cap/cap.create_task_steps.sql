--
-- Name: create_task_steps(text, text, boolean, text, integer, text, integer, integer, boolean, integer, boolean); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.create_task_steps(INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _debugmode boolean DEFAULT false, IN _mode text DEFAULT 'CreateFromImportedJobs'::text, IN _existingjob integer DEFAULT 0, IN _extensionscriptname text DEFAULT ''::text, IN _maxjobstoprocess integer DEFAULT 0, IN _logintervalthreshold integer DEFAULT 15, IN _loggingenabled boolean DEFAULT false, IN _loopingupdateinterval integer DEFAULT 5, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Make entries in the capture task job steps table and the job step dependency table for each newly added capture task job,
**      as defined by the script for that job
**
**  Arguments:
**    _message                  Status message
**    _returnCode               Return code
**    _debugMode                When setting this to true, you can optionally specify a capture task job using _existingJob to view the steps that would be created for that job
**    _mode                     Processing mode; the only supported mode for capture task jobs is 'CreateFromImportedJobs'
**    _existingJob              Only used if _debugMode is true
**    _extensionScriptName      Extension script name
**    _maxJobsToProcess         Maximum number of jobs to process
**    _logIntervalThreshold     If this procedure runs longer than this threshold, status messages will be posted to the log
**    _loggingEnabled           Set to true to immediately enable progress logging; if false, logging will auto-enable if _logIntervalThreshold seconds elapse
**    _loopingUpdateInterval    Seconds between detailed logging while looping through the dependencies,
**    _infoonly                 When true, preview updates
**
**  Auth:   grk
**  Date:   09/02/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          01/14/2010 grk - Removed path ID fields
**          05/25/2011 mem - Updated call to create_steps_for_task
**          04/09/2013 mem - Added additional comments
**          09/24/2014 mem - Rename Job in t_task_step_dependencies
**          05/29/2015 mem - Add support for column Capture_Subfolder
**          09/17/2015 mem - Added parameter _infoOnly
**          05/17/2019 mem - Switch from folder to directory in temp tables
**          10/11/2022 mem - Ported to PostgreSQL
**          11/30/2022 mem - Use clock_timestamp() when determining elapsed runtime
**                         - Skip the current job if the return code from create_steps_for_task() is not an empty string
**                         - Use sw.show_tmp_job_steps_and_job_step_dependencies() and sw.show_tmp_jobs() to display the contents of the temporary tables
**          12/09/2022 mem - Change _mode to lowercase
**          04/02/2023 mem - Rename procedure and functions
**          05/10/2023 mem - Capitalize procedure name sent to post_log_entry
**          05/12/2023 mem - Rename variables and fix bug with misplaced "And"
**          05/30/2023 mem - Use format() for string concatenation
**          06/21/2023 mem - Use Order By when finding tasks with state 0 in cap.t_tasks
**                         - Do not change _mode to lowercase
**          07/11/2023 mem - Use COUNT(job) instead of COUNT(*)
**          08/01/2023 mem - Set _captureTaskJob to true when calling sw.show_tmp_job_steps_and_job_step_dependencies
**          09/07/2023 mem - Align assignment statements
**          09/08/2023 mem - Adjust capitalization of keywords
**          11/01/2023 mem - Add special handling for script 'LCDatasetCapture' to skip step creation when the target dataset does not have an LC instrument defined (bcg)
**          11/02/2023 mem - Delete job parameters from Tmp_Job_Parameters when skipping a capture task job (bcg)
**          03/03/2024 mem - Trim whitespace when extracting values from XML
**
*****************************************************/
DECLARE
    _maxJobsToAdd int;
    _insertCount int;
    _matchCount int;
    _infoMessage text = '';

    _startTime timestamp;
    _lastLogTime timestamp;
    _statusMessage text;
    _jobCountToProcess int;
    _jobsProcessed int;
    _jobInfo record;

    _xmlParameters xml;
    _scriptXML xml;
    _scriptXML2 xml;
    _tag text;
    _instrumentName text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly         := Coalesce(_infoOnly, false);
    _debugMode        := Coalesce(_debugMode, false);
    _existingJob      := Coalesce(_existingJob, 0);
    _mode             := Trim(Coalesce(_mode, ''));
    _maxJobsToProcess := Coalesce(_maxJobsToProcess, 0);

    If _debugMode Then
        RAISE INFO '';
    End If;

    If Not _mode::citext In ('CreateFromImportedJobs') Then
        _message := format('Unknown mode: %s', _mode);
        _returnCode := 'U5201';

        RAISE WARNING '%', _message;
        RETURN;
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

    If _loggingEnabled Or Extract(epoch from clock_timestamp() - _startTime) >= _logIntervalThreshold Then
        _statusMessage := 'Entering';
        CALL public.post_log_entry ('Progress', _statusMessage, 'Create_Task_Steps', 'cap');
    End If;

    If _debugMode And _existingJob <> 0 Then

        If Exists (SELECT job FROM cap.t_task_steps WHERE job = _existingJob) Then
            _message := format('Job %s already has rows in cap.t_task_steps; aborting', _existingJob);
            RAISE WARNING '%', _message;
            RETURN;
        End If;

        If Exists (SELECT job FROM cap.t_task_step_dependencies WHERE job = _existingJob) Then
            _message := format('Job %s already has rows in cap.t_task_step_dependencies; aborting', _existingJob);
            RAISE WARNING '%', _message;
            RETURN;
        End If;

        If Exists (SELECT job FROM cap.t_task_parameters WHERE job = _existingJob) Then
            _message := format('Job %s already has rows in cap.t_task_parameters; aborting', _existingJob);
            RAISE WARNING '%', _message;
            RETURN;
        End If;

    End If;

    ---------------------------------------------------
    -- Create temporary tables to accumulate capture task job steps,
    -- job step dependencies, and job parameters
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Jobs (
        Job int NOT NULL,
        Priority int NULL,
        Script citext NULL,
        State int NOT NULL,
        Dataset citext NULL,
        Dataset_ID int NULL,
        Results_Directory_Name text NULL,
        Storage_Server text NULL,
        Instrument text NULL,
        Instrument_Class text,
        Max_Simultaneous_Captures int NULL,
        Capture_Subdirectory text NULL
    );

    CREATE INDEX IX_Tmp_Jobs_Job ON Tmp_Jobs (Job);

    CREATE TEMP TABLE Tmp_Job_Steps (
        Job int NOT NULL,
        Step int NOT NULL,
        Tool citext NOT NULL,
        CPU_Load int NULL,
        Dependencies int NULL ,
        Filter_Version int NULL,
        Signature int NULL,
        State int NULL ,
        Input_Directory_Name citext NULL,
        Output_Directory_Name citext NULL,
        Processor citext NULL,
        Special_Instructions citext NULL,
        Holdoff_Interval_Minutes int NOT NULL,
        Retry_Count int NOT NULL,
        Next_Try timestamp default CURRENT_TIMESTAMP
    );

    CREATE INDEX IX_Tmp_Job_Steps_Job_Step ON Tmp_Job_Steps (Job, Step);

    CREATE TEMP TABLE Tmp_Job_Step_Dependencies (
        Job int NOT NULL,
        Step int NOT NULL,
        Target_Step int NOT NULL,
        Condition_Test text NULL,
        Test_Value text NULL,
        Enable_Only int NULL
    );

    CREATE INDEX IX_Tmp_Job_Step_Dependencies_Job_Step ON Tmp_Job_Step_Dependencies (Job, Step);

    CREATE TEMP TABLE Tmp_Job_Parameters (
        Job int NOT NULL,
        Parameters xml NULL
    );

    CREATE INDEX IX_Tmp_Job_Parameters_Job ON Tmp_Job_Parameters (Job);

    ---------------------------------------------------
    -- Get capture task jobs that need to be processed
    ---------------------------------------------------

    If _mode::citext = 'CreateFromImportedJobs' Then
        If _maxJobsToProcess > 0 Then
            _maxJobsToAdd := _maxJobsToProcess;
        Else
            _maxJobsToAdd := 1000000;
        End If;

        If Not _debugMode Or (_debugMode And _existingJob = 0) Then
            INSERT INTO Tmp_Jobs (
                Job,
                Priority,
                Script,
                State,
                Dataset,
                Dataset_ID,
                Results_Directory_Name,
                Storage_Server,
                Instrument,
                Instrument_Class,
                Max_Simultaneous_Captures,
                Capture_Subdirectory
            )
            SELECT
                TJ.Job,
                TJ.Priority,
                TJ.Script,
                TJ.State,
                TJ.Dataset,
                TJ.Dataset_ID,
                TJ.Results_Folder_Name AS Results_Directory_Name,
                VDD.Storage_Server_Name,
                VDD.Instrument_Name,
                VDD.Instrument_Class,
                VDD.Max_Simultaneous_Captures,
                VDD.Capture_Subfolder AS Capture_Subdirectory
            FROM cap.t_tasks TJ
                 INNER JOIN cap.V_DMS_Get_Dataset_Definition AS VDD
                   ON TJ.Dataset_ID = VDD.Dataset_ID
            WHERE TJ.State = 0
            ORDER BY TJ.Job
            LIMIT _maxJobsToAdd;
            --
            GET DIAGNOSTICS _insertCount = ROW_COUNT;

            If _infoOnly Then
                If _insertCount = 0 Then
                    If Exists (SELECT job FROM cap.t_tasks WHERE State = 0) Then
                        SELECT COUNT(job)
                        INTO _matchCount
                        FROM cap.t_tasks
                        WHERE State = 0 AND Dataset_ID > 0;

                        _infoMessage := format('%s capture task %s in cap.t_tasks %s State = 0, but the Dataset_ID %s not found in view cap.V_DMS_Get_Dataset_Definition',
                                                _matchCount,
                                                public.check_plural(_matchCount, 'job', 'jobs'),
                                                public.check_plural(_matchCount, 'has', 'have'),
                                                public.check_plural(_matchCount, 'value was', 'values were'));

                        RAISE WARNING '%', _infoMessage;
                    Else
                        _infoMessage := 'No capture task jobs in cap.t_tasks have State = 0';
                        RAISE INFO '%', _infoMessage;
                    End If;
                Else
                    _infoMessage := format('Found %s capture task %s in cap.t_tasks with State = 0',
                                            _insertCount, public.check_plural(_insertCount, 'job', 'jobs'));
                    RAISE INFO '%', _infoMessage;
                End If;
            End If;

        End If;

        If _debugMode And _existingJob <> 0 Then
            INSERT INTO Tmp_Jobs( Job,
                                  Priority,
                                  Script,
                                  State,
                                  Dataset,
                                  Dataset_ID,
                                  Results_Directory_Name )
            SELECT Job,
                   Priority,
                   Script,
                   State,
                   Dataset,
                   Dataset_ID,
                   NULL
            FROM cap.t_tasks
            WHERE Job = _existingJob;

            If Not FOUND Then
                _message := format('Capture task job %s not found in cap.t_tasks; unable to continue debugging', _existingJob);
                _returnCode := 'U5202';

                RAISE WARNING '%', _message;

                DROP TABLE Tmp_Jobs;
                DROP TABLE Tmp_Job_Steps;
                DROP TABLE Tmp_Job_Step_Dependencies;
                DROP TABLE Tmp_Job_Parameters;

                RETURN;
            End If;
        End If;
    End If;

    ---------------------------------------------------
    -- Loop through capture task jobs and process them into temp tables
    ---------------------------------------------------

    SELECT COUNT(job)
    INTO _jobCountToProcess
    FROM Tmp_Jobs;

    _jobsProcessed := 0;
    _lastLogTime := clock_timestamp();

    FOR _jobInfo IN
        SELECT
            Job,
            Dataset,
            Dataset_ID AS DatasetID,
            Script,
            Storage_Server AS StorageServer,
            Instrument,
            Instrument_Class AS InstrumentClass,
            Max_Simultaneous_Captures AS MaxSimultaneousCaptures,
            Capture_Subdirectory AS CaptureSubdirectory,
            Coalesce(Results_Directory_Name, '') AS ResultsDirectoryName
        FROM Tmp_Jobs
        ORDER BY Job
    LOOP

        -- Get contents of script and tag for results directory name
        SELECT contents, results_tag
        INTO _scriptXML, _tag
        FROM cap.t_scripts
        WHERE script = _jobInfo.Script;

        If Not FOUND Then
            _message := format('Script ''%s'' not found in cap.t_scripts for capture task job %s', _jobInfo.Script, _jobInfo.Job);

            CALL public.post_log_entry ('Error', _message, 'Create_Task_Steps', 'cap');

            CONTINUE;
        End If;

        -- Add additional script if extending an existing job
        If _extensionScriptName <> '' Then
            SELECT contents
            INTO _scriptXML2
            FROM cap.t_scripts
            WHERE script = _extensionScriptName::citext;

            _scriptXML := format('%s%s', _scriptXML, _scriptXML2)::xml;
        End If;

        -- Get parameters for the capture task job as XML

        _xmlParameters := cap.create_parameters_for_task (_jobInfo.Job, _jobInfo.Dataset, _jobInfo.DatasetID,
                                                          _jobInfo.Script, _jobInfo.StorageServer,
                                                          _jobInfo.Instrument, _jobInfo.InstrumentClass,
                                                          _jobInfo.MaxSimultaneousCaptures, _jobInfo.CaptureSubdirectory);

        -- Store the parameters
        INSERT INTO Tmp_Job_Parameters (Job, Parameters)
        VALUES (_jobInfo.Job, _xmlParameters);

        -- If the script is 'LCDatasetCapture' and the instrument name is not defined, set the task state to 'Skipped', add a comment, and don't create steps for the task
        If _jobInfo.Script = 'LCDatasetCapture' Then

            -- Examine the XML to extract the value for job parameter "Instrument_Name", for example, 'Agilent_QQQ_04' in :
            -- <Param Section="JobParameters" Name="Instrument_Name" Value="Agilent_QQQ_04" />

            SELECT XmlQ.value
            INTO _instrumentName
            FROM (
                SELECT Trim(xmltable.section) AS section,
                       Trim(xmltable.name)    AS name,
                       Trim(xmltable.value)   AS value
                FROM ( SELECT ('<params>' || _xmlParameters || '</params>')::xml AS rooted_xml
                     ) Src,
                     XMLTABLE('//params/Param'
                              PASSING Src.rooted_xml
                              COLUMNS section text PATH '@Section',
                                      name    text PATH '@Name',
                                      value   text PATH '@Value')
                 ) XmlQ
            WHERE XmlQ.section = 'JobParameters' AND
                  XmlQ.name    = 'Instrument_Name'
            LIMIT 1;

            If Not FOUND Or Trim(Coalesce(_instrumentName, '')) = '' Then
                UPDATE T_Tasks
                SET State   = 15,       -- Skipped
                    Comment = 'No instrument name found matching LC cart name'
                WHERE Job = _jobInfo.Job;

                UPDATE Tmp_Jobs
                SET State = 15
                WHERE Job = _jobInfo.Job;

                DELETE FROM Tmp_Job_Parameters
                WHERE Job = _jobInfo.Job;

                -- Process the next job in Tmp_Jobs
                CONTINUE;
            End If;

        End If;

        -- Create the basic capture task job structure (steps and dependencies)
        -- Details are stored in Tmp_Job_Steps and Tmp_Job_Step_Dependencies

        CALL cap.create_steps_for_task (
                    _jobInfo.Job,
                    _scriptXML,
                    _jobInfo.ResultsDirectoryName,
                    _message    => _message,        -- Output
                    _returnCode => _returnCode,     -- Output
                    _debugMode  => _debugMode);

        If _returnCode <> '' Then
            RAISE WARNING 'Error %: %', _returnCode, _message;
            CONTINUE;
        End If;

        If _debugMode Then
            -- Show contents of Tmp_Job_Steps and Tmp_Job_Step_Dependencies
            CALL sw.show_tmp_job_steps_and_job_step_dependencies(_captureTaskJob => true);
        End If;

        -- Perform a mixed bag of operations on the capture task jobs in the temporary tables to finalize them before
        -- copying to the main database tables

        CALL cap.finish_task_creation (
                     _jobInfo.Job,
                     _message   => _message,    -- Output
                     _debugMode => _debugMode);


        If _jobInfo.Script = 'LCDatasetCapture' Then
            -- Set a default delayed start for LCDatasetCapture steps; we want to give the 'DatasetArchive' task a chance to run before the 'LCDatasetCapture' task starts
            -- This can just be bulk-applied to all steps for this capture task job
            UPDATE Tmp_Job_Steps
            SET Next_Try = CURRENT_TIMESTAMP + INTERVAL '30 minutes'
            WHERE Job = _jobInfo.Job;
        End If;

        _jobsProcessed := _jobsProcessed + 1;

        If Extract(epoch from clock_timestamp() - _lastLogTime) >= _loopingUpdateInterval Then
            -- Make sure _loggingEnabled is true
            _loggingEnabled := true;

            _statusMessage := format('... Creating capture task job steps: %s / %s', _jobsProcessed, _jobCountToProcess);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Create_Task_Steps', 'cap');

            _lastLogTime := clock_timestamp();
        End If;

    END LOOP;

    ---------------------------------------------------
    -- We've got new capture task jobs in temp tables - what to do?
    ---------------------------------------------------

    If _infoOnly Then
        _message := _infoMessage;
    Else
        If _mode::citext = 'CreateFromImportedJobs' Then

            -- Copy data from the following temp tables into actual database tables:
            --     Tmp_Jobs
            --     Tmp_Job_Steps
            --     Tmp_Job_Step_Dependencies
            --     Tmp_Job_Parameters

            CALL cap.move_tasks_to_main_tables (
                        _message    => _message,
                        _returnCode => _returnCode,     -- Output
                        _debugMode  => _debugMode);     -- Output
        End If;
    End If;

    If _loggingEnabled Or Extract(epoch from clock_timestamp() - _startTime) >= _logIntervalThreshold Then
        _loggingEnabled := true;
        _statusMessage := 'Create task steps complete';
        CALL public.post_log_entry ('Progress', _statusMessage, 'Create_Task_Steps', 'cap');
    End If;

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------

    If _loggingEnabled Or Extract(epoch from clock_timestamp() - _startTime) >= _logIntervalThreshold Then
        _statusMessage := 'Exiting';
        CALL public.post_log_entry ('Progress', _statusMessage, 'Create_Task_Steps', 'cap');
    End If;

    If _debugMode Then
        -- Show contents of Tmp_Jobs

        CALL sw.show_tmp_jobs();
    End If;

    DROP TABLE Tmp_Jobs;
    DROP TABLE Tmp_Job_Steps;
    DROP TABLE Tmp_Job_Step_Dependencies;
    DROP TABLE Tmp_Job_Parameters;
END
$$;


ALTER PROCEDURE cap.create_task_steps(INOUT _message text, INOUT _returncode text, IN _debugmode boolean, IN _mode text, IN _existingjob integer, IN _extensionscriptname text, IN _maxjobstoprocess integer, IN _logintervalthreshold integer, IN _loggingenabled boolean, IN _loopingupdateinterval integer, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE create_task_steps(INOUT _message text, INOUT _returncode text, IN _debugmode boolean, IN _mode text, IN _existingjob integer, IN _extensionscriptname text, IN _maxjobstoprocess integer, IN _logintervalthreshold integer, IN _loggingenabled boolean, IN _loopingupdateinterval integer, IN _infoonly boolean); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.create_task_steps(INOUT _message text, INOUT _returncode text, IN _debugmode boolean, IN _mode text, IN _existingjob integer, IN _extensionscriptname text, IN _maxjobstoprocess integer, IN _logintervalthreshold integer, IN _loggingenabled boolean, IN _loopingupdateinterval integer, IN _infoonly boolean) IS 'CreateTaskSteps or CreateJobSteps';

