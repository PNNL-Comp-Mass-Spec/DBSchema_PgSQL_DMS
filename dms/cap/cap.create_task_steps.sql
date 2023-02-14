--
-- Name: create_task_steps(text, boolean, text, integer, text, integer, integer, boolean, integer, boolean, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.create_task_steps(INOUT _message text DEFAULT ''::text, IN _debugmode boolean DEFAULT false, IN _mode text DEFAULT 'CreateFromImportedJobs'::text, IN _existingjob integer DEFAULT 0, IN _extensionscriptname text DEFAULT ''::text, IN _maxjobstoprocess integer DEFAULT 0, IN _logintervalthreshold integer DEFAULT 15, IN _loggingenabled boolean DEFAULT false, IN _loopingupdateinterval integer DEFAULT 5, IN _infoonly boolean DEFAULT false, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Make entries in the capture task job steps table and the
**      job step dependency table for each newly added capture task job,
**      as defined by the script for that job
**
**  Arguments:
**    _debugMode               When setting this to true, you can optionally specify a capture task job using _existingJob to view the steps that would be created for that job
**    _mode                    Processing mode; the only supported mode for capture task jobs is 'CreateFromImportedJobs'
**    _existingJob             Only used if _debugMode is true
**    _logIntervalThreshold    If this procedure runs longer than this threshold, status messages will be posted to the log
**    _loggingEnabled          Set to true to immediately enable progress logging; if false, logging will auto-enable if _logIntervalThreshold seconds elapse
**    _loopingUpdateInterval   Seconds between detailed logging while looping through the dependencies,
**
**  Auth:   grk
**  Date:   09/02/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          01/14/2010 grk - Removed path ID fields
**          05/25/2011 mem - Updated call to create_steps_for_job
**          04/09/2013 mem - Added additional comments
**          09/24/2014 mem - Rename Job in t_task_step_dependencies
**          05/29/2015 mem - Add support for column Capture_Subfolder
**          09/17/2015 mem - Added parameter _infoOnly
**          05/17/2019 mem - Switch from folder to directory in temp tables
**          10/11/2022 mem - Ported to PostgreSQL
**          11/30/2022 mem - Use clock_timestamp() when determining elapsed runtime
**                         - Skip the current job if the return code from create_steps_for_job() is not an empty string
**                         - Use sw.show_tmp_job_steps_and_job_step_dependencies() and sw.show_tmp_jobs() to display the contents of the temporary tables
**          12/09/2022 mem - Change _mode to lowercase
**
*****************************************************/
DECLARE
    _maxJobsToAdd int;
    _myRowCount int;
    _infoMessage text = '';

    _startTime timestamp;
    _lastLogTime timestamp;
    _statusMessage text;
    _jobCountToProcess int;
    _jobsProcessed int;
    _jobInfo record;

    _xmlParameters xml;
    _scriptXML xml;
    _tag text;
    _scriptXML2 xml;
BEGIN

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --
    _message := '';
    _returnCode := '';

    _infoOnly := Coalesce(_infoOnly, false);
    _debugMode := Coalesce(_debugMode, false);
    _existingJob := Coalesce(_existingJob, 0);
    _mode := Trim(Lower(Coalesce(_mode, '')));
    _maxJobsToProcess := Coalesce(_maxJobsToProcess, 0);

    If _debugMode Then
        RAISE INFO ' ';
    End If;

    If Not _mode::citext In ('CreateFromImportedJobs') Then
        _message := 'Unknown mode: ' || _mode;
        _returnCode := 'U5201';

        RAISE WARNING '%', _message;
        RETURN;
    End If;

    _startTime := CURRENT_TIMESTAMP;
    _loggingEnabled := Coalesce(_loggingEnabled, false);
    _logIntervalThreshold := Coalesce(_logIntervalThreshold, 15);
    _loopingUpdateInterval := Coalesce(_loopingUpdateInterval, 5);

    If _logIntervalThreshold = 0 Then
        _loggingEnabled := true;
    End If;

    If _loopingUpdateInterval < 2 Then
        _loopingUpdateInterval := 2;
    End If;

    If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
        _statusMessage := 'Entering';
        Call public.post_log_entry ('Progress', _statusMessage, 'create_task_steps', 'cap');
    End If;

    If _debugMode And _existingJob <> 0 Then

        If Exists (SELECT * FROM cap.t_task_steps WHERE job = _existingJob) Then
            _message := format('Job %s already has rows in cap.t_task_steps; aborting', _existingJob);
            RAISE WARNING '%', _message;
            RETURN;
        End If;

        If Exists (SELECT * FROM cap.t_task_step_dependencies WHERE job = _existingJob) Then
            _message := format('Job %s already has rows in cap.t_task_step_dependencies; aborting', _existingJob);
            RAISE WARNING '%', _message;
            RETURN;
        End If;

        If Exists (SELECT * FROM cap.t_task_parameters WHERE job = _existingJob) Then
            _message := format('Job %s already has rows in cap.t_task_parameters; aborting', _existingJob);
            RAISE WARNING '%', _message;
            RETURN;
        End If;

    End If;

    ---------------------------------------------------
    -- Create temporary tables to accumulate capture task job steps,
    -- job step dependencies, and job parameters
    ---------------------------------------------------
    --
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
        Step_Tool citext NOT NULL,
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
        Retry_Count int NOT NULL
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
    --
    If _mode::citext = 'CreateFromImportedJobs' Then
        If _maxJobsToProcess > 0 Then
            _maxJobsToAdd := _maxJobsToProcess;
        Else
            _maxJobsToAdd := 1000000;
        End If;

        If Not _debugMode OR (_debugMode And _existingJob = 0) Then
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
                TJ.Results_Folder_Name As Results_Directory_Name,
                VDD.Storage_Server_Name,
                VDD.Instrument_Name,
                VDD.Instrument_Class,
                VDD.Max_Simultaneous_Captures,
                VDD.Capture_Subfolder As Capture_Subdirectory
            FROM
                cap.t_tasks TJ
                INNER JOIN cap.V_DMS_Get_Dataset_Definition AS VDD ON TJ.Dataset_ID = VDD.Dataset_ID
            WHERE TJ.State = 0
            LIMIT _maxJobsToAdd;
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _infoOnly And Then
                If _myRowCount = 0 Then
                    If Exists (SELECT * FROM cap.t_tasks WHERE State = 0) Then
                        SELECT COUNT(*)
                        INTO _myRowCount
                        FROM cap.t_tasks
                        WHERE State = 0 And Dataset_ID > 0;

                        _infoMessage := format('%s capture task %s in cap.t_tasks %s State = 0, but the Dataset_ID %s not found in view cap.V_DMS_Get_Dataset_Definition',
                                                _myRowCount,
                                                public.check_plural(_myRowCount, 'job', 'jobs'),
                                                public.check_plural(_myRowCount, 'has', 'have'),
                                                public.check_plural(_myRowCount, 'value was', 'values were'));

                        RAISE WARNING '%', _infoMessage;
                    Else
                        _infoMessage := 'No capture task jobs in cap.t_tasks has State = 0';
                        RAISE INFO '%', _infoMessage;
                    End If;
                Else
                    _infoMessage := format('Found %s capture task %s in cap.t_tasks with State = 0',
                                            _myRowCount, public.check_plural(_myRowCount, 'job', 'jobs'));
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
    --
    SELECT COUNT(*)
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
            Storage_Server As StorageServer,
            Instrument,
            Instrument_Class as InstrumentClass,
            Max_Simultaneous_Captures As MaxSimultaneousCaptures,
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

            Call public.post_log_entry ('Error', _message, 'create_task_steps', 'cap');

            CONTINUE;
        End If;

        -- Add additional script if extending an existing job
        If _extensionScriptName <> '' Then
            SELECT contents
            INTO _scriptXML2
            FROM cap.t_scripts
            WHERE script = extensionScriptNameList;

            -- FUTURE: process as list INTO _scriptXML2
            _scriptXML := (_scriptXML::text || _scriptXML2::text)::xml;
        End If;

        -- Get parameters for the capture task job as XML
        --
        _xmlParameters := cap.create_parameters_for_job (_jobInfo.Job, _jobInfo.Dataset, _jobInfo.DatasetID,
                                                         _jobInfo.Script, _jobInfo.StorageServer,
                                                         _jobInfo.Instrument, _jobInfo.InstrumentClass,
                                                         _jobInfo.MaxSimultaneousCaptures, _jobInfo.CaptureSubdirectory);

        -- Store the parameters
        INSERT INTO Tmp_Job_Parameters (Job, Parameters)
        VALUES (_jobInfo.Job, _xmlParameters);

        -- Create the basic capture task job structure (steps and dependencies)
        -- Details are stored in Tmp_Job_Steps and Tmp_Job_Step_Dependencies
        Call cap.create_steps_for_job (
                _jobInfo.Job,
                _scriptXML,
                _jobInfo.ResultsDirectoryName,
                _message => _message,
                _returnCode => _returnCode,
                _debugMode => _debugMode);

        If _returnCode <> '' Then
            RAISE WARNING 'Error %: %', _returnCode, _message;
            CONTINUE;
        End If;

        If _debugMode Then
            -- Show contents of Tmp_Job_Steps and Tmp_Job_Step_Dependencies
            --
            CALL sw.show_tmp_job_steps_and_job_step_dependencies();
        End If;

        -- Perform a mixed bag of operations on the capture task jobs in the temporary tables to finalize them before
        -- copying to the main database tables

        Call cap.finish_task_creation (
                 _jobInfo.Job,
                 _message => _message,
                 _debugMode => _debugMode);

        _jobsProcessed := _jobsProcessed + 1;

        If extract(epoch FROM clock_timestamp() - _lastLogTime) >= _loopingUpdateInterval Then
            -- Make sure _loggingEnabled is true
            _loggingEnabled := true;

            _statusMessage := format('... Creating capture task job steps: %s / %s', _jobsProcessed, _jobCountToProcess);
            Call public.post_log_entry ('Progress', _statusMessage, 'create_task_steps', 'cap');

            _lastLogTime := clock_timestamp();
        End If;

    END LOOP;

    ---------------------------------------------------
    -- We've got new capture task jobs in temp tables - what to do?
    ---------------------------------------------------
    --
    If _infoOnly Then
        _message = _infoMessage;
    Else
        If _mode::citext = 'CreateFromImportedJobs' Then
            -- Copies data from the following temp tables to actual database tables:
            --     Tmp_Jobs
            --     Tmp_Job_Steps
            --     Tmp_Job_Step_Dependencies
            --     Tmp_Job_Parameters
            Call cap.move_jobs_to_main_tables (_message => _message, _returnCode => _returnCode, _debugMode => _debugMode);
        End If;
    End If;

    If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
        _loggingEnabled := true;
        _statusMessage := 'Create task steps complete';
        Call public.post_log_entry ('Progress', _statusMessage, 'create_task_steps', 'cap');
    End If;

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
    If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
        _statusMessage := 'Exiting';
        Call public.post_log_entry ('Progress', _statusMessage, 'create_task_steps', 'cap');
    End If;

    If _debugMode Then
        -- Show contents of Tmp_Jobs
        --
        CALL sw.show_tmp_jobs();
    End If;

    DROP TABLE Tmp_Jobs;
    DROP TABLE Tmp_Job_Steps;
    DROP TABLE Tmp_Job_Step_Dependencies;
    DROP TABLE Tmp_Job_Parameters;
END
$$;


ALTER PROCEDURE cap.create_task_steps(INOUT _message text, IN _debugmode boolean, IN _mode text, IN _existingjob integer, IN _extensionscriptname text, IN _maxjobstoprocess integer, IN _logintervalthreshold integer, IN _loggingenabled boolean, IN _loopingupdateinterval integer, IN _infoonly boolean, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE create_task_steps(INOUT _message text, IN _debugmode boolean, IN _mode text, IN _existingjob integer, IN _extensionscriptname text, IN _maxjobstoprocess integer, IN _logintervalthreshold integer, IN _loggingenabled boolean, IN _loopingupdateinterval integer, IN _infoonly boolean, INOUT _returncode text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.create_task_steps(INOUT _message text, IN _debugmode boolean, IN _mode text, IN _existingjob integer, IN _extensionscriptname text, IN _maxjobstoprocess integer, IN _logintervalthreshold integer, IN _loggingenabled boolean, IN _loopingupdateinterval integer, IN _infoonly boolean, INOUT _returncode text) IS 'CreateJobSteps';

