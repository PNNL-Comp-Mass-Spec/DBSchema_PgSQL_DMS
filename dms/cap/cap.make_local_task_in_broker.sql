--
-- Name: make_local_task_in_broker(text, integer, xml, text, boolean, integer, text, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.make_local_task_in_broker(IN _scriptname text, IN _priority integer, IN _jobparamxml xml, IN _comment text, IN _debugmode boolean DEFAULT false, INOUT _job integer DEFAULT 0, INOUT _resultsdirectoryname text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Create capture task job directly in 'cap' schema tables
**
**      This procedure is similar to sw.make_local_job_in_broker,
**      but this procedure is not actually used since cap.add_update_local_task_in_broker
**      only supports modes 'update' or 'reset', and not 'add'
**
**  Arguments:
**    _scriptName               Script name
**    _priority                 Job priority
**    _jobParamXML              XML job parameters
**    _comment                  Comment to store in t_tasks
**    _debugMode                When true, store the contents of the temp tables in the following tables (auto-created if missing)
**                                cap.t_debug_tmp_tasks
**                                cap.t_debug_tmp_task_steps
**                                cap.t_debug_tmp_task_step_dependencies
**                                cap.t_debug_tmp_task_parameters
**                              When _debugMode is true, the capture task job will not be added to cap.t_tasks
**    _job                      Output: capture task job number
**    _resultsDirectoryName     Output: results directory name
**
**  Auth:   grk
**  Date:   05/03/2010 grk - Initial release
**          05/25/2011 mem - Updated call to create_steps_for_task and removed Priority from Tmp_Job_Steps
**          09/24/2014 mem - Rename Job in t_task_step_dependencies
**          05/29/2015 mem - Add support for column Capture_Subfolder
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/17/2019 mem - Switch from folder to directory
**          06/19/2023 mem - Ported to PostgreSQL
**          07/27/2023 mem - Add missing assignment to variable _scriptXML
**          10/12/2023 mem - Rename debug tables to include "Task" instead of "Job"
**
*****************************************************/
DECLARE
    _datasetName text;
    _datasetID int;
    _scriptXML xml;
    _tag text;
    _msg text;

    _currentLocation text := 'Start';
    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN

        If _debugMode Then
            RAISE INFO '';
        End If;

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
        );

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
        -- Dataset
        ---------------------------------------------------

        _datasetName := 'na';
        _datasetID := 0;

        ---------------------------------------------------
        -- Script
        ---------------------------------------------------

        _currentLocation := 'Look for script in cap.t_scripts';

        -- Get contents of script and tag for results directory name
        --
        SELECT contents, results_tag
        INTO _scriptXML, _tag
        FROM cap.t_scripts
        WHERE script = _scriptName;

        If Not FOUND Then
            _tag := 'unk';
        End If;

        ---------------------------------------------------
        -- Add capture task job to temp table
        ---------------------------------------------------

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
               1,           -- State
               _datasetName,
               _datasetID,
               NULL);

        ---------------------------------------------------
        -- Save capture task job parameters as XML into temp table
        ---------------------------------------------------

        INSERT INTO Tmp_Job_Parameters (Job, Parameters)
        VALUES (_job, _jobParamXML);

        ---------------------------------------------------
        -- Create the basic capture task job structure (steps and dependencies)
        -- Details are stored in Tmp_Job_Steps and Tmp_Job_Step_Dependencies
        ---------------------------------------------------

        _currentLocation := 'Call cap.create_steps_for_task';

        CALL cap.create_steps_for_task (
                    _job,
                    _scriptXML,
                    _resultsDirectoryName,
                    _message    => _message,        -- Output
                    _returnCode => _returnCode,     -- Output
                    _debugmode  => _debugmode);

        If _returnCode <> '' Then
            _msg := format('Error returned by create_steps_for_task: %s', _returnCode);

            If Coalesce(_message, '') <> '' Then
                _msg := public.append_to_text (_msg, _message);
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

        _currentLocation := 'Call cap.finish_task_creation';

        CALL cap.finish_task_creation (
                    _job,
                    _message   => _message,     -- Output
                    _debugMode => _debugMode);

        ---------------------------------------------------
        -- Move temp tables to main tables
        ---------------------------------------------------

        If Not _debugMode Then

            _currentLocation := 'Add row to cap.t_tasks';

            -- Move_Tasks_To_Main_Tables procedure assumes that t_tasks table entry is already there
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
                  1,            -- State
                  _datasetName,
                  _datasetID,
                  NULL,
                  _comment,
                  NULL)
            RETURNING job
            INTO _job;

            UPDATE Tmp_Jobs                   SET Job = _job;
            UPDATE Tmp_Job_Steps              SET Job = _job;
            UPDATE Tmp_Job_Step_Dependencies  SET Job = _job;
            UPDATE Tmp_Job_Parameters         SET Job = _job;

            CALL cap.move_tasks_to_main_tables (
                        _message    => _message,        -- Output
                        _returnCode => _returnCode,     -- Output
                        _debugmode  => false);

        Else
            -- Debug mode is enabled

            _currentLocation := 'Preview the new capture task job';

            -- Tmp_Tasks
            RAISE INFO 'Storing contents of Tmp_Jobs in table cap.t_debug_tmp_tasks';

            If Exists (SELECT tablename FROM pg_tables WHERE schemaname::citext = 'cap' And tablename::citext = 't_debug_tmp_tasks') Then
                DELETE FROM cap.t_debug_tmp_tasks;

                INSERT INTO cap.t_debug_tmp_tasks( Job, Priority, Script, State, Dataset, Dataset_ID, Results_Directory_Name,
                                                  Storage_Server, Instrument, Instrument_Class,
                                                  Max_Simultaneous_Captures, Capture_Subdirectory )
                SELECT Job, Priority, Script, State, Dataset, Dataset_ID, Results_Directory_Name,
                       Storage_Server, Instrument, Instrument_Class,
                       Max_Simultaneous_Captures, Capture_Subdirectory
                FROM Tmp_Jobs;
            Else
                CREATE TABLE cap.t_debug_tmp_tasks AS
                SELECT Job, Priority, Script, State, Dataset, Dataset_ID, Results_Directory_Name,
                       Storage_Server, Instrument, Instrument_Class,
                       Max_Simultaneous_Captures, Capture_Subdirectory
                FROM Tmp_Jobs;
            End If;

            -- Tmp_Task_Steps
            RAISE INFO 'Storing contents of Tmp_Job_Steps in table cap.t_debug_tmp_task_steps';

            If Exists (SELECT tablename FROM pg_tables WHERE schemaname::citext = 'cap' And tablename::citext = 't_debug_tmp_task_steps') Then
                DELETE FROM cap.t_debug_tmp_task_steps;

                INSERT INTO cap.t_debug_tmp_task_steps (Job, Step, Tool, CPU_Load, Dependencies, Filter_Version, Signature, State,
                                                       Input_Directory_Name, Output_Directory_Name, Processor,
                                                       Special_Instructions, Holdoff_Interval_Minutes, Retry_Count)
                SELECT Job, Step, Tool, CPU_Load, Dependencies, Filter_Version, Signature, State,
                       Input_Directory_Name, Output_Directory_Name, Processor,
                       Special_Instructions, Holdoff_Interval_Minutes, Retry_Count
                FROM Tmp_Job_Steps;
            Else
                CREATE TABLE cap.t_debug_tmp_task_steps AS
                SELECT Job, Step, Tool, CPU_Load, Dependencies, Filter_Version, Signature, State,
                       Input_Directory_Name, Output_Directory_Name, Processor,
                       Special_Instructions, Holdoff_Interval_Minutes, Retry_Count
                FROM Tmp_Job_Steps;
            End If;

            -- Tmp_Task_Step_Dependencies
            RAISE INFO 'Storing contents of Tmp_Job_Step_Dependencies in table cap.t_debug_tmp_task_step_dependencies';

            If Exists (SELECT tablename FROM pg_tables WHERE schemaname::citext = 'cap' And tablename::citext = 't_debug_tmp_task_step_dependencies') Then
                DELETE FROM cap.t_debug_tmp_task_step_dependencies;

                INSERT INTO cap.t_debug_tmp_task_step_dependencies (Job, Step, Target_Step, Condition_Test, Test_Value, Enable_Only)
                SELECT Job, Step, Target_Step, Condition_Test, Test_Value, Enable_Only
                FROM Tmp_Job_Step_Dependencies;
            Else
                CREATE TABLE cap.t_debug_tmp_task_step_dependencies AS
                SELECT Job, Step, Target_Step, Condition_Test, Test_Value, Enable_Only
                FROM Tmp_Job_Step_Dependencies;
            End If;

            -- Tmp_Task_Parameters
            RAISE INFO 'Storing contents of Tmp_Job_Parameters in table cap.t_debug_tmp_task_parameters';

            If Exists (SELECT tablename FROM pg_tables WHERE schemaname::citext = 'cap' And tablename::citext = 't_debug_tmp_task_parameters') Then
                DELETE FROM cap.t_debug_tmp_task_parameters;

                INSERT INTO cap.t_debug_tmp_task_parameters (Job, Parameters)
                SELECT Job, Parameters
                FROM Tmp_Job_Parameters;
            Else
                CREATE TABLE cap.t_debug_tmp_task_parameters AS
                SELECT Job, Parameters
                FROM Tmp_Job_Parameters;
            End If;

        End If;

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


ALTER PROCEDURE cap.make_local_task_in_broker(IN _scriptname text, IN _priority integer, IN _jobparamxml xml, IN _comment text, IN _debugmode boolean, INOUT _job integer, INOUT _resultsdirectoryname text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE make_local_task_in_broker(IN _scriptname text, IN _priority integer, IN _jobparamxml xml, IN _comment text, IN _debugmode boolean, INOUT _job integer, INOUT _resultsdirectoryname text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.make_local_task_in_broker(IN _scriptname text, IN _priority integer, IN _jobparamxml xml, IN _comment text, IN _debugmode boolean, INOUT _job integer, INOUT _resultsdirectoryname text, INOUT _message text, INOUT _returncode text) IS 'MakeLocalTaskInBroker or MakeLocalJobInBroker';

