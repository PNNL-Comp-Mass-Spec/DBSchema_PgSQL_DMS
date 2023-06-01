--
CREATE OR REPLACE PROCEDURE sw.merge_jobs_to_main_tables
(
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Merges data in the temp tables into T_Jobs, T_Job_Steps, etc.
**      Intended for use with an extension job script
**
**
**  Auth:   grk
**  Date:   02/06/2009 grk - Initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**          10/22/2010 mem - Added parameter _debugMode
**          03/21/2011 mem - Renamed _debugMode to _infoOnly
**          05/25/2011 mem - Removed priority column from T_Job_Steps
**          10/17/2011 mem - Added column Memory_Usage_MB
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          11/18/2015 mem - Add Actual_CPU_Load
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE

BEGIN
    _message := '';
    _returnCode:= '';

    If _infoOnly Then

        -- ToDo: Show this information using RAISE INFO

        SELECT 'Tmp_Jobs' as Table, * FROM Tmp_Jobs
        SELECT 'Tmp_Job_Parameters ' as Table, * FROM Tmp_Job_Parameters

        -- No need to output these tables, since SP CreateJobSteps will have already displayed them
        -- SELECT 'Tmp_Job_Steps ' as Table, * FROM Tmp_Job_Steps
        -- SELECT 'Tmp_Job_Step_Dependencies' as Table, * FROM Tmp_Job_Step_Dependencies

        RETURN;
    End If;

    ---------------------------------------------------
    -- Replace job parameters
    ---------------------------------------------------
    --
    UPDATE sw.t_job_parameters
    SET sw.t_job_parameters.parameters = Tmp_Job_Parameters.parameters
    FROM Tmp_Job_Parameters
    WHERE Tmp_Job_Parameters.job = sw.t_job_parameters.job;

    ---------------------------------------------------
    -- Update job
    ---------------------------------------------------
    --
    UPDATE sw.t_jobs
    SET priority = Tmp_Jobs.priority,
        state = Tmp_Jobs.state,
        imported = CURRENT_TIMESTAMP,
        start = CURRENT_TIMESTAMP,
        finish = NULL
    FROM Tmp_Jobs
    WHERE Tmp_Jobs.job = sw.t_jobs.job;

    ---------------------------------------------------
    -- Add steps for job that currently aren't in main tables
    ---------------------------------------------------

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
        input_directory_name,
        output_directory_name,
        processor
    FROM Tmp_Job_Steps
    WHERE NOT EXISTS
    (
        SELECT *
        FROM sw.t_job_steps
        WHERE
            sw.t_job_steps.job = Tmp_Job_Steps.job and
            sw.t_job_steps.step = Tmp_Job_Steps.step
    );

    ---------------------------------------------------
    -- Add step dependencies for job that currently aren't
    -- in main tables
    ---------------------------------------------------

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
    FROM Tmp_Job_Step_Dependencies
    WHERE NOT EXISTS
    (
        SELECT *
        FROM sw.t_job_step_dependencies
        WHERE
            sw.t_job_step_dependencies.job = Tmp_Job_Step_Dependencies.job and
            sw.t_job_step_dependencies.step = Tmp_Job_Step_Dependencies.step
    );

END
$$;

COMMENT ON PROCEDURE sw.merge_jobs_to_main_tables IS 'MergeJobsToMainTables';
