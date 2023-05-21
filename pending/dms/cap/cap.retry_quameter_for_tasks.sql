--
CREATE OR REPLACE FUNCTION cap.retry_quameter_for_tasks
(
    _jobs text,
    _infoOnly boolean = false,
    _ignoreQuameterErrors boolean = true,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
RETURNS TABLE (
    Job int,
    Step int,
    Tool text,
    Message int,
    State int,
    Start timestamp,
    Finish timestamp
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Resets failed DatasetQuality step in t_task_steps for the specified capture task jobs
**
**      Useful for capture task jobs where Quameter encountered an error
**
**      By default, also sets parameter IgnoreQuameterErrors to 1, meaning
**      if Quameter fails again, the capture task job will be marked as 'skipped' instead of 'Failed'
**
**  Arguments:
**    _jobs       List of capture task jobs whose steps should be reset
**    _infoOnly   True to preview the changes,
**
**  Auth:   mem
**  Date:   07/11/2019 mem - Initial version
**          07/22/2019 mem - When _infoOnly is false, return a table listing the capture task jobs that were reset
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _logErrors boolean := false;
    _jobList text;
    _job int := 0;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------
    --
    _jobs := Coalesce(_jobs, '');
    _infoOnly := Coalesce(_infoOnly, false);
    _ignoreQuameterErrors := Coalesce(_ignoreQuameterErrors, true);

    If _jobs = '' Then
        _message := 'Job number not supplied';
        RAISE INFO '%', _message;

        _returnCode := 'U5201';
        RETURN
    End If;

    BEGIN
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
        -- Look for capture task jobs that have a failed DatasetQuality step
        -----------------------------------------------------------
        --
        INSERT INTO Tmp_JobStepsToReset( Job, Step )
        SELECT TS.Job, TS.Step
        FROM cap.V_task_Steps TS
             INNER JOIN Tmp_Jobs JL
               ON TS.Job = JL.Job
        WHERE Tool = 'DatasetQuality' AND
              State = 6;

        If Not Exists (Select * From Tmp_JobStepsToReset) Then
            _message := 'None of the capture task job(s) has a failed DatasetQuality step';
            RAISE INFO '%', _message;

            _returnCode := 'U5201';
            RETURN;
        End If;

        -- Construct a comma-separated list of capture task jobs
        --

        SELECT string_agg(Job::text, ',')
        INTO _jobList
        FROM Tmp_JobStepsToReset
        ORDER BY Job;

        -----------------------------------------------------------
        -- Reset the DatasetQuality step
        -----------------------------------------------------------
        --

        If _ignoreQuameterErrors Then

            FOR _job IN
                SELECT Job
                FROM Tmp_JobStepsToReset
                ORDER BY Job
            LOOP
                If _infoOnly Then
                    RAISE INFO 'call cap.add_update_task_parameter (_job, ''StepParameters'', ''IgnoreQuameterErrors'', ''1'', _infoOnly => false)';
                Else
                    call cap.add_update_task_parameter (_job, 'StepParameters', 'IgnoreQuameterErrors', '1', _infoOnly => false);
                End If;
            END LOOP;

        End If;

        If _infoOnly Then

            RETURN QUERY
            SELECT TS.Job,
                   TS.Step,
                   TS.Tool,
                   'Step would be reset' AS Message,
                   TS.State,
                   TS.Start,
                   TS.Finish
            FROM cap.V_task_Steps TS
                 INNER JOIN Tmp_JobStepsToReset JR
                   ON TS.Job = JR.Job AND
                      TS.Step = JR.Step;

            RAISE INFO 'call reset_dependent_task_steps for %', _jobList

        Else
            _logErrors := true;

            -- Reset the DatasetQuality step
            --
            UPDATE cap.t_task_steps TS
            SET state = 2,
                completion_code = 0,
                completion_message = NULL,
                evaluation_code = NULL,
                evaluation_message = NULL
            FROM Tmp_JobStepsToReset JR
            WHERE TS.Job  = JR.Job AND
                  TS.Step = JR.Step;

            -- Reset the state of the dependent steps
            --
            CALL cap.reset_dependent_task_steps (_jobList, _infoOnly => false);

            RETURN QUERY
            SELECT TS.Job,
                   TS.Step,
                   TS.Tool,
                   'Job step has been reset' AS Message,
                   TS.State,
                   TS.Start,
                   TS.Finish
            FROM cap.V_task_Steps TS
                  INNER JOIN Tmp_JobStepsToReset JR
                    ON TS.Job  = JR.Job AND
                       TS.Step = JR.Step;
        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;

    DROP TABLE IF EXISTS Tmp_Jobs;
    DROP TABLE IF EXISTS Tmp_JobStepsToReset;
END
$$;

COMMENT ON PROCEDURE cap.retry_quameter_for_tasks IS 'RetryQuameterForJobs';
