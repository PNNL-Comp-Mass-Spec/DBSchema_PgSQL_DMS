--
-- Name: make_local_job_in_broker(text, text, integer, xml, text, text, integer, boolean, boolean, integer, text, text, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.make_local_job_in_broker(IN _scriptname text, IN _datasetname text, IN _priority integer, IN _jobparamxml xml, IN _comment text, IN _ownerusername text, IN _datapackageid integer, IN _debugmode boolean DEFAULT false, IN _logdebugmessages boolean DEFAULT false, INOUT _job integer DEFAULT 0, INOUT _resultsdirectoryname text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Create analysis job directly in sw.t_jobs
**
**  Arguments:
**    _scriptName               Script name
**    _datasetName              Dataset name
**    _priority                 Job priority
**    _jobParamXML              XML job parameters
**    _comment                  Comment to store in t_jobs
**    _ownerUsername            Owner username
**    _dataPackageID            Data package id (0 if not applicable)
**
**    _debugMode                When true, store the contents of the temp tables in the following tables (auto-created if missing)
**                                sw.t_debug_tmp_jobs
**                                sw.t_debug_tmp_job_steps
**                                sw.t_debug_tmp_job_step_dependencies
**                                sw.t_debug_tmp_job_parameters
**                              When _debugMode is true, the new job will not be added to sw.t_jobs
**
**    _logDebugMessages         Set to true to log debug messages in sw.T_Log_Entries (ignored if _debugMode is false)
**    _job                      Output: job number
**    _resultsDirectoryName     Output: results folder name
**    _message                  Status message
**    _returnCode               Return code
**    _returnCode               Calling user
**
**  Auth:   grk
**  Date:   04/13/2010 grk - Initial release
**          05/25/2010 grk - All dataset name other than 'na'
**          10/25/2010 grk - Added call to Adjust_Params_For_Local_Job
**          11/25/2010 mem - Added code to update the Dependencies column in Tmp_Job_Steps
**          05/25/2011 mem - Updated call to Create_Steps_For_Job and removed Priority from Tmp_Job_Steps
**          10/17/2011 mem - Added column Memory_Usage_MB
**          11/14/2011 mem - Now populating column Transfer_Folder_Path in T_Jobs
**          01/09/2012 mem - Added parameter _ownerUsername
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
**          07/28/2023 mem - Ported to PostgreSQL
**          07/31/2023 mem - Remove processor column from Tmp_Job_Steps (it was typically null, but obsolete procedure sw.override_dta_gen_for_external_dta() set it to 'Internal')
**          09/07/2023 mem - Align assignment statements
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**
*****************************************************/
DECLARE
    _xmlParameters xml;
    _scriptXML xml;
    _tag text := 'unk';
    _datasetID int;
    _transferFolderPath text := '';
    _currentLocation text := 'Starting';
    _msg text;
    _alterEnteredByMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _currentLocation := 'Validate the inputs';

        _scriptName       := Trim(Coalesce(_scriptName, ''));
        _datasetName      := Trim(Coalesce(_datasetName, ''));
        _priority         := Coalesce(_priority, 3);
        _comment          := Trim(Coalesce(_comment, ''));
        _ownerUsername    := Coalesce(_ownerUsername, session_user);
        _dataPackageID    := Coalesce(_dataPackageID, 0);
        _debugMode        := Coalesce(_debugMode, false);
        _logDebugMessages := Coalesce(_logDebugMessages, false);

        If _datasetName = '' Then
            _datasetName = 'na';
        End If;

        If _dataPackageID < 0 Then
            _dataPackageID := 0;
        End If;

        If _debugMode Then
            RAISE INFO '';
        End If;

        ---------------------------------------------------
        -- Create temporary tables to accumulate job steps,
        -- job step dependencies, and job parameters for jobs being created
        ---------------------------------------------------

        _currentLocation := 'Create temp tables';

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

        _currentLocation := 'Get script contents';

        -- Get contents of script and tag for results directory name
        --
        SELECT contents, results_tag
        INTO _scriptXML, _tag
        FROM sw.t_scripts
        WHERE script = _scriptName::citext;

        If Not FOUND Then
            _returnCode := 'U5213';
            RAISE EXCEPTION 'Script not found in sw.t_scripts: %', Coalesce(_scriptName, '??');
        End If;

        If Coalesce(_scriptXML::text, '') = '' Then
            _returnCode := 'U5214';
            RAISE EXCEPTION 'Script XML not defined in the contents field of sw.t_scripts for script %', Coalesce(_scriptName, '??');
        End If;

        If _scriptName::citext In ('MultiAlign_Aggregator', 'MaxQuant_DataPkg', 'MSFragger_DataPkg', 'DiaNN_DataPkg') And _dataPackageID = 0 Then
            _returnCode := 'U5215';
            RAISE EXCEPTION '"Data Package ID" must be positive when using script %', _scriptName;
        End If;

        ---------------------------------------------------
        -- Obtain new job number (if not debugging)
        ---------------------------------------------------

        _currentLocation := 'Get new job number';

        If Not _debugMode Then
            _job := public.get_new_job_id('Created in sw.t_jobs', false);

            If _job = 0 Then
                _returnCode := 'U5210';
                RAISE EXCEPTION 'Could not get a valid job number using get_new_job_id()';
            End If;
        End If;

        ---------------------------------------------------
        -- Note: _datasetID needs to be 0
        --
        -- If it is non-zero, the newly created job will get deleted from
        -- sw.t_jobs the next time Update_Context runs, since the system will think
        -- the job no-longer exists in public.t_analysis_job and thus should be deleted
        ---------------------------------------------------

        _datasetID := 0;

        ---------------------------------------------------
        -- Add job to temp table
        ---------------------------------------------------

        _currentLocation := 'Add row to Tmp_Jobs';

        INSERT INTO Tmp_Jobs (Job, Priority, Script, State, Dataset, Dataset_ID, Results_Directory_Name)
        VALUES (_job, _priority, _scriptName, 1, _datasetName, _datasetID, NULL);

        ---------------------------------------------------
        -- Construct the results directory name
        ---------------------------------------------------

        _currentLocation := 'Get results directory name';

        _resultsDirectoryName := sw.get_results_directory_name(_job, _tag);

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

        _currentLocation := 'Call sw.create_steps_for_job()';

        CALL sw.create_steps_for_job (
                    _job,
                    _scriptXML,
                    _resultsDirectoryName,
                    _message    => _message,        -- Output
                    _returnCode => _returnCode);    -- Output

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

        If _debugMode Then
            RAISE INFO '';
            RAISE INFO 'Calling sw.adjust_params_for_local_job';
        End If;

        _currentLocation := 'Call sw.adjust_params_for_local_job()';

        CALL sw.adjust_params_for_local_job (
                    _scriptName,
                    _dataPackageID,
                    _jobParamXML => _jobParamXML,   -- Input/Output
                    _message     => _message,       -- Output
                    _returnCode  => _returnCode,    -- Output
                    _debugMode   => _debugMode
                    );

        ---------------------------------------------------
        -- Calculate signatures for steps that require them (and also handle shared results directories)
        -- Details are stored in Tmp_Job_Steps
        ---------------------------------------------------

        _currentLocation := 'Call sw.create_signatures_for_job_steps()';

        CALL sw.create_signatures_for_job_steps (
                    _job,
                    _jobParamXML,
                    _dataPackageID,
                    _message    => _message,        -- Output
                    _returnCode => _returnCode,     -- Output
                    _debugMode  => _debugMode);

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
        -- Store XML job parameters in Tmp_Job_Parameters
        ---------------------------------------------------

        _currentLocation := 'Add row to Tmp_Job_Parameters';

        INSERT INTO Tmp_Job_Parameters (Job, Parameters)
        VALUES (_job, _jobParamXML);

        ---------------------------------------------------
        -- Handle any step cloning
        ---------------------------------------------------

        _currentLocation := 'Call sw.clone_job_step()';

        CALL sw.clone_job_step (
                    _job,
                    _jobParamXML,
                    _message    => _message,        -- Output
                    _returnCode => _returnCode);    -- Output

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
        -- Update step dependency count (code taken from procedure Finish_Job_Creation)
        ---------------------------------------------------

        _currentLocation := 'Update step dependencies';

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
        -- Copy data from temp tables to main tables
        ---------------------------------------------------

        If Not _debugMode Then

            _currentLocation := 'Add row to sw.t_jobs';

            -- The move_jobs_to_main_tables procedure requires that the job already be in sw.t_jobs
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
            SELECT Job,
                   Priority,
                   Script,
                   State,
                   Dataset,
                   Dataset_ID,
                   NULL AS transfer_folder_path,
                   _comment,
                   NULL AS storage_server,
                   _ownerUsername,
                   Coalesce(_dataPackageID, 0)
            FROM Tmp_Jobs;

            _currentLocation := 'Call sw.move_jobs_to_main_tables';

            CALL sw.move_jobs_to_main_tables (
                        _message    => _message,        -- Output
                        _returnCode => _returnCode);    -- Output

            _currentLocation := 'Call public.alter_entered_by_user';

            CALL public.alter_entered_by_user ('sw', 't_job_events', 'job', _job, _callingUser, _message => _alterEnteredByMessage);
        End If;

        If Not _debugMode Then
            ---------------------------------------------------
            -- Populate column transfer_folder_path in sw.t_jobs
            ---------------------------------------------------

            _currentLocation := 'Store TransferFolderPath in sw.t_jobs';

            SELECT Value
            INTO _transferFolderPath
            FROM sw.get_job_param_table_local( _job)
            WHERE Name = 'TransferFolderPath';

            If Coalesce(_transferFolderPath, '') <> '' Then
                UPDATE sw.t_jobs
                SET transfer_folder_path = _transferFolderPath
                WHERE job = _job;
            End If;

            ---------------------------------------------------
            -- If a data package is defined, update entries for
            -- OrganismName, LegacyFastaFileName, ProteinOptions, and ProteinCollectionList in sw.t_job_parameters
            ---------------------------------------------------

            If _dataPackageID > 0 Then
                _currentLocation := 'Call sw.update_job_param_org_db_info_using_data_pkg()';

                CALL sw.update_job_param_org_db_info_using_data_pkg (
                            _job,
                            _dataPackageID,
                            _deleteIfInvalid => false,
                            _message     => _message,       -- Output
                            _returnCode  => _returnCode,    -- Output
                            _callingUser => _callingUser);
            End If;
        End If;

        If _debugMode And _dataPackageID > 0 Then

            -----------------------------------------------
            -- Call update_job_param_org_db_info_using_data_pkg with debug mode enabled
            ---------------------------------------------------

            _currentLocation := 'Call sw.update_job_param_org_db_info_using_data_pkg()';

            CALL sw.update_job_param_org_db_info_using_data_pkg (
                        _job,
                        _dataPackageID,
                        _deleteIfInvalid    => false,
                        _debugMode          => true,
                        _scriptNameForDebug => _scriptName,
                        _message            => _message,        -- Output
                        _returnCode         => _returnCode,     -- Output
                        _callingUser        => _callingUser);

        End If;

        If _debugMode Then

            -- Tmp_Jobs
            RAISE INFO 'Storing contents of Tmp_Jobs in table sw.t_debug_tmp_jobs';
            _currentLocation := 'Store data in sw.t_debug_tmp_jobs';

            If Exists (SELECT tablename FROM pg_tables WHERE schemaname::citext = 'sw' And tablename::citext = 't_debug_tmp_jobs') Then
                DELETE FROM sw.t_debug_tmp_jobs;

                INSERT INTO sw.t_debug_tmp_jobs(Job, Priority, Script, State, Dataset, Dataset_ID, Results_Directory_Name)
                SELECT Job, Priority, Script, State, Dataset, Dataset_ID, Results_Directory_Name
                FROM Tmp_Jobs;
            Else
                CREATE TABLE sw.t_debug_tmp_jobs AS
                SELECT Job, Priority, Script, State, Dataset, Dataset_ID, Results_Directory_Name
                FROM Tmp_Jobs;
            End If;

            -- Tmp_Job_Steps
            RAISE INFO 'Storing contents of Tmp_Job_Steps in table sw.t_debug_tmp_job_steps';
            _currentLocation := 'Store data in sw.t_debug_tmp_job_steps';

            If Exists (SELECT tablename FROM pg_tables WHERE schemaname::citext = 'sw' And tablename::citext = 't_debug_tmp_job_steps') Then
                DELETE FROM sw.t_debug_tmp_job_steps;

                INSERT INTO sw.t_debug_tmp_job_steps (Job, Step, Tool, CPU_Load, Memory_Usage_MB, Dependencies, Shared_Result_Version, Filter_Version, Signature, State,
                                                      Input_Directory_Name, Output_Directory_Name, Special_Instructions)
                SELECT Job, Step, Tool, CPU_Load, Memory_Usage_MB, Dependencies, Shared_Result_Version, Filter_Version, Signature, State,
                       Input_Directory_Name, Output_Directory_Name, Special_Instructions
                FROM Tmp_Job_Steps;
            Else
                CREATE TABLE sw.t_debug_tmp_job_steps AS
                SELECT Job, Step, Tool, CPU_Load, Memory_Usage_MB, Dependencies, Shared_Result_Version, Filter_Version, Signature, State,
                       Input_Directory_Name, Output_Directory_Name, Special_Instructions
                FROM Tmp_Job_Steps;
            End If;

            -- Tmp_Job_Step_Dependencies
            RAISE INFO 'Storing contents of Tmp_Job_Step_Dependencies in table sw.t_debug_tmp_job_step_dependencies';
            _currentLocation := 'Store data in sw.t_debug_tmp_job_step_dependencies';

            If Exists (SELECT tablename FROM pg_tables WHERE schemaname::citext = 'sw' And tablename::citext = 't_debug_tmp_job_step_dependencies') Then
                DELETE FROM sw.t_debug_tmp_job_step_dependencies;

                INSERT INTO sw.t_debug_tmp_job_step_dependencies (Job, Step, Target_Step, Condition_Test, Test_Value, Enable_Only)
                SELECT Job, Step, Target_Step, Condition_Test, Test_Value, Enable_Only
                FROM Tmp_Job_Step_Dependencies;
            Else
                CREATE TABLE sw.t_debug_tmp_job_step_dependencies AS
                SELECT Job, Step, Target_Step, Condition_Test, Test_Value, Enable_Only
                FROM Tmp_Job_Step_Dependencies;
            End If;

            -- Tmp_Job_Parameters
            RAISE INFO 'Storing contents of Tmp_Job_Parameters in table sw.t_debug_tmp_job_parameters';
            _currentLocation := 'Store data in sw.t_debug_tmp_job_parameters';

            If Exists (SELECT tablename FROM pg_tables WHERE schemaname::citext = 'sw' And tablename::citext = 't_debug_tmp_job_parameters') Then
                DELETE FROM sw.t_debug_tmp_job_parameters;

                INSERT INTO sw.t_debug_tmp_job_parameters (Job, Parameters)
                SELECT Job, Parameters
                FROM Tmp_Job_Parameters;
            Else
                CREATE TABLE sw.t_debug_tmp_job_parameters AS
                SELECT Job, Parameters
                FROM Tmp_Job_Parameters;
            End If;

            If _logDebugMessages Then
                CALL public.post_log_entry ('Debug', _jobParamXML::text, 'Make_Local_Job_In_Broker', 'sw');
            End If;
        End If;

        _currentLocation := 'Drop tables';

        DROP TABLE Tmp_Jobs;
        DROP TABLE Tmp_Job_Steps;
        DROP TABLE Tmp_Job_Step_Dependencies;
        DROP TABLE Tmp_Job_Parameters;

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

        DROP TABLE IF EXISTS Tmp_Jobs;
        DROP TABLE IF EXISTS Tmp_Job_Steps;
        DROP TABLE IF EXISTS Tmp_Job_Step_Dependencies;
        DROP TABLE IF EXISTS Tmp_Job_Parameters;
    END;
END
$$;


ALTER PROCEDURE sw.make_local_job_in_broker(IN _scriptname text, IN _datasetname text, IN _priority integer, IN _jobparamxml xml, IN _comment text, IN _ownerusername text, IN _datapackageid integer, IN _debugmode boolean, IN _logdebugmessages boolean, INOUT _job integer, INOUT _resultsdirectoryname text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE make_local_job_in_broker(IN _scriptname text, IN _datasetname text, IN _priority integer, IN _jobparamxml xml, IN _comment text, IN _ownerusername text, IN _datapackageid integer, IN _debugmode boolean, IN _logdebugmessages boolean, INOUT _job integer, INOUT _resultsdirectoryname text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.make_local_job_in_broker(IN _scriptname text, IN _datasetname text, IN _priority integer, IN _jobparamxml xml, IN _comment text, IN _ownerusername text, IN _datapackageid integer, IN _debugmode boolean, IN _logdebugmessages boolean, INOUT _job integer, INOUT _resultsdirectoryname text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'MakeLocalJobInBroker';

