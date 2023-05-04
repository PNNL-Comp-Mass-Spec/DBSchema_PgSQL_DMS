--
CREATE OR REPLACE PROCEDURE cap.merge_tasks_to_main_tables
(
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates t_tasks, t_task_parameters, and t_task_steps
**      using contents of temporary tables:
**          Tmp_Jobs
**          Tmp_Job_Steps
**          Tmp_Job_Step_Dependencies
**          Tmp_Job_Parameters
**
**  Auth:   grk
**  Date:   02/06/2009 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/720)
**          05/25/2011 mem - Removed priority column from t_task_steps
**          09/24/2014 mem - Rename Job in t_task_step_dependencies
**          05/17/2019 mem - Switch from folder to directory
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
    _returnCode:= '';

/*
select * from Tmp_Jobs
select * from Tmp_Job_Steps
select * from Tmp_Job_Step_Dependencies
select * from Tmp_Job_Parameters
RETURN;
*/

    ---------------------------------------------------
    -- Replace capture task job parameters
    ---------------------------------------------------
    --
    UPDATE cap.t_task_parameters Target
    SET Parameters = JP.Parameters
    FROM Tmp_Job_Parameters JP
    WHERE Target.Job = JP.Job;

    ---------------------------------------------------
    -- Update capture task job
    ---------------------------------------------------
    --
    UPDATE cap.t_tasks Target
    SET
        Priority = T.Priority,
        State = T.State,
        Imported = CURRENT_TIMESTAMP,
        Start = CURRENT_TIMESTAMP,
        Finish = NULL
    FROM Tmp_Jobs T
    WHERE Target.Job = T.job;

    ---------------------------------------------------
    -- Add steps for capture task job that currently aren't in main tables
    ---------------------------------------------------

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
    FROM Tmp_Job_Steps
    WHERE NOT EXISTS
    (
        SELECT *
        FROM cap.t_task_steps
        WHERE
            cap.t_task_steps.Job = Tmp_Job_Steps.Job and
            cap.t_task_steps.Step = Tmp_Job_Steps.Step
    )

    ---------------------------------------------------
    -- Add step dependencies for capture task job that currently aren't
    -- in main tables
    ---------------------------------------------------

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
    FROM Tmp_Job_Step_Dependencies
    WHERE NOT EXISTS
    (
        SELECT *
        FROM cap.t_task_step_dependencies
        WHERE
            cap.t_task_step_dependencies.Job = Tmp_Job_Step_Dependencies.Job and
            cap.t_task_step_dependencies.Step = Tmp_Job_Step_Dependencies.Step
    )

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

END
$$;

COMMENT ON PROCEDURE cap.merge_tasks_to_main_tables IS 'MergeJobsToMainTables';

