--
CREATE OR REPLACE PROCEDURE sw.make_local_job_in_broker
(
    _scriptName text,
    _datasetName text = 'na',
    _priority int,
    _jobParamXML xml,
    _comment text,
    _ownerUsername text,
    _dataPackageID int,
    _debugMode boolean = false,
    _logDebugMessages boolean = false
    INOUT _job int,
    INOUT _resultsFolderName text,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Create analysis job directly in broker database
**
**  Arguments:
**    _debugMode            When this is true, optionally specify a job using _existingJob to view the steps that would be created for that job
**    _logDebugMessages     Set to true to log debug messages in sw.T_Log_Entries (ignored if _debugMode is false)
**
**  Auth:   grk
**  Date:   04/13/2010 grk - Initial release
**          05/25/2010 grk - All dataset name other than 'na'
**          10/25/2010 grk - Added call to Adjust_Params_For_Local_Job
**          11/25/2010 mem - Added code to update the Dependencies column in Tmp_Job_Steps
**          05/25/2011 mem - Updated call to Create_Steps_For_Job and removed Priority from Tmp_Job_Steps
**          10/17/2011 mem - Added column Memory_Usage_MB
**          11/14/2011 mem - Now populating column Transfer_Folder_Path in T_Jobs
**          01/09/2012 mem - Added parameter _ownerPRN
**          01/19/2012 mem - Added parameter _dataPackageID
**          02/07/2012 mem - Now validating that _dataPackageID is > 0 when _scriptName is MultiAlign_Aggregator
**          03/20/2012 mem - Now calling Update_Job_Param_Org_Db_Info_Using_Data_Pkg
**          08/21/2012 mem - Now including the message text reported by Create_Steps_For_Job if it returns an error code
**          04/10/2013 mem - Now calling Alter_Entered_By_User to update T_Job_Events
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          03/10/2021 mem - Do not call S_GetNewJobID when _debugMode is true
**          10/15/2021 mem - Capitalize keywords and update whitespace
**          03/02/2022 mem - Require that data package ID is non-zero for MaxQuant_DataPkg and MSFragger_DataPkg jobs
**                         - Pass data package ID to create_signatures_for_job_steps
**          03/24/2023 mem - Capitalize job parameter TransferFolderPath
**          03/27/2022 mem - Require that data package ID is non-zero for DiaNN_DataPkg jobs
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _xmlParameters xml;
    _scriptXML xml;
    _tag text := 'unk';
    _datasetID int := 0;
    _transferFolderPath text := '';
    _msg text;
BEGIN
    _message := '';
    _returnCode := '';

    _dataPackageID := Coalesce(_dataPackageID, 0);
    _scriptName := Trim(Coalesce(_scriptName, ''));

    _debugMode := Coalesce(_debugMode, false);
    _logDebugMessages := Coalesce(_logDebugMessages, false);

    If _dataPackageID < 0 Then
        _dataPackageID := 0;
    End If;

    ---------------------------------------------------
    -- Create temporary tables to accumulate job steps,
    -- job step dependencies, and job parameters for jobs being created
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Jobs (
        Job int NOT NULL,
        Priority int NULL,
        Script text NULL,
        State int NOT NULL,
        Dataset text NULL,
        Dataset_ID int NULL,
        Results_Directory_Name citext NULL
    );

    CREATE TEMP TABLE Tmp_Job_Steps (
        Job int NOT NULL,
        Step int NOT NULL,
        Tool text NOT NULL,
        CPU_Load int NULL,
        Memory_Usage_MB int NULL,
        Dependencies int NULL,
        Shared_Result_Version int NULL,
        Filter_Version int NULL,
        Signature int NULL,
        State int NULL,
        Input_Directory_Name text NULL,
        Output_Directory_Name text NULL,
        Processor text NULL,
        Special_Instructions text NULL
    );

    CREATE TEMP TABLE Tmp_Job_Step_Dependencies (
        Job int NOT NULL,
        Step int NOT NULL,
        Target_Step int NOT NULL,
        Condition_Test text NULL,
        Test_Value text NULL,
        Enable_Only int NULL
    );

    CREATE TEMP TABLE Tmp_Job_Parameters (
        Job int NOT NULL,
        Parameters xml NULL
    );

    ---------------------------------------------------
    -- Script
    ---------------------------------------------------

    -- Get contents of script and tag for results directory name
    --
    SELECT results_tag
    INTO _tag
    FROM sw.t_scripts
    WHERE script = _scriptName;

    If Not FOUND Then
        _returnCode := 'U5213';
        RAISE EXCEPTION 'Script not found in sw.t_scripts: %', Coalesce(_scriptName, '??');
    End If;

    If _scriptXML Is Null Then
        _returnCode := 'U5214';
        RAISE EXCEPTION 'Script XML not defined in the contents field of sw.t_scripts for script %', Coalesce(_scriptName, '??');
    End If;

    If _scriptName IN ('MultiAlign_Aggregator', 'MaxQuant_DataPkg', 'MSFragger_DataPkg', 'DiaNN_DataPkg') And _dataPackageID = 0 Then
        _returnCode := 'U5215';
        RAISE EXCEPTION '"Data Package ID" must be positive when using script %', _scriptName
    End If;

    ---------------------------------------------------
    -- Obtain new job number (if not debugging)
    ---------------------------------------------------

    If Not _debugMode Then
        _job := public.get_new_job_id('Created in broker', false)

        If _job = 0 Then
            _returnCode := 'U5210';
            RAISE EXCEPTION 'Could not get a valid job number using get_new_job_id()';
        End If;
    End If;

    ---------------------------------------------------
    -- Note: _datasetID needs to be 0
    --
    -- If it is non-zero, the newly created job will get deleted from
    -- this DB the next time Update_Context runs, since the system will think
    -- the job no-longer exists in DMS5 and thus should be deleted
    ---------------------------------------------------

    ---------------------------------------------------
    -- Add job to temp table
    ---------------------------------------------------

    INSERT INTO Tmp_Jobs (Job, Priority, Script, State, Dataset, Dataset_ID, Results_Directory_Name)
    VALUES (_job, _priority, _scriptName, 1, _datasetName, _datasetID, NULL)

    ---------------------------------------------------
    -- Construct the results directory name
    ---------------------------------------------------

    _resultsDirectoryName := sw.get_results_directory_name (_job, _tag);

    If _resultsDirectoryName Is Null Then

        RAISE WARNING 'Get_Results_Directory_Name returned a null string';

        DROP TABLE Tmp_Jobs;
        DROP TABLE Tmp_Job_Steps;
        DROP TABLE Tmp_Job_Step_Dependencies;
        DROP TABLE Tmp_Job_Parameters;

        RETURN;
    End If;

    UPDATE Tmp_Jobs
    SET Results_Directory_Name = _resultsDirectoryName
    WHERE Job = _job;

    ---------------------------------------------------
    -- Create the basic job structure (steps and dependencies)
    -- Details are stored in Tmp_Job_Steps and Tmp_Job_Step_Dependencies
    ---------------------------------------------------

    CALL sw.create_steps_for_job (_job, _scriptXML, _resultsDirectoryName, _message => _message, _returnCode => _returnCode);

    If _returnCode <> '' Then
        _msg := format('Error returned by create_steps_for_job: %s', _returnCode);

        If Coalesce(_message, '') <> '' Then
            _msg := format('%s; %s', _msg, _message);
        End If;

        RAISE WARNING '%', _msg;

        DROP TABLE Tmp_Jobs;
        DROP TABLE Tmp_Job_Steps;
        DROP TABLE Tmp_Job_Step_Dependencies;
        DROP TABLE Tmp_Job_Parameters;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Do special needs for local jobs that target other jobs
    ---------------------------------------------------

    CALL sw.adjust_params_for_local_job
        _scriptName,
        _datasetName,
        _dataPackageID,
        _jobParamXML OUTPUT,
        _message => _message

    If _debugMode Then
        RAISE INFO '';
        RAISE INFO 'Job params after calling adjust_params_for_local_job: %', _jobParamXML;
    End If;

    ---------------------------------------------------
    -- Calculate signatures for steps that require them (and also handle shared results directories)
    -- Details are stored in Tmp_Job_Steps
    ---------------------------------------------------

    CALL sw.create_signatures_for_job_steps (
            _job,
            _jobParamXML,
            _dataPackageID,
            _message => _message,
            _returnCode => _returnCode,
            _debugMode => _debugMode);

    If _returnCode <> '' Then
        _msg := format('Error returned by create_signatures_for_job_steps: %s', _returnCode);

        If Coalesce(_message, '') <> '' Then
            _msg := format('%s; %s', _msg, _message);
        End If;

        RAISE WARNING '%', _msg;

        DROP TABLE Tmp_Jobs;
        DROP TABLE Tmp_Job_Steps;
        DROP TABLE Tmp_Job_Step_Dependencies;
        DROP TABLE Tmp_Job_Parameters;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Save job parameters as XML into temp table
    ---------------------------------------------------

    -- FUTURE: need to get set of parameters normally provided by Get_Job_Param_Table,
    -- except for the job specifc ones which need to be provided as initial content of _jobParamXML
    --
    INSERT INTO Tmp_Job_Parameters (Job, Parameters)
    VALUES (_job, _jobParamXML);

    ---------------------------------------------------
    -- Handle any step cloning
    ---------------------------------------------------

    CALL sw.clone_job_step (_job, _jobParamXML, _message => _message, _returnCode => _returnCode);

    If _returnCode <> '' Then
        _msg := format('Error returned by clone_job_step: %s', _returnCode);

        If Coalesce(_message, '') <> '' Then
            _msg := format('%s; %s', _msg, _message);
        End If;

        RAISE WARNING '%', _msg;

        DROP TABLE Tmp_Jobs;
        DROP TABLE Tmp_Job_Steps;
        DROP TABLE Tmp_Job_Step_Dependencies;
        DROP TABLE Tmp_Job_Parameters;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Update step dependency count (code taken from SP FinishJobCreation)
    ---------------------------------------------------

    UPDATE Tmp_Job_Steps
    SET Dependencies = T.dependencies
    FROM ( SELECT Step,
                 COUNT(*) AS dependencies
          FROM Tmp_Job_Step_Dependencies
          WHERE Job = _job
          GROUP BY Step ) AS T
    WHERE T.Step = Tmp_Job_Steps.Step AND
          Tmp_Job_Steps.Job = _job;

    ---------------------------------------------------
    -- Move temp tables to main tables
    ---------------------------------------------------

    If Not _debugMode Then
        -- move_jobs_to_main_tables procedure requires that the job already be in sw.t_jobs
        --
        INSERT INTO sw.t_jobs( job,
                               priority,
                               script,
                               state,
                               dataset,
                               dataset_id,
                               transfer_folder_path,
                               comment,
                               storage_server,
                               owner_username,
                               data_pkg_id )
        VALUES(_job, _priority, _scriptName, 1,
               _datasetName, _datasetID, NULL,
               _comment, NULL, _ownerUsername,
               Coalesce(_dataPackageID, 0))

        CALL sw.move_jobs_to_main_tables _message => _message

        CALL alter_entered_by_user ('sw.t_job_events', 'job', _job, _callingUser);
    End If;

    If Not _debugMode Then
        ---------------------------------------------------
        -- Populate column transfer_folder_path in sw.t_jobs
        ---------------------------------------------------

        SELECT Value
        INTO _transferFolderPath
        FROM sw.get_job_param_table_local ( _job )
        WHERE Name = 'TransferFolderPath';

        If Coalesce(_transferFolderPath, '') <> '' Then
            UPDATE sw.t_jobs
            SET transfer_folder_path = _transferFolderPath
            WHERE job = _job
        End If;

        ---------------------------------------------------
        -- If a data package is defined, update entries for
        -- OrganismName, LegacyFastaFileName, ProteinOptions, and ProteinCollectionList in sw.t_job_parameters
        ---------------------------------------------------

        If _dataPackageID > 0 Then
            CALL sw.update_job_param_org_db_info_using_data_pkg (
                        _job,
                        _dataPackageID,
                        _deleteIfInvalid => false,
                        _message => _message,           -- Output
                        _returnCode => _returnCode,     -- Output
                        _callingUser => _callingUser);
        End If;
    End If;

    If _debugMode And _dataPackageID > 0 Then

        -----------------------------------------------
        -- Call update_job_param_org_db_info_using_data_pkg with debug mode enabled
        ---------------------------------------------------

        CALL sw.update_job_param_org_db_info_using_data_pkg (
                _job,
                _dataPackageID,
                _deleteIfInvalid => false,
                _debugMode => true,
                _scriptNameForDebug => _scriptName,
                _message => _message,
                _returnCode => _returnCode,
                _callingUser => _callingUser);

    End If;

    If _debugMode Then

        -- ToDo: Call a shared procedure to preview the contents of these tables using RAISE INFO

        SELECT * FROM Tmp_Jobs
        SELECT * FROM Tmp_Job_Steps
        SELECT * FROM Tmp_Job_Step_Dependencies
        SELECT * FROM Tmp_Job_Parameters

        If _logDebugMessages Then
            CALL public.post_log_entry ('Debug', _jobParamXML::text, 'Make_Local_Job_In_Broker', 'sw');
        End If;
    End If;

    DROP TABLE Tmp_Jobs;
    DROP TABLE Tmp_Job_Steps;
    DROP TABLE Tmp_Job_Step_Dependencies;
    DROP TABLE Tmp_Job_Parameters;
END
$$;

COMMENT ON PROCEDURE sw.make_local_job_in_broker IS 'MakeLocalJobInBroker';
