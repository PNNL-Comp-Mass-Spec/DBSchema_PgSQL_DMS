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
    _jobResetTran text := 'DependentJobStepReset';

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN

        -----------------------------------------------------------
        -- Validate the inputs
        -----------------------------------------------------------

        _jobs := Coalesce(_jobs, '');
        _infoOnly := Coalesce(_infoOnly, false);
        _message := '';

        If _jobs = '' Then
            _message := 'The jobs parameter is empty';
            RAISE WARNING '%', _message;

            _returnCode := 'U5201';
            RETURN
        End If;

        -----------------------------------------------------------
        -- Create the temporary tables
        -----------------------------------------------------------

        CREATE TEMP TABLE Tmp_Jobs (
            Job int
        );

        CREATE TEMP TABLE Tmp_JobStepsToReset (
            Job int,
            Step int
        );

        -----------------------------------------------------------
        -- Parse the job list
        -----------------------------------------------------------

        INSERT INTO Tmp_Jobs (Job)
        SELECT Value
        FROM public.parse_delimited_integer_list(_jobs, ',')
        ORDER BY Value;

        -----------------------------------------------------------
        -- Find steps for the given jobs that need to be reset
        -----------------------------------------------------------

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
               JS_Target.start > JS.finish);

        If _infoOnly Then
            -- Preview steps that would be updated

            RAISE INFO ' ';

            _infoHead := format(_formatSpecifier,
                                'Job',
                                'Dataset_ID',
                                'Step',
                                'Tool',
                                'State_Name',
                                'State',
                                'Dataset'
                            );

            _infoHeadSeparator := format(_formatSpecifier,
                                '----------',
                                '----------',
                                '-----',
                                '--------------------',
                                '----------',
                                '-----',
                                '--------------------------------------------------'
                            );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT JS.job, JS.dataset_id, JS.step, JS.tool, JS.state_name, JS.state, JS.dataset
                FROM sw.V_job_steps JS
                     INNER JOIN Tmp_JobStepsToReset JR
                       ON JS.Job = JR.Job AND
                          JS.Step = JR.Step
                ORDER BY JS.Job, JS.Step;
            LOOP
                _infoData := format(_formatSpecifier,
                                        _previewData.job,
                                        _previewData.dataset_id,
                                        _previewData.step,
                                        _previewData.tool,
                                        _previewData.state_name,
                                        _previewData.state,
                                        _previewData.dataset
                                   );

                RAISE INFO '%', _infoData;

            END LOOP;

            DROP TABLE Tmp_Jobs;
            DROP TABLE Tmp_JobStepsToReset;

            RETURN;

        End If;

        -- Reset evaluated to 0 for the affected steps
        --
        UPDATE sw.t_job_step_dependencies JSD
        SET evaluated = 0, triggered = 0
        FROM Tmp_JobStepsToReset JR
        WHERE JSD.Job  = JR.Job AND
              JSD.Step = JR.Step;

        -- Update the Job Steps to state Waiting
        --
        UPDATE sw.t_job_steps JS
        SET state = 1,                      -- 1=waiting
            tool_version_id = 1,            -- 1=Unknown
            next_try = CURRENT_TIMESTAMP,
            remote_info_id = 1              -- 1=Unknown
        FROM Tmp_JobStepsToReset JR
        WHERE JS.Job  = JR.Job AND
              JS.Step = JR.Step;

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

    DROP TABLE Tmp_Jobs;
    DROP TABLE Tmp_JobStepsToReset;
END
$$;

COMMENT ON PROCEDURE sw.reset_dependent_job_steps IS 'ResetDependentJobSteps';
