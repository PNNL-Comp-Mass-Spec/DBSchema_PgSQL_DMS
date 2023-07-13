--
CREATE OR REPLACE PROCEDURE sw.unhold_candidate_msgf_job_steps
(
    _stepTool text = 'MSGF',
    _targetCandidates int = 25,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Examines the number of MSGF step steps with state 2
**      If less than _targetCandidates, updates job steps with state 7 to have state 2
**      such that we will have _targetCandidates enabled job steps for MSGF
**
**      Only updates jobs where the DataExtractor step has Tool_Version_ID >= 82 and is complete
**
**  Auth:   mem
**  Date:   12/20/2011 mem - Initial version
**          05/12/2017 mem - Update Tool_Version_ID, Next_Try, and Remote_Info_ID
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _updateCount int;
    _candidateSteps int;
    _jobsToRelease int;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    _stepTool := Coalesce(_stepTool, '');
    _targetCandidates := Coalesce(_targetCandidates, 25);

    -----------------------------------------------------------
    -- Count the number of job steps in state 2 for step tool _stepTool
    -----------------------------------------------------------

    SELECT COUNT(step)
    INTO _candidateSteps
    FROM t_job_steps
    WHERE state = 2 AND
          tool = _stepTool::citext;

    -----------------------------------------------------------
    -- Compute the number of jobs that need to be released (un-held)
    -----------------------------------------------------------
    _jobsToRelease := _targetCandidates - _candidateSteps;

    If _targetCandidates = 1 And _jobsToRelease > 0 OR
       _targetCandidates > 1 And _jobsToRelease > 1 Then
        -----------------------------------------------------------
        -- Un-hold _jobsToRelease jobs
        -----------------------------------------------------------

        UPDATE t_job_steps
        SET state = 2,
            tool_version_id = 1,        -- 1=Unknown
            next_try = CURRENT_TIMESTAMP,
            remote_info_id = 1            -- 1=Unknown
        FROM sw.t_job_steps
             INNER JOIN ( SELECT JS_MSGF.job,
                                 JS_MSGF.step
                          FROM sw.t_job_steps JS_MSGF
                               INNER JOIN sw.t_job_steps ExtractQ
                                 ON JS_MSGF.job = ExtractQ.job
                                    AND
                                    ExtractQ.tool = 'DataExtractor'
                          WHERE JS_MSGF.state = 7 AND
                                JS_MSGF.tool = _stepTool::citext AND
                                ExtractQ.state = 5 AND
                                ExtractQ.tool_version_id >= 82
                          ORDER BY job DESC
                          LIMIT _jobsToRelease ) ReleaseQ
               ON sw.t_job_steps.job = ReleaseQ.job AND
                  sw.t_job_steps.step = ReleaseQ.step
        WHERE sw.t_job_steps.state = 7
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        _message := format('Enabled %s %s for processing', _updateCount, public.check_plural(_updateCount, 'job', 'jobs'));
    Else
        _message := format('Already have %s candidate %s; nothing to do', _candidateSteps, public.check_plural(_candidateSteps, 'job', 'jobs'));
    End If;

END
$$;

COMMENT ON PROCEDURE sw.unhold_candidate_msgf_job_steps IS 'UnholdCandidateMSGFJobSteps';
