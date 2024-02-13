--
-- Name: get_job_step_input_folder(integer, integer, text, text, text, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.get_job_step_input_folder(IN _job integer, IN _jobstep integer DEFAULT NULL::integer, IN _steptoolfilter text DEFAULT NULL::text, INOUT _inputfoldername text DEFAULT ''::text, INOUT _steptoolmatch text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return the input folder for a given job and optionally job step or tool name
**
**      Class DataPackageFileHandler in the Analysis Manager uses this procedure to determine the input folder for MS-GF+ and MzRefinery.
**      Use _jobStep and/or _stepToolFilter to specify which job step to target.
**      Ignores 'Results_Transfer' job steps, but updates _message if the given job step is a Results_Transfer step.
**
**      If _jobStep is 0 (or null) and _stepToolFilter is '' (or null),
**      this procedure returns the input folder for the primary step tool used by a job (e.g. MSGFPlus)
**
**      First looks for completed job steps in sw.t_job_steps; if no match, looks in sw.t_job_steps_history
**
**  Arguments:
**    _job               Job to search
**    _jobStep           Optional job step filter; 0 or null to use the folder associated with the highest job step
**    _stepToolFilter    Optional filter, like 'Mz_Refinery' or 'MSGFPlus'
**    _inputFolderName   Output: Matched input folder, or '' if no match
**    _stepToolMatch     Output: Matched step tool
**    _message           Status message
**    _returnCode        Return code
**
**  Auth:   mem
**  Date:   02/02/2017 mem - Initial release
**          08/08/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _jobStepMatch int;
BEGIN
    _message := '';
    _returnCode := '';

    _job := Coalesce(_job, 0);
    _jobStep := Coalesce(_jobStep, 0);
    _stepToolFilter := Trim(Coalesce(_stepToolFilter, ''));
    _inputFolderName := '';
    _stepToolMatch := '';

    ---------------------------------------------------
    -- First look in sw.t_job_steps
    ---------------------------------------------------

    SELECT JS.input_folder_name,
           JS.Tool
    INTO _inputFolderName, _stepToolMatch
    FROM sw.t_job_steps JS
         INNER JOIN sw.t_step_tools ST
           ON JS.tool = ST.step_tool
    WHERE NOT JS.tool IN ('Results_Transfer') AND
          JS.job = _job AND
          (_jobStep <= 0 OR JS.step = _jobStep) AND
          (_stepToolFilter = '' OR JS.tool = _stepToolFilter)
    ORDER BY ST.primary_step_tool DESC, step DESC
    LIMIT 1;

    If FOUND Then
        RETURN;
    End If;

    ---------------------------------------------------
    -- Match not found; try sw.t_job_steps_history
    ---------------------------------------------------

    SELECT JSH.input_folder_name,
           JSH.tool
    INTO _inputFolderName, _stepToolMatch
    FROM sw.t_job_steps_history JSH
         INNER JOIN sw.t_step_tools ST
           ON JSH.tool = ST.step_tool
    WHERE NOT JSH.tool IN ('Results_Transfer') AND
          JSH.job = _job AND
          (_jobStep <= 0 OR JSH.step = _jobStep) AND
          (_stepToolFilter = '' OR JSH.tool = _stepToolFilter)
    ORDER BY ST.primary_step_tool DESC, JSH.step DESC
    LIMIT 1;

    If FOUND then
        RETURN;
    End If;

    ---------------------------------------------------
    -- Match not found; do the filters matching a Results_Transfer job step?
    ---------------------------------------------------

    SELECT JS.step, JS.input_folder_name
    INTO _jobStepMatch, _inputFolderName
    FROM sw.t_job_steps JS
         INNER JOIN sw.t_step_tools ST
           ON JS.tool = ST.step_tool
    WHERE JS.tool IN ('Results_Transfer') AND
          JS.job = _job AND
          (_jobStep <= 0 OR JS.step = _jobStep) AND
          (_stepToolFilter = '' OR JS.tool = _stepToolFilter)
    ORDER BY ST.primary_step_tool DESC, step DESC
    LIMIT 1;

    If FOUND Then
        _message := format('The only matching job step for the specified filters is a Results_Transfer step: Job %s, Step %s, Input_Folder %s',
                            _job, _jobStepMatch, _inputFolderName);

        _inputFolderName := '';
        RETURN;
    End If;

    SELECT JSH.step, JSH.input_folder_name
    INTO _jobStepMatch, _inputFolderName
    FROM sw.t_job_steps_history JSH
         INNER JOIN sw.t_step_tools ST
           ON JSH.tool = ST.step_tool
    WHERE JSH.tool IN ('Results_Transfer') AND
          JSH.job = _job AND
          (_jobStep <= 0 OR JSH.step = _jobStep) AND
          (_stepToolFilter = '' OR JSH.tool = _stepToolFilter)
    ORDER BY ST.primary_step_tool DESC, JSH.step DESC
    LIMIT 1;

    If FOUND Then
        _message := format('The only matching job step for the specified filters is a Results_Transfer step: Job %s, Step %s, Input_Folder %s',
                            _job, _jobStepMatch, _inputFolderName);

        _inputFolderName := '';
        RETURN;
    End If;

    If _jobStep > 0 And _stepToolFilter <> '' Then
        _message := format('Match not found for Job %s, Step %s, and Tool %s', _job, _jobStep, _stepToolFilter);
    ElsIf _jobStep > 0 Then
        _message := format('Match not found for Job %s and Step %s', _job, _jobStep);
    ElsIf _stepToolFilter <> '' Then
        _message := format('Match not found for Job %s and Tool %s', _job, _stepToolFilter);
    Else
        _message := format('Match not found for Job %s (_jobStep is 0 and _stepToolFilter is undefined)', _job);
    End If;

END
$$;


ALTER PROCEDURE sw.get_job_step_input_folder(IN _job integer, IN _jobstep integer, IN _steptoolfilter text, INOUT _inputfoldername text, INOUT _steptoolmatch text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE get_job_step_input_folder(IN _job integer, IN _jobstep integer, IN _steptoolfilter text, INOUT _inputfoldername text, INOUT _steptoolmatch text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.get_job_step_input_folder(IN _job integer, IN _jobstep integer, IN _steptoolfilter text, INOUT _inputfoldername text, INOUT _steptoolmatch text, INOUT _message text, INOUT _returncode text) IS 'GetJobStepInputFolder';

