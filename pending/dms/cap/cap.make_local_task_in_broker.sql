--
CREATE OR REPLACE PROCEDURE cap.make_local_task_in_broker
(
    _scriptName text,
    _priority int,
    _jobParamXML xml,
    _comment text,
    _debugMode boolean = false,
    INOUT _job int,
    INOUT _resultsDirectoryName text,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Create capture task job directly in broker database
**
**  Arguments:
**    _scriptName   Script name
**    _priority     Job priority
**    _jobParamXML  XML job parameters
**    _comment      Job comment
**    _debugMode    When true, store the contents of the temp tables in the following tables (auto-created if missing)
**                    cap.t_debug_tmp_jobs
**                    cap.t_debug_tmp_job_steps
**                    cap.t_debug_tmp_job_step_dependencies
**                    cap.t_debug_tmp_job_parameters
**    _job          Capture task job number
**    _comment      Comment to store in t_tasks
**
**  Auth:   grk
**  Date:   05/03/2010 grk - Initial release
**          05/25/2011 mem - Updated call to create_steps_for_task and removed Priority from Tmp_Job_Steps
**          09/24/2014 mem - Rename Job in t_task_step_dependencies
**          05/29/2015 mem - Add support for column Capture_Subfolder
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/17/2019 mem - Switch from folder to directory
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetName text;
    _datasetID int;
    _scriptXML xml;
    _tag text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN

        ---------------------------------------------------
        -- Create temporary tables to accumulate capture task job steps,
        -- job step dependencies, and job parameters for
        -- capture task jobs being created
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_Jobs (
            Job int NOT NULL,
            Priority int NULL,
            Script text NULL,
            State int NOT NULL,
            Dataset text NULL,
            Dataset_ID int NULL,
            Results_Directory_Name text NULL,
            Storage_Server text NULL,
            Instrument text NULL,
            Instrument_Class text NULL,
            Max_Simultaneous_Captures int NULL,
            Capture_Subdirectory text NULL
        )

        CREATE TEMP TABLE Tmp_Job_Steps (
            Job int NOT NULL,
            Step int NOT NULL,
            Tool text NOT NULL,
            CPU_Load int NULL,
            Dependencies int NULL,
            Filter_Version int NULL,
            Signature int NULL,
            State int NULL,
            Input_Directory_Name text NULL,
            Output_Directory_Name text NULL,
            Processor text NULL,
            Special_Instructions text NULL,
            Holdoff_Interval_Minutes int NOT NULL,
            Retry_Count int NOT NULL
        )

        CREATE TEMP TABLE Tmp_Job_Step_Dependencies (
            Job int NOT NULL,
            Step int NOT NULL,
            Target_Step int NOT NULL,
            Condition_Test text NULL,
            Test_Value text NULL,
            Enable_Only int NULL
        )

        CREATE TEMP TABLE Tmp_Job_Parameters (
            Job int NOT NULL,
            Parameters xml NULL
        )

        ---------------------------------------------------
        -- Dataset
        ---------------------------------------------------

        _datasetName := 'na';
        _datasetID := 0;

        ---------------------------------------------------
        -- Script
        ---------------------------------------------------
        --

        -- Get contents of script and tag for results Directory name
        SELECT results_tag
        INTO _tag
        FROM cap.t_scripts
        WHERE script = _scriptName

        If Not FOUND Then
            _tag := 'unk';
        End If;

        ---------------------------------------------------
        -- Add capture task job to temp table
        ---------------------------------------------------
        --
        INSERT INTO Tmp_Jobs( Job,
                           Priority,
                           Script,
                           State,
                           Dataset,
                           Dataset_ID,
                           Results_Directory_Name )
        VALUES(_job,
               _priority,
               _scriptName,
               1,
               _datasetName,
               _datasetID,
               NULL)

        ---------------------------------------------------
        -- Save capture task job parameters as XML into temp table
        ---------------------------------------------------
        -- FUTURE: need to get set of parameters normally provided by GetJobParamTable,
        -- except for the job specific ones which need to be provided as initial content of _jobParamXML
        --
        INSERT INTO Tmp_Job_Parameters (Job, Parameters)
        VALUES (_job, _jobParamXML)

        ---------------------------------------------------
        -- Create the basic capture task job structure (steps and dependencies)
        -- Details are stored in Tmp_Job_Steps and Tmp_Job_Step_Dependencies
        ---------------------------------------------------
        --
        Call cap.create_steps_for_task (_job, _scriptXML, _resultsDirectoryName, _message => _message, _returnCode => _returnCode);

        If _returnCode <> '' Then
            _msg := 'Error returned by create_steps_for_task: ' || _returnCode;

            If Coalesce(_message, '') <> '' Then
                _msg := _msg || '; ' || _message;
            End If;

            RAISE WARNING '%', _msg;

            DROP TABLE Tmp_Jobs;
            DROP TABLE Tmp_Job_Steps;
            DROP TABLE Tmp_Job_Step_Dependencies;
            DROP TABLE Tmp_Job_Parameters;

            RETURN;
        End If;

        ---------------------------------------------------
        -- Perform a mixed bag of operations on the capture task jobs
        -- in the temporary tables to finalize them before
        -- copying to the main database tables
        ---------------------------------------------------
        --
        Call cap.finish_task_creation (_job, _message => _message, _debugMode => _debugMode);

        ---------------------------------------------------
        -- Move temp tables to main tables
        ---------------------------------------------------
        If Not _debugMode Then

            BEGIN

                -- MoveJobsToMainTables sproc assumes that t_tasks table entry is already there
                --
                INSERT INTO cap.t_tasks (
                      Priority,
                      Script,
                      State,
                      Dataset,
                      Dataset_ID,
                      Transfer_Folder_Path,
                      Comment,
                      Storage_Server
                    )
                VALUES
                    ( _priority,
                      _scriptName,
                      1,
                      _datasetName,
                      _datasetID,
                      NULL,
                      _comment,
                      NULL);

                _job := IDENT_CURRENT('t_tasks');

                UPDATE Tmp_Jobs  SET Job = _job
                UPDATE Tmp_Job_Steps  SET Job = _job
                UPDATE Tmp_Job_Step_Dependencies  SET Job = _job
                UPDATE Tmp_Job_Parameters  SET Job = _job

                Call cap.move_tasks_to_main_tables (_message => _message, _returnCode => _returnCode);

                COMMIT;
            END;

        End If;

        If _debugMode Then

            -- Tmp_Jobs
            RAISE INFO 'Storing contents of Tmp_Jobs in table cap.t_debug_tmp_jobs';

            If Exists (SELECT tablename FROM pg_tables WHERE schemaname::citext = 'cap' And tablename::citext = 't_debug_tmp_jobs') Then
                DELETE FROM cap.t_debug_tmp_jobs;

                INSERT INTO cap.t_debug_tmp_jobs
                SELECT *
                FROM Tmp_Jobs;
            Else
                CREATE TABLE cap.t_debug_tmp_jobs AS
                SELECT *
                FROM Tmp_Jobs;
            End If;

            -- Tmp_Job_Steps
            RAISE INFO 'Storing contents of Tmp_Job_Steps in table cap.t_debug_tmp_job_steps';

            If Exists (SELECT tablename FROM pg_tables WHERE schemaname::citext = 'cap' And tablename::citext = 't_debug_tmp_job_steps') Then
                DELETE FROM cap.t_debug_tmp_job_steps;

                INSERT INTO cap.t_debug_tmp_job_steps
                SELECT *
                FROM Tmp_Job_Steps;
            Else
                CREATE TABLE cap.t_debug_tmp_job_steps AS
                SELECT *
                FROM Tmp_Job_Steps;
            End If;

            -- Tmp_Job_Step_Dependencies
            RAISE INFO 'Storing contents of Tmp_Job_Step_Dependencies in table cap.t_debug_tmp_job_step_dependencies';

            If Exists (SELECT tablename FROM pg_tables WHERE schemaname::citext = 'cap' And tablename::citext = 't_debug_tmp_job_step_dependencies') Then
                DELETE FROM cap.t_debug_tmp_job_step_dependencies;

                INSERT INTO cap.t_debug_tmp_job_step_dependencies
                SELECT *
                FROM Tmp_Job_Step_Dependencies;
            Else
                CREATE TABLE cap.t_debug_tmp_job_step_dependencies AS
                SELECT *
                FROM Tmp_Job_Step_Dependencies;
            End If;

            -- Tmp_Job_Parameters
            RAISE INFO 'Storing contents of Tmp_Job_Parameters in table cap.t_debug_tmp_job_parameters';

            If Exists (SELECT tablename FROM pg_tables WHERE schemaname::citext = 'cap' And tablename::citext = 't_debug_tmp_job_parameters') Then
                DELETE FROM cap.t_debug_tmp_job_parameters;

                INSERT INTO cap.t_debug_tmp_job_parameters
                SELECT *
                FROM Tmp_Job_Parameters;
            Else
                CREATE TABLE cap.t_debug_tmp_job_parameters AS
                SELECT *
                FROM Tmp_Job_Parameters;
            End If;

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

    DROP TABLE IF EXISTS Tmp_Jobs;
    DROP TABLE IF EXISTS Tmp_Job_Steps;
    DROP TABLE IF EXISTS Tmp_Job_Step_Dependencies;
    DROP TABLE IF EXISTS Tmp_Job_Parameters;
END
$$;

COMMENT ON PROCEDURE cap.make_local_task_in_broker IS 'MakeLocalJobInBroker';
