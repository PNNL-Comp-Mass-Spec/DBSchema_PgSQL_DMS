--
CREATE OR REPLACE FUNCTION sw.preview_request_step_task
(
    _processorName text,
    _jobCountToPreview int = 10,
    INOUT _job int = 0,
    INOUT _parameters text = '',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoLevel int = 1
)
RETURNS TABLE (
    Job_Number int,
    Dataset text,
    Processor text,
    Parameters text,
    Message text
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Previews the next step task that would be returned for a given processor
**
**  Arguments:
**    _jobCountToPreview    The number of jobs to preview
**    _job                  Job number assigned; 0 if no job available
**    _parameters           Job step parameters (in XML)
**    _infoLevel            1 to preview the assigned task; 2 to preview the task and see extra status messages
**
**  Auth:   mem
**  Date:   12/05/2008 mem
**          01/15/2009 mem - Updated to only display the job info if a job is assigned (Ticket #716, http://prismtrac.pnl.gov/trac/ticket/716)
**          08/23/2010 mem - Added parameter _infoOnly
**          05/18/2017 mem - Call Get_Default_Remote_Info_For_Manager to retrieve the _remoteInfo XML for _processorName
**                           Pass this to RequestStepTaskXML
**                           (Get_Default_Remote_Info_For_Manager is a synonym for the procedure in the Manager_Control DB)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _remoteInfo text;
BEGIN
    _message := '';
    _returnCode := '';

    _infoLevel := Coalesce(_infoLevel, 1);

    If _infoLevel < 1 Then
        _infoLevel := 1;
    End If;

    CALL mc.get_default_remote_info_for_manager (_processorName, _remoteInfoXML => _remoteInfo);

    CALL sw.request_step_task_xml (
            _processorName,
            _job => _job,                   -- Output
            _parameters => _parameters,     -- Output
            _message => _message,           -- Output
            _infoLevel = _infoLevel,
            _jobCountToPreview = _jobCountToPreview,
            _remoteInfo = _remoteInfo);

    If Exists (Select * FROM sw.t_jobs WHERE job = _job) Then
        RETURN QUERY
        SELECT _job AS JobNumber,
               dataset,
               _processorName AS Processor,
               _parameters AS Parameters,
               _message AS Message
        FROM sw.t_jobs
        WHERE job = _job;
    Else
        RETURN QUERY
        SELECT 0 AS JobNumber,
               '' AS dataset,
               '' AS Processor,
               '' AS Parameters,
               _message AS Message
        FROM sw.t_jobs;
    End If;

END
$$;

COMMENT ON PROCEDURE sw.preview_request_step_task IS 'PreviewRequestStepTask';
