--
-- Name: preview_create_job_steps(integer, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.preview_create_job_steps(IN _jobtopreview integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Preview the job steps that would be created
**
**      Calling this procedure with _jobToPreview = 0 will typically not show any results, since there usually aren't any jobs with a state of 0,
**      since procedure sw.update_context runs once per minute, and it calls sw.create_job_steps to create steps for any jobs with state = 0,
**      after which the job state is changed to 1
**
**  Arguments:
**    _jobToPreview     When 0, preview the steps for any jobs with state = 0 in sw.t_jobs;
**                      When non-zero, preview the steps for the given job in sw.t_jobs (regardless of its state)
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   02/08/2009 mem - Initial version
**          03/11/2009 mem - Updated call to Create_Job_Steps (Ticket #725, http://prismtrac.pnl.gov/trac/ticket/725)
**          03/21/2011 mem - Now passing _infoOnly = true to Create_Job_Steps
**          08/03/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _stepCount int := 0;
    _stepCountNew int := 0;
BEGIN
    _message := '';
    _returnCode := '';

    _jobToPreview := Coalesce(_jobToPreview, 0);

    CALL sw.create_job_steps (
                _message     => _message,       -- Output
                _returnCode  => _returnCode,    -- Output
                _existingJob => _jobToPreview,
                _infoOnly    => true,
                _debugMode   => true);

END
$$;


ALTER PROCEDURE sw.preview_create_job_steps(IN _jobtopreview integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE preview_create_job_steps(IN _jobtopreview integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.preview_create_job_steps(IN _jobtopreview integer, INOUT _message text, INOUT _returncode text) IS 'PreviewCreateJobSteps';

