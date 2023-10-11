--
-- Name: update_step_states(boolean, integer, integer, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.update_step_states(IN _infoonly boolean DEFAULT false, IN _maxjobstoprocess integer DEFAULT 0, IN _loopingupdateinterval integer DEFAULT 5, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Determine which steps will be enabled or skipped based upon completion of target steps that they depend upon
**
**  Arguments:
**    _infoOnly                 When true, preview updates
**    _maxJobsToProcess         Maximum number of jobs to update
**    _loopingUpdateInterval    Seconds between detailed logging while looping through the dependencies
**
**  Auth:   grk
**  Date:   05/06/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          01/09/2009 mem - Added parameter _infoOnly and renamed _numStepsChanged to _numStepsSkipped (http://prismtrac.pnl.gov/trac/ticket/713)
**          06/02/2009 mem - Added parameter _maxJobsToProcess (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**          06/03/2009 mem - Added parameter _loopingUpdateInterval
**          12/21/2009 mem - Now passing _infoOnly to EvaluateStepDependencies
**          08/02/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _result int;
    _numStepsSkipped int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _infoOnly              := Coalesce(_infoOnly, false);
    _maxJobsToProcess      := Coalesce(_maxJobsToProcess, 0);
    _loopingUpdateInterval := Coalesce(_loopingUpdateInterval, 5);

    ---------------------------------------------------
    -- Perform state evaluation process followed by
    -- step update process and repeat until no more
    -- step states were changed
    ---------------------------------------------------

    WHILE true
    LOOP

        -- Get unevaluated dependencies for steps that are finished
        -- (skipped or completed)
        --
        CALL sw.evaluate_step_dependencies (
                    _maxJobsToProcess       => _maxJobsToProcess,
                    _loopingUpdateInterval  => _LoopingUpdateInterval,
                    _infoOnly               => _infoOnly,
                    _message                => _message,            -- Output
                    _returnCode             => _returnCode          -- Output
                    );

        -- Examine all dependencies for steps in 'Waiting' state
        -- and set state of steps that have them all satisfied
        --
        CALL sw.update_dependent_steps (
                    _infoOnly              => _infoOnly,
                    _maxJobsToProcess      => _maxJobsToProcess,
                    _loopingUpdateInterval => _LoopingUpdateInterval,
                    _numStepsSkipped       => _numStepsSkipped,         -- Output
                    _message               => _message,                 -- Output
                    _returnCode            => _returnCode                   -- Output
                    );

        -- Repeat if any step states were changed (but only If Not _infoOnly)
        --
        If Not (_numStepsSkipped > 0 And Not _infoOnly) Then
            -- Break out of the while loop
            EXIT;
        End If;

    END LOOP;

END
$$;


ALTER PROCEDURE sw.update_step_states(IN _infoonly boolean, IN _maxjobstoprocess integer, IN _loopingupdateinterval integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_step_states(IN _infoonly boolean, IN _maxjobstoprocess integer, IN _loopingupdateinterval integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.update_step_states(IN _infoonly boolean, IN _maxjobstoprocess integer, IN _loopingupdateinterval integer, INOUT _message text, INOUT _returncode text) IS 'UpdateStepStates';

