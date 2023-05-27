--
CREATE OR REPLACE PROCEDURE sw.create_job_steps
(
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _mode text = 'CreateFromImportedJobs',
    _existingJob int = 0,
    _extensionScriptName text = '',
    _extensionScriptSettingsFileOverride text = '',
    _maxJobsToProcess int = 0,
    _logIntervalThreshold int = 15,
    _loggingEnabled boolean = false,
    _loopingUpdateInterval int = 5,
    _infoOnly boolean = false,
    _debugMode boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Make entries in job steps table and job step
**      dependency table for each newly added job
**      according to definition of script for that job
**
**    Example usage for debugging:
**
**        Declare _message text;
**
**        CALL sw.create_job_steps (_message => _message, 'CreateFromImportedJobs', _existingJob => 555225, _infoOnly => true);
**
**        Raise Info '%', _message;
**
**  Arguments:
**    _mode                                  Modes: CreateFromImportedJobs, ExtendExistingJob, UpdateExistingJob (rarely used)
**    _existingJob                           Used if _mode = 'ExtendExistingJob' or _mode = 'UpdateExistingJob'; can also be used when _mode = 'CreateFromImportedJobs' and _debugMode is true
**    _extensionScriptName                   Only used if _mode = 'ExtendExistingJob'; name of the job script to apply when extending an existing job
**    _extensionScriptSettingsFileOverride   Only used if _mode = 'ExtendExistingJob'; new settings file to use instead of the one defined in DMS
**    _logIntervalThreshold                  If this procedure runs longer than this threshold, status messages will be posted to the log
**    _loggingEnabled                        Set to true to immediately enable progress logging; if false, logging will auto-enable if _logIntervalThreshold seconds elapse
**    _loopingUpdateInterval                 Seconds between detailed logging while looping through the dependencies
**    _debugMode                             When setting this to true, you can optionally specify a job using _existingJob to view the steps that would be created for that job.  Also, when this is true, various debug tables will be shown
**
**  Auth:   grk
**  Date:   05/06/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          01/28/2009 grk - Modified for parallelization (http://prismtrac.pnl.gov/trac/ticket/718)
**          01/30/2009 grk - Modified output folder name initiation (http://prismtrac.pnl.gov/trac/ticket/719)
**          02/06/2009 grk - modified for extension jobs (http://prismtrac.pnl.gov/trac/ticket/720)
**          02/08/2009 mem - Added parameters _debugMode and _jobOverride
**          02/26/2009 mem - Removed old Script_ID column from the temporary tables
**          03/11/2009 mem - Removed parameter _jobOverride since _existingJob can be used to specify an existing job
**                         - Added mode 'UpdateExistingJob' (Ticket #725, http://prismtrac.pnl.gov/trac/ticket/725)
**          06/01/2009 mem - Added indices on the temporary tables (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**                         - Added parameter _maxJobsToProcess
**          06/04/2009 mem - Added parameters _logIntervalThreshold, _loggingEnabled, and _loopingUpdateInterval
**          12/21/2009 mem - Now displaying additional information when _debugMode is non-zero
**          01/05/2010 mem - Renamed parameter _extensionScriptNameList to _extensionScriptName
**                         - Added parameter _extensionScriptSettingsFileOverride
**          10/22/2010 mem - Now passing _debugMode to MergeJobsToMainTables
**          01/06/2011 mem - Now passing _ignoreSignatureMismatch to CrossCheckJobParameters
**          03/21/2011 mem - Now passing _debugMode to FinishJobCreation
**          05/25/2011 mem - Updated call to CreateStepsForJob
**          10/17/2011 mem - Now populating column Memory_Usage_MB using UpdateJobStepMemoryUsage
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          09/14/2015 mem - Now passing _debugMode to MoveJobsToMainTables
**                         - Verify that T_Step_Tool_Versions has Tool_Version_ID 1 (unknown)
**          11/09/2015 mem - Assure that Dataset_ID is only if the dataset name is 'Aggregation'
**          05/12/2017 mem - Verify that T_Remote_Info has Remote_Info_ID 1 (unknown)
**          03/02/2022 mem - Pass data package ID to CreateSignaturesForJobSteps when dataset ID is 0
**          02/13/2023 mem - Show contents of temp table Tmp_Jobs when _debugMode is true
**                         - Add results folder name comment regarding Special="Job_Results"
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _stepCount int := 0;
    _stepCountNew int := 0;
    _maxJobsToAdd int;
    _startTime timestamp;
    _lastLogTime timestamp;
    _statusMessage text;
    _jobCountToProcess int;
    _jobsProcessed int;
    _errorMessage text;
    _jobInfo record;
    _prevJob int;
    _datasetOrDataPackageId int;
    _continue boolean;
    _resultsDirectoryName text;
    _jobList text;
    _xmlParameters xml;
    _scriptXML xml;
    _tag text;
    _scriptXML2 xml;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --
    _infoOnly := Coalesce(_infoOnly, false);
    _debugMode := Coalesce(_debugMode, false);
    _existingJob := Coalesce(_existingJob, 0);
    _extensionScriptName := Coalesce(_extensionScriptName, '');
    _extensionScriptSettingsFileOverride := Coalesce(_extensionScriptSettingsFileOverride, '');

    _mode := Trim(Lower(Coalesce(_mode, '')));
    _maxJobsToProcess := Coalesce(_maxJobsToProcess, 0);

    If _debugMode Then
        RAISE INFO ' ';
    End If;

    If Not _mode::citext In ('CreateFromImportedJobs', 'ExtendExistingJob', 'UpdateExistingJob') Then
        _message := format('Unknown mode: %s', _mode);
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

    If _mode::citext = 'ExtendExistingJob' Then
        -- Make sure _existingJob is non-zero
        If _existingJob = 0 Then
            _message := 'Error: Parameter _existingJob must contain a valid job number to extend an existing job';
            _returnCode := 'U5202';

            RAISE WARNING '%', _message;
            RETURN;
        End If;

        -- Make sure a valid extension script is defined
        If Coalesce(_extensionScriptName, '') = '' Then
            _message := 'Error: Parameter _extensionScriptName must be defined when extending an existing job';
            _returnCode := 'U5203';

            RAISE WARNING '%', _message;
            RETURN;
        End If;

        If Not Exists (Select * from sw.t_scripts WHERE script = _extensionScriptName) Then
            _message := format('Error: Extension script "%s" not found in sw.t_scripts', _extensionScriptName);
            _returnCode := 'U5204';

            RAISE WARNING '%', _message;
            RETURN;
        End If;

        -- Make sure there are no conflicts in the step numbers in the extension script vs. the script used for the existing job

        CALL sw.validate_extension_script_for_job (
                _existingJob,
                _extensionScriptName,
                _message => _message,           -- Output
                _returnCode => _returnCode);    -- Output

        If _returnCode <> '' Then
            RETURN;
        End If;

    Else
        _extensionScriptName := '';
        _extensionScriptSettingsFileOverride := '';
    End If;

    ---------------------------------------------------
    -- Create temporary tables to accumulate job steps
    -- job step dependencies, and job parameters for
    -- jobs being created
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Jobs (
        Job int NOT NULL,
        Priority int NULL,
        Script citext NULL,
        State int NOT NULL,
        Dataset citext NULL,
        Dataset_ID int NULL,
        DataPkgID int NULL,
        Results_Directory_Name citext NULL
    );

    CREATE INDEX IX_Tmp_Jobs_Job ON Tmp_Jobs (Job);

    CREATE TEMP TABLE Tmp_Job_Steps (
        Job int NOT NULL,
        Step int NOT NULL,
        tool citext NOT NULL,
        CPU_Load int NULL,
        Memory_Usage_MB int NULL,
        Dependencies int NULL,
        Shared_Result_Version int NULL,
        Filter_Version int NULL,
        Signature int NULL,
        State int NULL,
        Input_Directory_Name citext NULL,
        Output_Directory_Name citext NULL,
        Processor citext NULL,
        Special_Instructions citext NULL
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
    -- Get recently imported jobs that need to be processed
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
                DataPkgID,
                Results_Directory_Name)
            SELECT
                TJ.Job,
                TJ.Priority,
                TJ.Script,
                TJ.State,
                TJ.Dataset,
                TJ.Dataset_ID,
                TJ.DataPkgID,
                NULL
            FROM sw.t_jobs TJ
            WHERE TJ.state = 0
            LIMIT _maxJobsToAdd;
        End If;

        If _debugMode And _existingJob <> 0 Then
            INSERT INTO Tmp_Jobs (job, priority, script, State, Dataset, Dataset_ID, DataPkgID, Results_Directory_Name)
            SELECT job, priority, script, State, Dataset, Dataset_ID, DataPkgID, NULL
            FROM sw.t_jobs
            WHERE job = _existingJob;

            If Not FOUND Then
                _message := format('Job %s not found in sw.t_jobs; unable to continue debugging', _existingJob);
                _returnCode := 'U5205';
                RETURN;
            End If;
        End If;
    End If;

    ---------------------------------------------------
    -- Set up to process extension job
    ---------------------------------------------------
    --
    If _mode::citext = 'ExtendExistingJob' Then
        -- Populate Tmp_Jobs with info from existing job
        -- If it only exists in history, restore it to main tables
        CALL sw.set_up_to_extend_existing_job _existingJob, _message
    End If;

    If _mode::citext = 'UpdateExistingJob' Then
        -- Note: As of April 4, 2011, the 'UpdateExistingJob' mode is not used in the DMS_Pipeline database
        --
        If Not Exists (SELECT job FROM sw.t_jobs Where job = _existingJob) Then
            _message := format('Job %s not found in sw.t_jobs; unable to continue', _existingJob);
            _returnCode := 'U5206';

            RAISE WARNING '%', _message;

            DROP TABLE Tmp_Jobs;
            DROP TABLE Tmp_Job_Steps;
            DROP TABLE Tmp_Job_Step_Dependencies;
            DROP TABLE Tmp_Job_Parameters;

            RETURN;
        End If;

        INSERT INTO Tmp_Jobs (job, priority, script, State, Dataset, Dataset_ID, DataPkgID, Results_Directory_Name)
        SELECT job, priority, script, State, Dataset, Dataset_ID, DataPkgID, Results_Folder_Name
        FROM sw.t_jobs
        WHERE job = _existingJob
    End If;

    ---------------------------------------------------
    -- Make sure sw.t_step_tool_versions as the "Unknown" version (ID=1)
    ---------------------------------------------------
    --
    If Not Exists (Select * from sw.t_step_tool_versions WHERE tool_version_id = 1) Then

        -- ToDo: Update this to work with PostgreSQL
        --
        -- Use OVERRIDING SYSTEM VALUE to insert an explicit value for the identity column, for example:
        --
        -- INSERT INTO mc.t_log_entries (entry_id, posted_by, posting_time, type, message)
        -- OVERRIDING SYSTEM VALUE
        -- VALUES (12345, 'Test', CURRENT_TIMESTAMP, 'Test', 'message');
        Set IDENTITY_INSERT sw.t_step_tool_versions ON

        Insert Into sw.t_step_tool_versions (tool_version_id, tool_version)
        Values (1, 'Unknown')

        Set IDENTITY_INSERT sw.t_step_tool_versions OFF
    End If;

    ---------------------------------------------------
    -- Make sure sw.t_remote_info as the "Unknown" version (ID=1)
    ---------------------------------------------------
    --
    If Not Exists (Select * from sw.t_remote_info WHERE remote_info_id = 1) Then

        -- ToDo: Update this to work with PostgreSQL
        --
        -- Use OVERRIDING SYSTEM VALUE to insert an explicit value for the identity column, for example:
        --
        -- INSERT INTO mc.t_log_entries (entry_id, posted_by, posting_time, type, message)
        -- OVERRIDING SYSTEM VALUE
        -- VALUES (12345, 'Test', CURRENT_TIMESTAMP, 'Test', 'message');
        Set IDENTITY_INSERT sw.t_remote_info ON

        Insert Into sw.t_remote_info (remote_info_id, remote_info)
        Values (1, 'Unknown')

        Set IDENTITY_INSERT sw.t_remote_info OFF
    End If;

    ---------------------------------------------------
    -- Loop through jobs and process them into temp tables
    ---------------------------------------------------

    SELECT COUNT(*)
    INTO _jobCountToProcess
    FROM Tmp_Jobs;

    _prevJob := 0;
    _jobsProcessed := 0;
    _lastLogTime := clock_timestamp();
    _jobList := '';
    _continue := true;

    WHILE _continue
    LOOP
        ---------------------------------------------------
        -- Get next unprocessed job and
        -- build it into the temporary tables
        ---------------------------------------------------
        --
        SELECT
            Job,
            Script As ScriptName,
            Dataset,
            Dataset_ID As DatasetID,
            DataPkgID,
            Coalesce(Results_Directory_Name, '') As ResultsDirectoryName
        INTO _jobInfo
        FROM Tmp_Jobs
        WHERE Job > _prevJob
        ORDER BY Job
        LIMIT 1;

        ---------------------------------------------------
        -- If no job was found, we are done
        -- otherwise, process the job
        ---------------------------------------------------
        If Not FOUND Then
            -- Break out of the while loop
            EXIT;
        End If;

        -- Set up to get next job on next pass
        _prevJob := _jobInfo.Job;

        If _jobInfo.DatasetID = 0 And _jobInfo.Dataset <> 'Aggregation' Then
            _errorMessage := 'Dataset_ID can be 0 only when the Dataset name is "Aggregation"';
            _returnCode := 'U5207';

        End If;

        If _jobInfo.DatasetID <> 0 And _jobInfo.Dataset = 'Aggregation' Then
            _errorMessage := 'Dataset_ID must be 0 when the Dataset name is "Aggregation"';
            _returnCode := 'U5208';
        End If;

        If _jobInfo.DatasetID > 0 Then
            _datasetOrDataPackageId := _jobInfo.DatasetID;
        Else
            _datasetOrDataPackageId := _jobInfo.DataPackageID;
        End If;

        If _returnCode <> '' Then
            CALL public.post_log_entry ('Error', _errorMessage, 'Create_Job_Steps', 'sw');

            UPDATE Tmp_Jobs
            SET State = 5
            WHERE Job = _jobInfo.Job;

        Else
        -- <c>

            If _jobList = '' Then
                _jobList := _jobInfo.Job::text;
            Else
                _jobList := format('%s,%s', _jobList, _job);
            End If;

            _tag := 'unk';

            -- Get contents of script and tag for results directory name
            SELECT results_tag
            INTO _tag
            FROM sw.t_scripts
            WHERE script = _jobInfo.ScriptName;

            -- Add additional script if extending an existing job
            If _mode::citext = 'ExtendExistingJob' and _extensionScriptName <> '' Then

                SELECT contents
                INTO _scriptXML2
                FROM sw.t_scripts
                WHERE script = _extensionScriptName;

                -- FUTURE: process as list INTO _scriptXML2
                _scriptXML := (_scriptXML::text || _scriptXML2::text)::xml;
            End If;

            If _debugMode Then
                RAISE INFO 'Script XML: %', _scriptXML;
            End If;

            -- Construct the results directory name
            If _mode::citext = 'CreateFromImportedJobs' or _mode::citext = 'UpdateExistingJob' Then
                _resultsDirectoryName = sw.get_results_directory_name (_jobInfo.Job, _tag);

                UPDATE Tmp_Jobs
                SET Results_Directory_Name = _resultsDirectoryName
                WHERE Job = _jobInfo.Job;

                _jobInfo.ResultsDirectoryName := _resultsDirectoryName;
            End If;

            -- Get parameters for the job as XML
            --
            _xmlParameters := sw.create_parameters_for_job (
                                    _jobInfo.Job,
                                    _settingsFileOverride => _extensionScriptSettingsFileOverride,
                                    _debugMode => _debugMode);

            -- Store the parameters in Tmp_Job_Parameters
            INSERT INTO Tmp_Job_Parameters (Job, Parameters)
            VALUES (_jobInfo.Job, _xmlParameters);

            -- Create the basic job structure (steps and dependencies)
            -- Details are stored in Tmp_Job_Steps and Tmp_Job_Step_Dependencies
            CALL sw.create_steps_for_job (
                    _job,
                    _scriptXML,
                    _resultsDirectoryName,
                    _message => _message,
                    _returnCode => _returnCode);

            -- Calculate signatures for steps that require them (and also handle shared results directories)
            -- Details are stored in Tmp_Job_Steps
            CALL sw.create_signatures_for_job_steps (
                    _job,
                    _xmlParameters,
                    _datasetOrDataPackageId,
                    _message => _message,
                    _debugMode => _debugMode);

            -- Update the memory usage for job steps that have JavaMemorySize entries defined in the parameters
            -- This updates Memory_Usage_MB in Tmp_Job_Steps
            CALL sw.update_job_step_memory_usage (
                    _job,
                    _xmlParameters,
                    _message => _message);

            -- For MSXML_Gen and ProMex jobs, _resultsFolderName will be of the form XML202212141459_Auto2113610 or PMX202301141131_Auto2139566
            -- We actually want the results folder to be the shared results directory name (e.g. MSXML_Gen_1_194_863076 or ProMex_1_286_1112666)
            -- This change will be made by finish_job_creation when it looks for Special="Job_Results" in the pipeline script XML, for example
            --
            -- <JobScript Name="ProMex">
            -- <Step Number="1" Tool="PBF_Gen"/>
            -- <Step Number="2" Tool="ProMex" Special="Job_Results">
            -- <Depends_On Step_Number="1"/>
            -- </Step>

            If _debugMode Then
                SELECT COUNT(*)
                INTO _stepCount
                FROM Tmp_Job_Steps ;

                -- Show the contents of Tmp_Jobs
                CALL sw.show_tmp_jobs();

                -- Show the contents of Tmp_Job_Steps and Tmp_Job_Step_Dependencies
                CALL sw.show_tmp_job_steps_and_job_step_dependencies();

                -- Show the XML parameters
                RAISE INFO 'Parameters for job %: %', _jobInfo.Job, _xmlParameters);
            End If;

            -- Handle any step cloning
            CALL sw.clone_job_step (_job, _xmlParameters, _message => _message);

            If _debugMode Then
                SELECT COUNT(*)
                INTO _stepCountNew
                FROM Tmp_Job_Steps;

                If _stepCountNew <> _stepCount Then
                    RAISE INFO '';
                    RAISE INFO 'Data after Cloning';

                    CALL sw.show_tmp_job_steps_and_job_step_dependencies();
                End If;
            End If;

            -- Handle external DTAs If any
            -- This updates DTA_Gen steps in Tmp_Job_Steps for which the job parameters contain parameter 'ExternalDTAFolderName' with value 'DTA_Manual'
            CALL sw.override_dta_gen_for_external_dta _job, _xmlParameters, _message => _message

            -- Perform a mixed bag of operations on the jobs in the temporary tables to finalize them before
            -- copying to the main database tables
            CALL sw.finish_job_creation (
                    _job,
                    _message => _message,
                    _debugMode => _debugMode);

            -- Do current job parameters conflict with existing job?
            If _mode::citext = 'ExtendExistingJob' or _mode::citext = 'UpdateExistingJob' Then

                CALL sw.cross_check_job_parameters (
                        _job,
                        _message => _message,               -- Output
                        _returnCode => _returnCode,         -- Output
                        _ignoreSignatureMismatch => true);

                If _returnCode <> '' Then
                    If _mode::citext = 'UpdateExistingJob' Then
                        -- If None of the job steps has completed yet,  it's OK if there are parameter differences
                        If Exists (SELECT * FROM sw.t_job_steps WHERE job = _job AND state = 5) Then
                            _message := format('Conflicting parameters are not allowed when one or more job steps has completed: %s', _message);
                            RETURN;
                        Else
                            _message := '';
                        End If;

                    Else
                        -- Mode is 'ExtendExistingJob'; exit the procedure

                        DROP TABLE Tmp_Jobs;
                        DROP TABLE Tmp_Job_Steps;
                        DROP TABLE Tmp_Job_Step_Dependencies;
                        DROP TABLE Tmp_Job_Parameters;

                        RETURN;
                    End If;
                End If;

            End If;

        End If; -- </c>

        _jobsProcessed := _jobsProcessed + 1;

        If extract(epoch FROM clock_timestamp() - _lastLogTime) >= _loopingUpdateInterval Then
            -- Make sure _loggingEnabled is true
            _loggingEnabled := true;

            _statusMessage := format('... Creating job steps: %s / %s', _jobsProcessed, _jobCountToProcess);
            CALL public.post_log_entry ('Progress', _statusMessage, 'Create_Job_Steps', 'sw');
            _lastLogTime := clock_timestamp();
        End If;

    END LOOP;

    ---------------------------------------------------
    -- We've got new jobs in temp tables - what to do?
    ---------------------------------------------------

    If Not _infoOnly Then
        If _mode::citext = 'CreateFromImportedJobs' Then
            -- Move temp tables to main tables
            CALL sw.move_jobs_to_main_tables (
                    _message => _message,
                    _debugMode => _debugMode);

            -- Possibly update the input folder using the
            -- Special_Processing param in the job parameters
            CALL sw.update_input_folder_using_special_processing_param (
                    _jobList,
                    _infoOnly => false,
                    _showResultsMode => 0);
        End If;

        If _mode::citext = 'ExtendExistingJob' Then
            -- Merge temp tables with existing job
            CALL sw.merge_jobs_to_main_tables (
                    _message => _message,
                    _infoOnly => _infoOnly);
        End If;

        If _mode::citext = 'UpdateExistingJob' Then
            -- Merge temp tables with existing job
            CALL sw.update_job_in_main_tables (_message => _message);
        End If;

    Else
        If _mode::citext = 'ExtendExistingJob' Then
            -- Preview changes that would be made
            CALL sw.merge_jobs_to_main_tables (
                    _message => _message,
                    _infoOnly => _infoOnly);
        End If;
    End If;

    If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
        _loggingEnabled := true;
        _statusMessage := 'Create job steps complete';
        CALL public.post_log_entry ('Progress', _statusMessage, 'Create_Job_Steps', 'sw');
    End If;

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --

    If _debugMode And _mode::citext <> 'ExtendExistingJob' Then
        -- Show the contents of Tmp_Jobs
        --  (If _mode is 'ExtendExistingJob', we will have
        --   already done this in MergeJobsToMainTables)

        CALL sw.show_tmp_jobs();
    End If;

    DROP TABLE Tmp_Jobs;
    DROP TABLE Tmp_Job_Steps;
    DROP TABLE Tmp_Job_Step_Dependencies;
    DROP TABLE Tmp_Job_Parameters;
END
$$;

COMMENT ON PROCEDURE sw.create_job_steps IS 'CreateJobSteps';
