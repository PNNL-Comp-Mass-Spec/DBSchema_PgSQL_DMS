--
-- Name: update_job_in_main_tables(text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.update_job_in_main_tables(INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates sw.T_Jobs, sw.T_Job_Steps, and sw.T_Job_Parameters using the information in Tmp_Jobs, Tmp_Job_Steps, and Tmp_Job_Parameters
**      This procedure is only called if procedure sw.create_job_steps() is called with Mode 'UpdateExistingJob'
**
**      Note: Does not update job steps in state 5 = Complete
**
**  Auth:   mem
**  Date:   03/11/2009 mem - Initial release (Ticket #725, http://prismtrac.pnl.gov/trac/ticket/725)
**          03/21/2011 mem - Changed transaction name to match procedure name
**          05/25/2011 mem - Removed priority column from T_Job_Steps
**          10/17/2011 mem - Added column Memory_Usage_MB
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          11/18/2015 mem - Add Actual_CPU_Load
**          07/31/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE

BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Replace job parameters
    ---------------------------------------------------

    UPDATE sw.t_job_parameters
    SET parameters = Tmp_Job_Parameters.parameters
    FROM Tmp_Job_Parameters
    WHERE Tmp_Job_Parameters.job = sw.t_job_parameters.job;

    ---------------------------------------------------
    -- Update job
    ---------------------------------------------------

    UPDATE sw.t_jobs
    SET priority = Tmp_Jobs.priority,
        state = Tmp_Jobs.state,
        imported = CURRENT_TIMESTAMP,
        start = CURRENT_TIMESTAMP,
        finish = NULL
    FROM Tmp_Jobs
    WHERE Tmp_Jobs.job = sw.t_jobs.job;

    -- Delete job step dependencies for job steps that are not yet completed
    DELETE FROM sw.t_job_step_dependencies JSD
    WHERE EXISTS
        ( SELECT 1
          FROM sw.t_job_steps JS
               INNER JOIN Tmp_Job_Steps
                 ON JS.job = Tmp_Job_Steps.job AND
                    JS.step = Tmp_Job_Steps.step
          WHERE JSD.job = JS.job AND
                JSD.step = JS.step AND
                JS.state <> 5            -- 5 = Complete
        );

    -- Delete job steps that are not yet completed
    DELETE FROM sw.t_job_steps JS
    WHERE EXISTS
        ( SELECT 1
          FROM Tmp_Job_Steps
          WHERE JS.Job = Tmp_Job_Steps.Job AND
                JS.Step = Tmp_Job_Steps.Step AND
                JS.State <> 5            -- 5 = Complete
        );

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
        output_folder_name
    )
    SELECT
        Src.job,
        Src.step,
        Src.tool,
        Src.cpu_load,
        Src.cpu_load,
        Src.memory_usage_mb,
        Src.dependencies,
        Src.shared_result_version,
        Src.signature,
        1,            -- state
        Src.input_directory_name,
        Src.output_directory_name
    FROM Tmp_Job_Steps Src
         LEFT OUTER JOIN sw.t_job_steps JS
           ON JS.job = Src.job AND
              JS.step = Src.step
    WHERE JS.job Is Null;

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
        Src.job,
        Src.step,
        Src.target_step,
        Src.condition_test,
        Src.test_value,
        Src.enable_only
    FROM Tmp_Job_Step_Dependencies Src
         LEFT OUTER JOIN sw.t_job_step_dependencies JSD
           ON JSD.job = Src.job AND
              JSD.step = Src.step
    WHERE JSD.job IS NULL;

END
$$;


ALTER PROCEDURE sw.update_job_in_main_tables(INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_job_in_main_tables(INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.update_job_in_main_tables(INOUT _message text, INOUT _returncode text) IS 'UpdateJobInMainTables';

