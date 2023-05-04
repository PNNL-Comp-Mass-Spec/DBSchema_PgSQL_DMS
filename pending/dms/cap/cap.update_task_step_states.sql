--

CREATE OR REPLACE PROCEDURE cap.update_task_step_states
(
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = false,
    _maxJobsToProcess int = 0,
    _loopingUpdateInterval int = 5
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Determine which steps will be enabled or skipped based
**      upon completion of target steps that they depend upon
**
**  Arguments:
**    _loopingUpdateInterval   Seconds between detailed logging while looping through the dependencies
**
**  Auth:   grk
**  Date:   09/02/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          06/01/2020 mem - Tabs to spaces
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _numStepsSkipped int;
    _done boolean := false;
BEGIN
    _message := '';
    _returnCode:= '';

    _maxJobsToProcess := Coalesce(_maxJobsToProcess, 0);

    ---------------------------------------------------
    -- Perform state evaluation process followed by
    -- step update process and repeat until no more
    -- step states were changed
    ---------------------------------------------------
    --
    --
    --
    WHILE _done = false
    LOOP

        -- Get unevaluated dependencies for steps that are finished
        -- (skipped or completed)
        --
        Call cap.evaluate_task_step_dependencies (
                            _message => _message,
                            _maxJobsToProcess => _maxJobsToProcess,
                            _loopingUpdateInterval => _LoopingUpdateInterval,
                            _returnCode => _returnCode);

        -- Examine all dependencies for steps in 'Waiting' state
        -- and set state of steps that have them all satisfied
        --
        Call cap.update_task_dependent_steps (
                            _message => _message,
                            _numStepsSkipped => _numStepsSkipped,
                            _infoOnly => _infoOnly,
                            _maxJobsToProcess => _maxJobsToProcess,
                            _loopingUpdateInterval => _LoopingUpdateInterval,
                            _returnCode => _returnCode);

        -- Repeat if any step states were changed (but only if _infoOnly is false)
        --
        If _numStepsSkipped = 0 Or _infoOnly Then
            _done := true;
        End If;

    END LOOP;

END
$$;

COMMENT ON PROCEDURE cap.update_task_step_states IS 'UpdateStepStates';

