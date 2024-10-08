--
-- Name: update_task_step_states(text, text, boolean, integer, integer); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.update_task_step_states(INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infoonly boolean DEFAULT false, IN _maxjobstoprocess integer DEFAULT 0, IN _loopingupdateinterval integer DEFAULT 10)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Determine which steps will be enabled or skipped based
**      upon completion of target steps that they depend upon
**
**  Arguments:
**    _message                  Status message
**    _returnCode               Return code
**    _infoOnly                 True to preview changes that would be made
**    _maxJobsToProcess         Maximum number of jobs to process
**    _loopingUpdateInterval    Seconds between detailed logging while looping through the dependencies
**
**  Auth:   grk
**  Date:   09/02/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          06/01/2020 mem - Tabs to spaces
**          06/20/2023 mem - Ported to PostgreSQL
**          08/27/2024 mem - Change default value for _loopingUpdateInterval to 10 seconds (previously 5 seconds)
**
*****************************************************/
DECLARE
    _numStepsSkipped int;
    _done boolean := false;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly              := Coalesce(_infoOnly, false);
    _maxJobsToProcess      := Coalesce(_maxJobsToProcess, 0);
    _loopingUpdateInterval := Coalesce(_loopingUpdateInterval, 10);

    ---------------------------------------------------
    -- Perform state evaluation process followed by
    -- step update process and repeat until no more
    -- step states were changed
    ---------------------------------------------------

    WHILE _done = false
    LOOP

        -- Get unevaluated dependencies for steps that are finished
        -- (skipped or completed)

        CALL cap.evaluate_task_step_dependencies (
                    _message               => _message,     -- Output
                    _returnCode            => _returnCode,  -- Output
                    _maxJobsToProcess      => _maxJobsToProcess,
                    _loopingUpdateInterval => _LoopingUpdateInterval);

        -- Examine all dependencies for steps in 'Waiting' state
        -- and set state of steps that have them all satisfied

        CALL cap.update_task_dependent_steps (
                    _message               => _message,     -- Output
                    _returnCode            => _returnCode,  -- Output
                    _numStepsSkipped       => _numStepsSkipped,
                    _infoOnly              => _infoOnly,
                    _maxJobsToProcess      => _maxJobsToProcess,
                    _loopingUpdateInterval => _LoopingUpdateInterval);

        -- Repeat if any step states were changed (but only if _infoOnly is false)

        If _numStepsSkipped = 0 Or _infoOnly Then
            _done := true;
        End If;

    END LOOP;

END
$$;


ALTER PROCEDURE cap.update_task_step_states(INOUT _message text, INOUT _returncode text, IN _infoonly boolean, IN _maxjobstoprocess integer, IN _loopingupdateinterval integer) OWNER TO d3l243;

--
-- Name: PROCEDURE update_task_step_states(INOUT _message text, INOUT _returncode text, IN _infoonly boolean, IN _maxjobstoprocess integer, IN _loopingupdateinterval integer); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.update_task_step_states(INOUT _message text, INOUT _returncode text, IN _infoonly boolean, IN _maxjobstoprocess integer, IN _loopingupdateinterval integer) IS 'UpdateTaskStepStates or UpdateStepStates';

