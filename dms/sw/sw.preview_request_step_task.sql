--
-- Name: preview_request_step_task(text, integer, integer); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.preview_request_step_task(_processorname text, _jobcounttopreview integer DEFAULT 10, _infolevel integer DEFAULT 1) RETURNS TABLE(job_number integer, dataset public.citext, processor text, parameters text, message text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Preview the next analysis job step that would be assigned to the given processor
**
**  Arguments:
**    _processorName        Name of the processor (aka manager) requesting a job
**    _jobCountToPreview    The number of jobs to preview when _infoLevel >= 1
**    _infoLevel            0 or 1 to preview the job step that would be assigned; if 2, show additional messages
**
**  Auth:   mem
**  Date:   12/05/2008 mem
**          01/15/2009 mem - Updated to only display the job info if a job is assigned (Ticket #716, http://prismtrac.pnl.gov/trac/ticket/716)
**          08/23/2010 mem - Added parameter _infoOnly
**          05/18/2017 mem - Call Get_Default_Remote_Info_For_Manager to retrieve the _remoteInfo XML for _processorName
**                           Pass this to Request_Step_Task_XML
**          06/10/2023 mem - Ported to PostgreSQL
**          08/03/2024 mem - Fix bug referencing sw.t_jobs when no job was assigned
**
*****************************************************/
DECLARE
    _message text;
    _returnCode text;
    _remoteInfo text;
    _job int;
    _parameters text;
BEGIN
    _message := '';

    _infoLevel := Coalesce(_infoLevel, 1);

    If _infoLevel < 1 Then
        _infoLevel := 1;
    End If;

    RAISE INFO '';

    CALL sw.get_default_remote_info_for_manager (
                _processorName,
                _remoteInfoXML => _remoteInfo); -- Output

    CALL sw.request_step_task_xml (
                _processorName,
                _job               => _job,                 -- Output
                _parameters        => _parameters,          -- Output
                _message           => _message,             -- Output
                _returnCode        => _returnCode,          -- Output
                _infoLevel         => _infoLevel,
                _jobCountToPreview => _jobCountToPreview,
                _remoteInfo        => _remoteInfo);

    If Exists (Select job FROM sw.t_jobs WHERE job = _job) Then
        RETURN QUERY
        SELECT _job AS JobNumber,
               J.Dataset,
               _processorName AS Processor,
               _parameters AS Parameters,
               _message AS Message
        FROM sw.t_jobs J
        WHERE J.job = _job;
    Else
        RETURN QUERY
        SELECT 0 AS JobNumber,
               ''::citext AS Dataset,
               '' AS Processor,
               '' AS Parameters,
               _message AS Message;
    End If;

END
$$;


ALTER FUNCTION sw.preview_request_step_task(_processorname text, _jobcounttopreview integer, _infolevel integer) OWNER TO d3l243;

--
-- Name: FUNCTION preview_request_step_task(_processorname text, _jobcounttopreview integer, _infolevel integer); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON FUNCTION sw.preview_request_step_task(_processorname text, _jobcounttopreview integer, _infolevel integer) IS 'PreviewRequestStepTask';

