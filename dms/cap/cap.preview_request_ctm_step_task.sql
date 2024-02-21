--
-- Name: preview_request_ctm_step_task(text, integer, integer); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.preview_request_ctm_step_task(_processorname text, _jobcounttopreview integer DEFAULT 10, _infolevel integer DEFAULT 1) RETURNS TABLE(parameter text, value text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Preview the next capture task job step that would be assigned to the given processor
**
**  Arguments:
**    _processorName        Name of the processor (aka manager) requesting a job
**    _jobCountToPreview    The number of capture task jobs to preview
**    _infoLevel            0 or 1 to preview the assigned task; 2 to preview the task and see extra status messages; 3 to dump candidate tables and variables
**
**  Example usage:
**    SELECT * FROM cap.preview_request_ctm_step_task('Proto-3_CTM', _jobCountToPreview => 10, _infoLevel => 1);
**    SELECT * FROM cap.preview_request_ctm_step_task('Proto-3_CTM', _jobCountToPreview => 5,  _infoLevel => 2);
**
**  Auth:   mem
**  Date:   01/06/2011 mem
**          07/26/2012 mem - Now looking up 'perspective' for the given manager and then passing _serverPerspectiveEnabled into RequestStepTask
**          06/06/2023 mem - No longer looking up "perspective" for the given manager, since the Capture Task Manager
**                           does not customize the value of @serverPerspectiveEnabled when calling request_ctm_step_task
**          06/07/2023 mem - Renamed parameter _infoOnly to _infoLevel and ported to PostgreSQL
**
*****************************************************/
DECLARE
    _job int;
    _results refcursor;
    _message text;
    _returnCode text;
    _jobParams record;
BEGIN
    _message := '';
    _returnCode := '';

    _infoLevel := Coalesce(_infoLevel, 1);

    If _infoLevel < 1 Then
        _infoLevel := 1;
    End If;

    /*
     * Deprecated in June 2023
     *

    _serverPerspectiveEnabled int := 0; -- When 0, manager parameter 'perspective' is 'client', meaning the manager will use paths of the form \\proto-5\Exact04\2012_1
                                        -- When 1, manager parameter 'perspective' is 'server', meaning the manager will use paths of the form E:\Exact04\2012_1
    _perspective citext := '';

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

    */

    CALL cap.request_ctm_step_task (
                _processorName     => _processorName,
                _jobNumber         => _job,
                _results           => _results,
                _message           => _message,     -- Output
                _returnCode        => _returnCode,  -- Output
                _infoLevel         => _infoLevel,
                _managerVersion    => '',
                _jobCountToPreview => _jobCountToPreview
            );

    If _job > 0 Then
        RETURN QUERY
        SELECT format('Would assign capture task job %s to processor %s', Job, _processorName) AS Parameter,
               format('Dataset: %s', Dataset) AS Value
        FROM cap.t_tasks
        WHERE Job = _job;
    ElsIf Coalesce(_message, '') <> '' Then
        RETURN QUERY
        SELECT _message, '';
    Else
        RETURN QUERY
        SELECT 'cap.request_ctm_step_task did not find a capture task job to process, and _message is empty', '';
    End If;

    WHILE NOT _results IS NULL
    LOOP
        FETCH NEXT FROM _results
        INTO _jobParams;

        If Not FOUND Then
             EXIT;
        End If;

        RETURN QUERY
        SELECT _jobParams.Parameter,
               _jobParams.Value;

    END LOOP;

END
$$;


ALTER FUNCTION cap.preview_request_ctm_step_task(_processorname text, _jobcounttopreview integer, _infolevel integer) OWNER TO d3l243;

