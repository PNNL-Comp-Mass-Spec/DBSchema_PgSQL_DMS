--
CREATE OR REPLACE PROCEDURE sw.move_jobs_to_main_tables
(
    INOUT _message text = '',
    INOUT _returnCode text = ''
    _debugMode boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Copy contents of four temporary tables:
**          Tmp_Jobs
**          Tmp_Job_Steps
**          Tmp_Job_Step_Dependencies
**          Tmp_Job_Parameters
**      To main database tables
**
**  Auth:   grk
**  Date:   02/06/2009 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/720)
**          05/25/2011 mem - Removed priority column from T_Job_Steps
**          10/17/2011 mem - Added column Memory_Usage_MB
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          09/14/2015 mem - Added parameter _debugMode
**          11/18/2015 mem - Add Actual_CPU_Load
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';
    _debugMode := Coalesce(_debugMode, false);

    ---------------------------------------------------
    -- Populate actual tables from accumulated entries
    ---------------------------------------------------

    If _debugMode Then

        -- Store the contents of the temporary tables in persistent tables
        --
        DROP TABLE IF EXISTS sw.T_Tmp_New_Jobs;
        DROP TABLE IF EXISTS sw.T_Tmp_New_Job_Steps;
        DROP TABLE IF EXISTS sw.T_Tmp_New_Job_Step_Dependencies;
        DROP TABLE IF EXISTS sw.T_Tmp_New_Job_Parameters;

        SELECT * INTO sw.T_Tmp_NewJobs FROM Tmp_Jobs;
        SELECT * INTO sw.T_Tmp_NewJobSteps FROM Tmp_Job_Steps;
        SELECT * INTO sw.T_Tmp_NewJobStepDependencies FROM Tmp_Job_Step_Dependencies;
        SELECT * INTO sw.T_Tmp_NewJobParameters FROM Tmp_Job_Parameters;
    End If;

    BEGIN

        UPDATE sw.t_jobs
        SET
            sw.t_jobs.state = Tmp_Jobs.state,
            sw.t_jobs.results_folder_name = Tmp_Jobs.results_directory_name
        FROM Tmp_Jobs
        WHERE sw.t_jobs.job = Tmp_Jobs.job;

        INSERT INTO sw.t_job_steps (
            job,
            step,
            tool,
            cpu_load,
            actual_cpu_load,
            memory_usage_mb,
            dependencies,
            shared_result_version,
            signature,
            state,
            input_folder_name,
            output_folder_name,
            processor
        )
        SELECT
            job,
            step,
            tool,
            cpu_load,
            cpu_load,
            memory_usage_mb,
            dependencies,
            shared_result_version,
            signature,
            state,
            input_folder_name,
            output_folder_name,
            processor
        FROM Tmp_Job_Steps;

        INSERT INTO sw.t_job_step_dependencies (
            job,
            step,
            target_step,
            condition_test,
            test_value,
            enable_only
        )
        SELECT
            job,
            step,
            target_step,
            condition_test,
            test_value,
            enable_only
        FROM Tmp_Job_Step_Dependencies;

        INSERT INTO sw.t_job_parameters (
            job,
            parameters
        )
        SELECT
            job,
            parameters
        FROM Tmp_Job_Parameters;

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

COMMENT ON PROCEDURE sw.move_jobs_to_main_tables IS 'MoveJobsToMainTables';
