--
CREATE OR REPLACE PROCEDURE sw.reset_dependent_job_steps
(
    _jobs text,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Resets entries in T_Job_Steps and T_Job_Step_Dependencies for the given jobs
**      for which the job steps that are complete yet depend on a job step that is enabled,
**      in progress, or completed after the given job step finished
**
**  Arguments:
**    _jobs       List of jobs whose steps should be reset
**    _infoOnly   True to preview the changes
**
**  Auth:   mem
**  Date:   05/19/2011 mem - Initial version
**          05/23/2011 mem - Now checking for target steps having state 0 or 1 in addition to 2 or 4
**          07/05/2011 mem - Now updating Tool_Version_ID when resetting job steps
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/12/2017 mem - Update Next_Try and Remote_Info_ID
**          05/13/2017 mem - Treat state 9 (Running_Remote) as 'In progress'
**          03/22/2021 mem - Do not reset steps in state 7 (Holding)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _jobResetTran text := 'DependentJobStepReset';
BEGIN

    BEGIN TRY

        -----------------------------------------------------------
        -- Validate the inputs
        -----------------------------------------------------------
        --
        _jobs := Coalesce(_jobs, '');
        _infoOnly := Coalesce(_infoOnly, false);
        _message := '';

        If _jobs = '' Then
            _message := 'Job number not supplied';
            RAISE INFO '%', _message;
            RAISE EXCEPTION '%', _message;
        End If;

        -----------------------------------------------------------
        -- Create the temporary tables
        -----------------------------------------------------------
        --

        CREATE TEMP TABLE Tmp_Jobs (
            Job int
        )

        CREATE TEMP TABLE Tmp_JobStepsToReset (
            Job int,
            Step int
        )

        -----------------------------------------------------------
        -- Parse the job list
        -----------------------------------------------------------

        INSERT INTO Tmp_Jobs (Job)
        SELECT Value
        FROM public.parse_delimited_integer_list(_jobs, ',')
        ORDER BY Value
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        -----------------------------------------------------------
        -- Find steps for the given jobs that need to be reset
        -----------------------------------------------------------
        --
        INSERT INTO Tmp_JobStepsToReset( job, step )
        SELECT DISTINCT JS.job,
                        JS.step
        FROM sw.t_job_steps JS
             INNER JOIN sw.t_job_step_dependencies
               ON JS.job = sw.t_job_step_dependencies.job AND
                  JS.step = sw.t_job_step_dependencies.step
             INNER JOIN sw.t_job_steps JS_Target
               ON sw.t_job_step_dependencies.job = JS_Target.job
                  AND
                  sw.t_job_step_dependencies.target_step = JS_Target.step
        WHERE JS.state >= 2 AND
              JS.state Not In (3, 7) AND
              JS.job IN ( SELECT job
                          FROM Tmp_Jobs ) AND
              (JS_Target.state IN (0, 1, 2, 4, 9) OR
               JS_Target.start > JS.finish)
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _infoOnly Then
            -- ToDo: Use Raise Info

            SELECT JS.*
            FROM V_Job_Steps2 JS
                 INNER JOIN Tmp_JobStepsToReset JR
                   ON JS.Job = JR.Job AND
                      JS.Step = JR.Step
            ORDER BY JS.Job, JS.Step
        Else

            BEGIN

                -- Reset evaluated to 0 for the affected steps
                --
                UPDATE sw.t_job_step_dependencies
                SET evaluated = 0, triggered = 0
                FROM sw.t_job_step_dependencies JSD

                /********************************************************************************
                ** This UPDATE query includes the target table name in the FROM clause
                ** The WHERE clause needs to have a self join to the target table, for example:
                **   UPDATE sw.t_job_step_dependencies
                **   SET ...
                **   FROM source
                **   WHERE source.id = sw.t_job_step_dependencies.id;
                ********************************************************************************/

                                       ToDo: Fix this query

                    INNER JOIN Tmp_JobStepsToReset JR
                    ON JSD.Job = JR.Job AND
                        JSD.Step = JR.Step
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                -- Update the Job Steps to state Waiting
                --
                UPDATE sw.t_job_steps
                SET state = 1,                    -- 1=waiting
                    tool_version_id = 1,        -- 1=Unknown
                    next_try = CURRENT_TIMESTAMP,
                    remote_info_id = 1            -- 1=Unknown
                FROM sw.t_job_steps JS

                /********************************************************************************
                ** This UPDATE query includes the target table name in the FROM clause
                ** The WHERE clause needs to have a self join to the target table, for example:
                **   UPDATE sw.t_job_steps
                **   SET ...
                **   FROM source
                **   WHERE source.id = sw.t_job_steps.id;
                ********************************************************************************/

                                       ToDo: Fix this query

                     INNER JOIN Tmp_JobStepsToReset JR
                       ON JS.Job = JR.Job AND
                          JS.Step = JR.Step
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                COMMIT;
            END;

        End If;

    END TRY
    BEGIN CATCH
        Call public.format_error_message _message => _message, _myError output

        -- Rollback any open transactions
        ROLLBACK;

        Call public.post_log_entry ('Error', _message, 'ResetDependentJobSteps');
    END CATCH

    DROP TABLE Tmp_Jobs;
    DROP TABLE Tmp_JobStepsToReset;
END
$$;

COMMENT ON PROCEDURE sw.reset_dependent_job_steps IS 'ResetDependentJobSteps';
