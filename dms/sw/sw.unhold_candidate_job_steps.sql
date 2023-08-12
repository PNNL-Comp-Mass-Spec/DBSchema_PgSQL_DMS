--
-- Name: unhold_candidate_job_steps(text, integer, integer, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.unhold_candidate_job_steps(IN _steptool text DEFAULT 'MASIC_Finnigan'::text, IN _targetcandidates integer DEFAULT 15, IN _maxcandidatesplusjobs integer DEFAULT 30, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Examines the number of step steps with state 2=Enabled
**
**      If less than _targetCandidates, updates job steps with state 7 to have state 2
**      such that we will have _targetCandidates enabled job steps for the given step tool
**
**  Arguments:
**    _stepTool                 Step tool name
**    _targetCandidates         Number of steps that should have state 2
**    _maxCandidatesPlusJobs    Maximum number of steps that can be enabled or running
**
**  Auth:   mem
**  Date:   12/20/2011 mem - Initial version
**          04/24/2014 mem - Added parameter _maxCandidatesPlusJobs
**          05/13/2017 mem - Add step state 9 (Running_Remote)
**          08/12/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _updateCount int;
    _candidateSteps int;
    _candidatesPlusRunning int;
    _jobsToRelease int;
    _runningJobs int;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    _stepTool := Coalesce(_stepTool, '');
    _targetCandidates := Coalesce(_targetCandidates, 15);
    _maxCandidatesPlusJobs := Coalesce(_maxCandidatesPlusJobs, 30);

    -----------------------------------------------------------
    -- Look for job steps in state 7 (Holding)
    -----------------------------------------------------------

    If Not Exists ( SELECT JS.job, JS.step
                    FROM sw.t_job_steps JS
                    WHERE JS.state = 7 AND
                          JS.tool = _stepTool::citext) Then

        _message := format('No job steps in sw.t_job_steps have state 7 for tool %s', _stepTool);

        RAISE INFO '';
        RAISE INFO '%', _message;
        RETURN;
    End If;

    -----------------------------------------------------------
    -- Count the number of job steps in state 2 or 9 for step tool _stepTool
    -- Also count the number in state 2, 4, or 9
    -----------------------------------------------------------

    SELECT COUNT(step)
    INTO _candidateSteps
    FROM sw.t_job_steps
    WHERE state IN (2, 9) AND           -- Enabled or Running Remote
          tool = _stepTool::citext;

    SELECT COUNT(step)
    INTO _candidatesPlusRunning
    FROM sw.t_job_steps
    WHERE state In (2, 4, 9) AND        -- Enabled, Running, or Running Remote
          tool = _stepTool::citext;

    -----------------------------------------------------------
    -- Compute the number of jobs that need to be released (un-held)
    -----------------------------------------------------------

    _jobsToRelease := _targetCandidates - _candidateSteps;

    If _candidatesPlusRunning + _jobsToRelease > _maxCandidatesPlusJobs Then
        RAISE INFO '';
        RAISE INFO 'Currently have % job steps enabled or running', _candidatesPlusRunning;
        RAISE INFO 'Would un-hold % steps to give % enabled, but then the total number running would be larger than %',
                    _jobsToRelease, _targetCandidates, _maxCandidatesPlusJobs;

        _jobsToRelease := _jobsToRelease - (_candidatesPlusRunning + _jobsToRelease - _maxCandidatesPlusJobs);

        If _jobsToRelease < 0 Then
            _jobsToRelease := 0;
        End If;
    End If;

    RAISE INFO 'Target candidates: %; Jobs to release: %', _targetCandidates, _jobsToRelease;

    If _targetCandidates = 1 And _jobsToRelease > 0 OR
       _targetCandidates >= 1 And _jobsToRelease >= 1 Then

        -----------------------------------------------------------
        -- Un-hold _jobsToRelease jobs
        -----------------------------------------------------------

        UPDATE sw.t_job_steps
        SET state = 2
        FROM ( SELECT JS.job, JS.step
               FROM sw.t_job_steps JS
               WHERE JS.state = 7 AND
                     JS.tool = _stepTool::citext
               ORDER BY JS.job
               LIMIT _jobsToRelease
             ) ReleaseQ
        WHERE sw.t_job_steps.job = ReleaseQ.job AND
              sw.t_job_steps.step = ReleaseQ.step AND
              sw.t_job_steps.state = 7;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        _message := format('Enabled %s job %s for processing', _updateCount, public.check_plural(_updateCount, 'step', 'steps'));

    Else
        _runningJobs := _candidatesPlusRunning - _candidateSteps;

        _message := format('Already have %s candidate job %s and %s running job %s; nothing to do',
                            _candidateSteps, public.check_plural(_candidateSteps, 'step', 'steps'),
                            _runningJobs,    public.check_plural(_runningJobs,    'step', 'steps'));
    End If;

END
$$;


ALTER PROCEDURE sw.unhold_candidate_job_steps(IN _steptool text, IN _targetcandidates integer, IN _maxcandidatesplusjobs integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE unhold_candidate_job_steps(IN _steptool text, IN _targetcandidates integer, IN _maxcandidatesplusjobs integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.unhold_candidate_job_steps(IN _steptool text, IN _targetcandidates integer, IN _maxcandidatesplusjobs integer, INOUT _message text, INOUT _returncode text) IS 'UnholdCandidateJobSteps';

