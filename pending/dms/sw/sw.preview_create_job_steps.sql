--
CREATE OR REPLACE PROCEDURE sw.preview_create_job_steps
(
    _jobToPreview int = 0,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Previews the job steps that would be created
**
**      If _jobToPreview = 0, previews the steps for any jobs with state = 0 in T_Jobs
**          Generally, there won't be any jobs with a state of 0, since SP UpdateContext runs once per minute,
**          and it calls CreateJobSteps to create steps for any jobs with state = 0, after which the job state is changed to 1
**
**      If _jobToPreview is non-zero, previews the steps for the given job in T_Jobs (regardless of its state)
**
**  Auth:   mem
**  Date:   02/08/2009 mem - Initial version
**          03/11/2009 mem - Updated call to CreateJobSteps (Ticket #725, http://prismtrac.pnl.gov/trac/ticket/725)
**          03/21/2011 mem - Now passing _infoOnly = true to CreateJobSteps
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _stepCount int := 0;
    _stepCountNew int := 0;
BEGIN
    _message := '';
    _returnCode:= '';

    _jobToPreview := Coalesce(_jobToPreview, 0);

    Call sw.create_job_steps (
            _message => _message,           -- Output
            _returnCode => _returnCode,     -- Output
            _existingJob => _jobToPreview,
            _infoOnly => true,
            _debugMode => true);

END
$$;

COMMENT ON PROCEDURE sw.preview_create_job_steps IS 'PreviewCreateJobSteps';
