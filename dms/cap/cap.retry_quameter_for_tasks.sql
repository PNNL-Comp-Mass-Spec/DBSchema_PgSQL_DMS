--
-- Name: retry_quameter_for_tasks(text, boolean, boolean); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.retry_quameter_for_tasks(_jobs text, _infoonly boolean DEFAULT false, _ignorequametererrors boolean DEFAULT true) RETURNS TABLE(job integer, step integer, tool public.citext, message text, state smallint, start timestamp without time zone, finish timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Resets failed DatasetQuality steps in t_task_steps for the specified capture task jobs
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
** Example Usage:
**   SELECT * FROM cap.retry_quameter_for_tasks('6016807, 6016805, 6016798', _infoOnly => true, _ignoreQuameterErrors => false);
**
**  Auth:   mem
**  Date:   07/11/2019 mem - Initial version
**          07/22/2019 mem - When _infoOnly is false, return a table listing the capture task jobs that were reset
**          06/25/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_integer_list for a comma-separated list
**
*****************************************************/
DECLARE
    _logErrors boolean := false;
    _jobList text;
    _job int := 0;
    _message text := '';
    _returnCode text := '';

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    _jobs                 := Trim(Coalesce(_jobs, ''));
    _infoOnly             := Coalesce(_infoOnly, false);
    _ignoreQuameterErrors := Coalesce(_ignoreQuameterErrors, true);

    If _jobs = '' Then
        _message := 'Job number not supplied';
        RAISE INFO '%', _message;

        RETURN QUERY
        SELECT null::int,        -- Job
               null::int,        -- Step
               ''::citext,       -- Tool
               _message,         -- Message
               null::int2,       -- State
               null::timestamp,  -- Start
               null::timestamp;  -- Finish

        RETURN;
    End If;

    BEGIN
        -----------------------------------------------------------
        -- Create the temporary tables
        -----------------------------------------------------------

        CREATE TEMP TABLE Tmp_Quameter_Jobs (
            Job int
        );

        CREATE TEMP TABLE Tmp_Quameter_Job_Steps_To_Reset (
            Job int,
            Step int
        );

        -----------------------------------------------------------
        -- Parse the capture task job list
        -----------------------------------------------------------

        INSERT INTO Tmp_Quameter_Jobs (Job)
        SELECT DISTINCT Value
        FROM public.parse_delimited_integer_list(_jobs)
        ORDER BY Value;

        -----------------------------------------------------------
        -- Look for capture task jobs that have a failed DatasetQuality step
        -----------------------------------------------------------

        INSERT INTO Tmp_Quameter_Job_Steps_To_Reset( Job, Step )
        SELECT TS.Job, TS.Step
        FROM cap.t_task_steps TS
             INNER JOIN Tmp_Quameter_Jobs JR
               ON TS.Job = JR.Job
        WHERE TS.Tool = 'DatasetQuality' AND
              TS.State = 6;

        If Not Exists (SELECT * FROM Tmp_Quameter_Job_Steps_To_Reset) Then
            _message := 'None of the capture task job(s) has a failed DatasetQuality step';
            RAISE INFO '%', _message;

            _returnCode := 'U5202';
            RETURN;
        End If;

        -- Construct a comma-separated list of capture task jobs
        --
        SELECT string_agg(JR.Job::text, ', ' ORDER BY JR.Job)
        INTO _jobList
        FROM Tmp_Quameter_Job_Steps_To_Reset JR;

        -----------------------------------------------------------
        -- Reset the DatasetQuality step
        -----------------------------------------------------------

        If _ignoreQuameterErrors Then

            FOR _job IN
                SELECT JR.Job
                FROM Tmp_Quameter_Job_Steps_To_Reset JR
                ORDER BY JR.Job
            LOOP
                If _infoOnly Then
                    RAISE INFO 'Call cap.add_update_task_parameter (_job, ''StepParameters'', ''IgnoreQuameterErrors'', ''1'', _infoOnly => false)';
                Else
                    CALL cap.add_update_task_parameter (
                                _job,
                                _section    => 'StepParameters',
                                _paramName  => 'IgnoreQuameterErrors',
                                _value      => '1',
                                _message    => _message,        -- Output
                                _returncode => _returncode,     -- Output
                                _infoOnly   => false);
                End If;
            END LOOP;

        End If;

        If _infoOnly Then

            RETURN QUERY
            SELECT TS.Job,
                   TS.Step,
                   TS.Tool,
                   'Step would be reset',
                   TS.State,
                   TS.Start,
                   TS.Finish
            FROM cap.t_task_steps TS
                 INNER JOIN Tmp_Quameter_Job_Steps_To_Reset JR
                   ON TS.Job = JR.Job AND
                      TS.Step = JR.Step;

            RAISE INFO 'Call reset_dependent_task_steps for %', _jobList;

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
            FROM Tmp_Quameter_Job_Steps_To_Reset JR
            WHERE TS.Job  = JR.Job AND
                  TS.Step = JR.Step;

            -- Reset the state of the dependent steps
            --
            CALL cap.reset_dependent_task_steps (
                        _jobList,
                        _infoOnly   => false,
                        _message    => _message,        -- Output
                        _returncode => _returncode);    -- Output

            RETURN QUERY
            SELECT TS.Job,
                   TS.Step,
                   TS.Tool,
                   'Job step has been reset',
                   TS.State,
                   TS.Start,
                   TS.Finish
            FROM cap.t_task_steps TS
                 INNER JOIN Tmp_Quameter_Job_Steps_To_Reset JR
                   ON TS.Job = JR.Job AND
                      TS.Step = JR.Step;
        End If;

        DROP TABLE Tmp_Quameter_Jobs;
        DROP TABLE Tmp_Quameter_Job_Steps_To_Reset;

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

        RAISE WARNING '%', _message;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        DROP TABLE IF EXISTS Tmp_Quameter_Jobs;
        DROP TABLE IF EXISTS Tmp_Quameter_Job_Steps_To_Reset;
    END;
END
$$;


ALTER FUNCTION cap.retry_quameter_for_tasks(_jobs text, _infoonly boolean, _ignorequametererrors boolean) OWNER TO d3l243;

--
-- Name: FUNCTION retry_quameter_for_tasks(_jobs text, _infoonly boolean, _ignorequametererrors boolean); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON FUNCTION cap.retry_quameter_for_tasks(_jobs text, _infoonly boolean, _ignorequametererrors boolean) IS 'RetryQuameterForTasks or RetryQuameterForJobs';

