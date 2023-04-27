--
CREATE OR REPLACE PROCEDURE cap.reset_dependent_task_steps
(
    _jobs text,
    _infoOnly boolean = false,
    INOUT _message text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Resets entries in t_task_steps and t_task_step_dependencies for the given capture task jobs
**      for which the capture task job steps that are complete yet depend a job step that is enabled,
**      in progress, or completed after the given job step finished
**
**  Arguments:
**    _jobs       List of capture task jobs whose steps should be reset
**    _infoOnly   True to preview the changes
**
**  Auth:   mem
**  Date:   05/19/2011 mem - Initial version
**          05/23/2011 mem - Now checking for target steps having state 0 or 1 in addition to 2 or 4
**          03/12/2012 mem - Now updating Tool_Version_ID when resetting capture task job steps
**          09/24/2014 mem - Rename Job in t_task_step_dependencies
**          11/18/2014 mem - Add a table alias for t_task_step_dependencies
**          04/24/2015 mem - Now updating State in t_tasks
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          07/10/2017 mem - Clear Completion_Code, Completion_Message, Evaluation_Code, & Evaluation_Message when resetting a capture task job step
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _formatSpecifier text := '%-10s %-10s %-5s %-20s %-10s %-5s %-50s';
    _infoHead text;
    _infoHeadSeparator text;
    _infoData text;
    _previewData record;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    BEGIN

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
            _returnCode := 'U5201';
            RETURN
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
        -- Parse the capture task job list
        -----------------------------------------------------------

        INSERT INTO Tmp_Jobs (Job)
        SELECT Value
        FROM public.parse_delimited_integer_list(_jobs, ',')
        ORDER BY Value

        -----------------------------------------------------------
        -- Find steps for the given capture task jobs that need to be reset
        -----------------------------------------------------------
        --
        INSERT INTO Tmp_JobStepsToReset( Job, Step )
        SELECT DISTINCT TS.Job,
                        TS.Step
        FROM cap.t_task_steps TS
             INNER JOIN cap.t_task_step_dependencies TSD
               ON TS.Job = TSD.Job AND
                  TS.Step = TSD.Step
             INNER JOIN cap.t_task_steps js_target
               ON TSD.Job = JS_Target.Job AND
                  TSD.Target_Step = JS_Target.Step
        WHERE TS.State >= 2 AND
              TS.State <> 3 AND
              TS.Job IN ( SELECT Job
                          FROM Tmp_Jobs ) AND
              (JS_Target.State IN (0, 1, 2, 4) OR
               JS_Target.Start > TS.Finish);

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
                SELECT TS.job, TS.dataset_id, TS.step, TS.tool, TS.state_name, TS.state, TS.dataset;
                FROM cap.V_task_steps TS
                     INNER JOIN Tmp_JobStepsToReset JR
                       ON TS.Job = JR.Job AND
                          TS.Step = JR.Step
                ORDER BY TS.Job, TS.Step;
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
        UPDATE cap.t_task_step_dependencies TSD
        SET Evaluated = 0, Triggered = 0
        FROM Tmp_JobStepsToReset JR
        WHERE TSD.Job  = JR.Job AND
              TSD.Step = JR.Step;

        -- Update the capture task job steps to state Waiting
        --
        UPDATE cap.t_task_steps TS
        SET State = 1,                    -- 1=waiting
            Tool_Version_ID = 1,          -- 1=Unknown
            Completion_Code = 0,
            Completion_Message = Null,
            Evaluation_Code = Null,
            Evaluation_Message = Null
        FROM Tmp_JobStepsToReset JR
        WHERE TS.Job  = JR.Job AND
              TS.Step = JR.Step;

        -- Change the capture task job state from failed to running
        UPDATE cap.t_tasks
        SET State = 2
        FROM Tmp_JobStepsToReset JR
        WHERE T.Job  = JR.Job;

        DROP TABLE Tmp_Jobs;
        DROP TABLE Tmp_JobStepsToReset;

        RETURN;

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

        DROP TABLE IF EXISTS Tmp_Jobs;
        DROP TABLE IF EXISTS Tmp_JobStepsToReset;
    END;

END
$$;

COMMENT ON PROCEDURE cap.reset_dependent_task_steps IS 'ResetDependentJobSteps';
