--
CREATE OR REPLACE PROCEDURE sw.get_job_step_input_folder
(
    _job int,
    _jobStep int = null,
    _stepToolFilter text = null,
    INOUT _inputFolderName text = '',
    INOUT _stepToolMatch text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Returns the input folder for a given job and optionally job step
**      Useful for determining the input folder for MSGF+ or MzRefinery
**      Use _jobStep and/or _stepToolFilter to specify which job step to target
**
**      If _jobStep is 0 (or null) and _stepToolFilter is '' (or null) preferentially returns
**      the input folder for the primary step tool used by a job (e.g. MSGFPlus)
**
**      First looks for completed job steps in T_Job_Steps
**      If no match, looks in T_Job_Steps_History
**
**  Arguments:
**    _job               Job to search
**    _jobStep           Optional job step; 0 or null to use the folder associated with the highest job step
**    _stepToolFilter    Optional filter, like Mz_Refinery or MSGFPlus
**    _inputFolderName   Matched InputFolder, or '' if no match
**
**  Auth:   mem
**  Date:   02/02/2017 mem - Initial release
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _message text;
BEGIN
    _message := '';
    _returnCode := '';

    _job := Coalesce(_job, 0);
    _jobStep := Coalesce(_jobStep, 0);
    _stepToolFilter := Coalesce(_stepToolFilter, '');
    _inputFolderName := '';
    _stepToolMatch := '';

    ---------------------------------------------------
    -- First look in sw.t_job_steps
    ---------------------------------------------------
    --
    SELECT JS.input_folder_name,
           JS.Tool
    INTO _inputFolderName, _stepToolMatch
    FROM sw.t_job_steps JS
         INNER JOIN sw.t_step_tools ST
           ON JS.tool = ST.step_tool
    WHERE NOT JS.tool IN ('Results_Transfer') AND
          JS.job = _job AND
          (_jobStep <= 0 OR
          JS.step = _jobStep) AND
          (_stepToolFilter = '' OR
          JS.tool = _stepToolFilter)
    ORDER BY ST.primary_step_tool DESC, step DESC
    LIMIT 1;

    If Not FOUND Then
        -- No match; try sw.t_job_steps_history
        SELECT JSH.input_folder_name,
               JSH.tool
        INTO _inputFolderName, _stepToolMatch
        FROM sw.t_job_steps_history JSH
             INNER JOIN sw.t_step_tools ST
               ON JSH.tool = ST.step_tool
        WHERE NOT JSH.tool IN ('Results_Transfer') AND
              JSH.job = _job AND
              (_jobStep <= 0 OR
              JSH.step = _jobStep) AND
              (_stepToolFilter = '' OR
              JSH.tool = _stepToolFilter)
        ORDER BY ST.primary_step_tool DESC, JSH.step DESC
        LIMIT 1;

    End If;

END
$$;

COMMENT ON PROCEDURE sw.get_job_step_input_folder IS 'GetJobStepInputFolder';
