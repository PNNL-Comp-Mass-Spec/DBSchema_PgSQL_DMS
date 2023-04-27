--
CREATE OR REPLACE PROCEDURE sw.update_step_states
(
    INOUT _message text,
    _infoOnly boolean = false,
    _maxJobsToProcess int = 0,
    _loopingUpdateInterval int = 5
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Determine which steps will be enabled or skipped based upon completion of target steps that they depend upon
**
**  Arguments:
**    _loopingUpdateInterval   Seconds between detailed logging while looping through the dependencies
**
**  Auth:   grk
**  Date:   05/06/2008 -- initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          01/09/2009 mem - Added parameter _infoOnly and renamed _numStepsChanged to _numStepsSkipped (http://prismtrac.pnl.gov/trac/ticket/713)
**          06/02/2009 mem - Added parameter _maxJobsToProcess (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**          06/03/2009 mem - Added parameter _loopingUpdateInterval
**          12/21/2009 mem - Now passing _infoOnly to EvaluateStepDependencies
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _result int;
    _numStepsSkipped int;
    _done boolean;
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _message := '';
    _infoOnly := Coalesce(_infoOnly, false);
    _maxJobsToProcess := Coalesce(_maxJobsToProcess, 0);
    _loopingUpdateInterval := Coalesce(_loopingUpdateInterval, 5);

    ---------------------------------------------------
    -- Perform state evaluation process followed by
    -- step update process and repeat until no more
    -- step states were changed
    ---------------------------------------------------
    --
    --
    _done := false;
    --
    WHILE Not _done
    LOOP

        -- Get unevaluated dependencies for steps that are finished
        -- (skipped or completed)
        --
        Call sw.evaluate_step_dependencies ( _message => _message,         -- Output
                                          _returnCode => _returnCode,   -- Output
                                          _maxJobsToProcess => _maxJobsToProcess,
                                          _loopingUpdateInterval => _LoopingUpdateInterval,
                                          _infoOnly => _infoOnly);

        -- Examine all dependencies for steps in 'Waiting' state
        -- and set state of steps that have them all satisfied
        --
        Call sw.update_dependent_steps ( _message => _message,                      -- Output
                                      _numStepsSkipped => _numStepsSkipped,      -- Output
                                      _infoOnly => _infoOnly,
                                      _maxJobsToProcess => _maxJobsToProcess,
                                      _loopingUpdateInterval => _LoopingUpdateInterval);

        -- Repeat if any step states were changed (but only If Not _infoOnly)
        --
        If Not (_numStepsSkipped > 0 AND Not _infoOnly) Then
            _done := true;
        End If;

    END LOOP;

END
$$;

COMMENT ON PROCEDURE sw.update_step_states IS 'UpdateStepStates';
