--
CREATE OR REPLACE PROCEDURE sw.unhold_candidate_job_steps
(
    _stepTool text = 'MASIC_Finnigan',
    _targetCandidates int = 15,
    _maxCandidatesPlusJobs int = 30,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Examines the number of step steps with state 2=Enabled
**      If less than _targetCandidates, updates job steps with state 7 to have state 2
**      such that we will have _targetCandidates enabled job steps for the given step tool
**
**  Auth:   mem
**  Date:   12/20/2011 mem - Initial version
**          04/24/2014 mem - Added parameter _maxCandidatesPlusJobs
**          05/13/2017 mem - Add step state 9 (Running_Remote)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _updateCount int;
    _candidateSteps int;
    _candidatesPlusRunning int;
    _jobsToRelease int;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    _stepTool := Coalesce(_stepTool, '');
    _targetCandidates := Coalesce(_targetCandidates, 250);

    -----------------------------------------------------------
    -- Count the number of job steps in state 2 for step tool _stepTool
    -----------------------------------------------------------
    --
    SELECT COUNT(*)
    INTO _candidateSteps
    FROM t_job_steps
    WHERE state IN (2, 9) AND
          tool = _stepTool;

    SELECT COUNT(*)
    INTO _candidatesPlusRunning
    FROM t_job_steps
    WHERE state In (2, 4, 9) AND
          tool = _stepTool;

    -----------------------------------------------------------
    -- Compute the number of jobs that need to be released (un-held)
    -----------------------------------------------------------

    _jobsToRelease := _maxCandidatesPlusJobs - _candidatesPlusRunning;

    If _jobsToRelease > _targetCandidates Then
        _jobsToRelease := _targetCandidates;
    End If;

    If _targetCandidates = 1 And _jobsToRelease > 0 OR
       _targetCandidates >= 1 And _jobsToRelease >= 1 Then

        -----------------------------------------------------------
        -- Un-hold _jobsToRelease jobs
        -----------------------------------------------------------

        UPDATE t_job_steps
        SET state = 2
        FROM sw.t_job_steps
             INNER JOIN ( SELECT CandidateSteps.job, CandidateSteps.step
                          FROM t_job_steps CandidateSteps
                          WHERE CandidateSteps.state = 7 AND
                                CandidateSteps.tool = _stepTool
                          ORDER BY CandidateSteps.job
                          LIMIT _jobsToRelease ) ReleaseQ
               ON sw.t_job_steps.job = ReleaseQ.job AND
                  sw.t_job_steps.step = ReleaseQ.step
        WHERE sw.t_job_steps.state = 7;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        _message := format('Enabled %s %s for processing', _updateCount, public.check_plural(_updateCount, 'job', 'jobs'));

    Else
        _runningJobs := _candidatesPlusRunning - _candidateSteps;

        _message := format('Already have %s candidate %s and %s running %s; nothing to do',
                            _candidateSteps, public.check_plural(_updateCount, 'job', 'jobs'),
                            _runningJobs,    public.check_plural(_runningJobs, 'job', 'jobs'));
    End If;

END
$$;

COMMENT ON PROCEDURE sw.unhold_candidate_job_steps IS 'UnholdCandidateJobSteps';
