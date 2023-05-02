--
CREATE OR REPLACE PROCEDURE cap.retry_selected_tasks
(
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates capture task jobs in temporary table Tmp_Selected_Jobs (created by the caller)
**
**      Note: Use SP Update_Multiple_Capture_Jobs to retry a list of capture task jobs
**
**  Auth:   grk
**  Date:   01/11/2010
**          01/18/2010 grk - reset step retry count
**          09/24/2014 mem - Rename Job in t_task_step_dependencies
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE

BEGIN
    _message := '';
    _returnCode:= '';

    ---------------------------------------------------
    -- Set any failed or holding capture task job steps to waiting
    -- and reset retry count from step tools table
    ---------------------------------------------------
    --
    UPDATE cap.t_task_steps Target
    SET State = 1,
        Retry_Count = cap.t_step_tools.number_of_retries
    FROM cap.t_step_tools
    WHERE Target.Tool = cap.t_step_tools.step_tool AND
          Target.State IN ( 6, 7 ) AND      -- 6=Failed, 7=Holding
          Target.Job IN ( SELECT Job FROM Tmp_Selected_Jobs );

    ---------------------------------------------------
    -- Reset the entries in cap.t_task_step_dependencies for any steps with state 1
    ---------------------------------------------------
    --
    UPDATE cap.t_task_step_dependencies TSD
    SET Evaluated = 0,
        Triggered = 0
    FROM cap.t_task_steps TS
    WHERE TSD.Job = TS.Job AND
          TSD.Step = TS.Step AND
          TS.State = 1 AND          -- 1=Waiting
          TS.Job IN (SELECT Job From Tmp_Selected_Jobs);

    ---------------------------------------------------
    -- Set capture task job state to 'new'
    ---------------------------------------------------
    --
    UPDATE cap.t_tasks
    SET State = 1                   -- 1=new
    WHERE Job IN (SELECT Job From Tmp_Selected_Jobs);

END
$$;

COMMENT ON PROCEDURE cap.retry_selected_tasks IS 'RetrySelectedJobs';
