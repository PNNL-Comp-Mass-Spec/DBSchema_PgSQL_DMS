--
CREATE OR REPLACE FUNCTION cap.preview_request_ctm_step_task
(
    _processorName text,
    _jobCountToPreview int = 10,
    INOUT _jobNumber int = 0,
    INOUT _message text default '',
    INOUT _returnCode text default ''
    _infoLevel int = 1
)
RETURNS Table (
    Parameter text,
    Value text
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Previews the next step task that would be returned for a given processor
**
**  Arguments:
**    _jobCountToPreview    The number of capture task jobs to preview
**    _jobNumber            Capture task job number that would be assigned; 0 if no job available
**    _parameters           Capture task job step parameters (as XML)
**    _infoLevel            0 or 1 to preview the assigned task; 2 to preview the task and see extra status messages; 3 to dump candidate tables and variables
**
**  Auth:   mem
**  Date:   01/06/2011 mem
**          07/26/2012 mem - Now looking up 'perspective' for the given manager and then passing _serverPerspectiveEnabled into RequestStepTask
**          12/15/2023 mem - Renamed parameter _infoOnly to _infoLevel and ported to PostgreSQL
**
*****************************************************/
DECLARE
    _serverPerspectiveEnabled int := 0; -- When 0, manager parameter 'perspective' is 'client', meaning the manager will use paths of the form \\proto-5\Exact04\2012_1
                                        -- When 1, manager parameter 'perspective' is 'server', meaning the manager will use paths of the form E:\Exact04\2012_1
    _perspective citext := '';
BEGIN
    _message := '';
    _returnCode := '';

    _infoLevel := Coalesce(_infoLevel, 1);

    If _infoLevel < 1 Then
        _infoLevel := 1;
    End If;

    -- Lookup the value for 'perspective' for this manager
    SELECT Parameter_Value
    INTO _perspective
    FROM mc.V_Mgr_Params
    WHERE Manager_Name = _processorName::citext AND Parameter_Name = 'perspective';

    If Not FOUND Then
        _message := format('The "Perspective" parameter was not found for manager "%s" in cap.V_Mgr_Params', _processorName);
    End If;

    If _perspective = 'server' Then
        _serverPerspectiveEnabled := 1;
    End If;

    RETURN QUERY
    SELECT Parameter, Value
    FROM cap.request_ctm_step_task (_processorName,
                                    _jobNumber                => _jobNumber,
                                    _message                  => _message,
                                    _infoLevel                => _infoLevel,
                                    _jobCountToPreview        => _jobCountToPreview,
                                    _serverPerspectiveEnabled => _serverPerspectiveEnabled,
                                    _returnCode               => _returnCode)

    If Exists (Select * FROM cap.t_tasks WHERE Job = _job) Then
        SELECT format('t_tasks Data for Job %s', _job) As Parameter,
               format('Dataset %s, Processor %s; %s', Dataset, _processorName, _message) As Value
        FROM cap.t_tasks
        WHERE Job = _job;
    End If;

    RAISE INFO '%', _message

END
$$;

COMMENT ON PROCEDURE cap.preview_request_ctm_step_task IS 'PreviewRequestStepTask';
