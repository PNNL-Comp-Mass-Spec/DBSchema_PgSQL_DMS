--
-- Name: unhold_candidate_msgf_job_steps(text, integer, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.unhold_candidate_msgf_job_steps(IN _steptool text DEFAULT 'MSGF'::text, IN _targetcandidates integer DEFAULT 25, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Examines the number of steps with state 2 and tool _stepTool (default MSGF)
**
**      If less than _targetCandidates have state 2 (enabled),
**      updates job steps with state 7 (holding) to have state 2,
**      such that we will have _targetCandidates enabled job steps for the given tool
**
**      Only updates jobs where the DataExtractor step has Tool_Version_ID >= 82 and is complete
**
**  Arguments:
**    _stepTool             Step tool name
**    _targetCandidates     Number of steps that should have state 2
**
**  Auth:   mem
**  Date:   12/20/2011 mem - Initial version
**          05/12/2017 mem - Update Tool_Version_ID, Next_Try, and Remote_Info_ID
**          08/12/2023 mem - Ported to PostgreSQL
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

        UPDATE sw.t_job_steps
        SET state = 2,
            tool_version_id = 1,            -- 1=Unknown
            next_try = CURRENT_TIMESTAMP,
            remote_info_id = 1              -- 1=Unknown
        FROM ( SELECT JS.job,
                      JS.step
               FROM sw.t_job_steps JS
                    INNER JOIN sw.t_job_steps ExtractQ
                      ON JS.job = ExtractQ.job AND
                         ExtractQ.tool = 'DataExtractor'
               WHERE JS.state = 7 AND
                     JS.tool = _stepTool::citext AND
                     ExtractQ.state = 5 AND
                     ExtractQ.tool_version_id >= 82
               ORDER BY job DESC
               LIMIT _jobsToRelease
             ) ReleaseQ
        WHERE sw.t_job_steps.job = ReleaseQ.job AND
              sw.t_job_steps.step = ReleaseQ.step AND
              sw.t_job_steps.state = 7;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        _message := format('Enabled %s job %s for processing', _updateCount, public.check_plural(_updateCount, 'step', 'steps'));
    Else
        _message := format('Already have %s candidate job %s; nothing to do', _candidateSteps, public.check_plural(_candidateSteps, 'step', 'steps'));
    End If;

END
$$;


ALTER PROCEDURE sw.unhold_candidate_msgf_job_steps(IN _steptool text, IN _targetcandidates integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE unhold_candidate_msgf_job_steps(IN _steptool text, IN _targetcandidates integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.unhold_candidate_msgf_job_steps(IN _steptool text, IN _targetcandidates integer, INOUT _message text, INOUT _returncode text) IS 'UnholdCandidateMSGFJobSteps';

