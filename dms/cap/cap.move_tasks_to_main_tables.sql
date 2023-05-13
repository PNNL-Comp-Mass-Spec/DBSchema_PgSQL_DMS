--
-- Name: move_tasks_to_main_tables(text, text, boolean); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.move_tasks_to_main_tables(INOUT _message text, INOUT _returncode text, IN _debugmode boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Move contents of temporary tables:
**              Tmp_Jobs
**              Tmp_Job_Steps
**              Tmp_Job_Step_Dependencies
**              Tmp_Job_Parameters
**          To main database tables
**
**  Auth:   grk
**  Date:   02/06/2009 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/720)
**          01/14/2010 grk - removed path ID fields
**          05/25/2011 mem - Removed priority column from t_task_steps
**          09/24/2014 mem - Rename Job in t_task_step_dependencies
**          05/29/2015 mem - Add support for column Capture_Subfolder
**          09/17/2015 mem - Added parameter _debugMode
**          05/17/2019 mem - Switch from folder to directory in temp tables
**          10/11/2022 mem - Ported to PostgreSQL
**          03/07/2023 mem - Rename column in temporary table
**          04/02/2023 mem - Rename procedure and functions
**          05/12/2023 mem - Rename variables
**
*****************************************************/
DECLARE
    _updateCount int;
    _insertCount int;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';
    _debugMode := Coalesce(_debugMode, false);

    If _debugMode Then

        -- Store the contents of the temporary tables in persistent tables
        --
        DROP TABLE IF EXISTS cap.T_Tmp_New_Jobs;
        DROP TABLE IF EXISTS cap.T_Tmp_New_Job_Steps;
        DROP TABLE IF EXISTS cap.T_Tmp_New_Job_Step_Dependencies;
        DROP TABLE IF EXISTS cap.T_Tmp_New_Job_Parameters;

        CREATE TABLE cap.T_Tmp_New_Jobs AS SELECT * FROM Tmp_Jobs;
        CREATE TABLE cap.T_Tmp_New_Job_Steps AS SELECT * FROM Tmp_Job_Steps;
        CREATE TABLE cap.T_Tmp_New_Job_Step_Dependencies AS SELECT * FROM Tmp_Job_Step_Dependencies;
        CREATE TABLE cap.T_Tmp_New_Job_Parameters AS SELECT * FROM Tmp_Job_Parameters;

        RAISE INFO 'Stored temporary table contents in database tables T_Tmp_New_Jobs, T_Tmp_New_Job_Steps, etc.';
    End If;

    ---------------------------------------------------
    -- Populate actual tables from accumulated entries
    ---------------------------------------------------

    Begin
        UPDATE cap.t_tasks target
        SET State = J.State,
            Results_Folder_Name = J.Results_Directory_Name,
            Storage_Server = J.Storage_Server,
            Instrument = J.Instrument,
            Instrument_Class = J.Instrument_Class,
            Max_Simultaneous_Captures = J.Max_Simultaneous_Captures,
            Capture_Subfolder = J.Capture_Subdirectory
        FROM Tmp_Jobs J
        WHERE target.Job = J.Job;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        If _debugMode Then
            RAISE INFO 'Copied metadata from Tmp_Jobs to cap.t_tasks for % capture task %',
                        _updateCount, public.check_plural(_updateCount, 'job', 'jobs');
        End If;

        INSERT INTO cap.t_task_steps (
            Job,
            Step,
            Tool,
            CPU_Load,
            Dependencies,
            State,
            Input_Folder_Name,
            Output_Folder_Name,
            Processor,
            Holdoff_Interval_Minutes,
            Retry_Count
        )
        SELECT
            Job,
            Step,
            Tool,
            CPU_Load,
            Dependencies,
            State,
            Input_Directory_Name,
            Output_Directory_Name,
            Processor,
            Holdoff_Interval_Minutes,
            Retry_Count
        FROM Tmp_Job_Steps;
        --
        GET DIAGNOSTICS _insertCount = ROW_COUNT;

        If _debugMode Then
            RAISE INFO 'Added % % to cap.t_task_steps',
                        _insertCount, public.check_plural(_insertCount, 'row', 'rows');
        End If;

        INSERT INTO cap.t_task_step_dependencies (
            Job,
            Step,
            Target_Step,
            Condition_Test,
            Test_Value,
            Enable_Only
        )
        SELECT
            Job,
            Step,
            Target_Step,
            Condition_Test,
            Test_Value,
            Enable_Only
        FROM Tmp_Job_Step_Dependencies;
        --
        GET DIAGNOSTICS _insertCount = ROW_COUNT;

        If _debugMode Then
            RAISE INFO 'Added % % to cap.t_task_step_dependencies',
                        _insertCount, public.check_plural(_insertCount, 'row', 'rows');
        End If;

        INSERT INTO cap.t_task_parameters (
            Job,
            Parameters
        )
        SELECT
            Job,
            Parameters
        FROM Tmp_Job_Parameters;
        --
        GET DIAGNOSTICS _insertCount = ROW_COUNT;

        If _debugMode Then
            RAISE INFO 'Added % % to cap.t_task_parameters',
                        _insertCount, public.check_plural(_insertCount, 'row', 'rows');
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

END
$$;


ALTER PROCEDURE cap.move_tasks_to_main_tables(INOUT _message text, INOUT _returncode text, IN _debugmode boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE move_tasks_to_main_tables(INOUT _message text, INOUT _returncode text, IN _debugmode boolean); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.move_tasks_to_main_tables(INOUT _message text, INOUT _returncode text, IN _debugmode boolean) IS 'MoveJobsToMainTables';

