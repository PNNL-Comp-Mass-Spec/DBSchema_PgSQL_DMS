--
-- Name: update_job_parameters(integer, boolean, text, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.update_job_parameters(IN _job integer, IN _infoonly boolean DEFAULT false, IN _settingsfileoverride text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update the parameters in T_Job_Parameters for the specified job
**
**      Note: The job parameters come from the public schema tables
**            (via Create_Parameters_For_Job and then Get_Job_Param_Table),
**            and not from the T_Job_Parameters table local to this DB
**
**  Arguments:
**    _job                      Job number
**    _infoOnly                 When true, preview updates
**    _settingsFileOverride     When defined, will use this settings file name instead of the one obtained with public.v_get_pipeline_job_parameters (in Get_Job_Param_Table)
**    _message                  Status message
**    _returnCode               Return code
**
**  Auth:   mem
**  Date:   01/24/2009
**          02/08/2009 grk - Modified to call Create_Parameters_For_Job
**          01/05/2010 mem - Added parameter _settingsFileOverride
**          03/21/2011 mem - Now calling Update_Input_Folder_Using_Source_Job_Comment
**          04/04/2011 mem - Now calling Update_Input_Folder_Using_Special_Processing_Param
**          01/11/2012 mem - Updated to support _xmlParameters being null, which will be the case for a job created directly in the pipeline database
**          07/25/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**
*****************************************************/
DECLARE
    _debugMode boolean;
    _xmlParameters xml;
    _showResultsMode int;
BEGIN
    _message := '';
    _returnCode := '';

    ----------------------------------------------
    -- Validate the inputs
    ----------------------------------------------

    If _job Is Null Then
        _message := '_job cannot be null';
        _returnCode := 'U5301';
        RETURN;
    End If;

    _infoOnly             := Coalesce(_infoOnly, true);
    _settingsFileOverride := Trim(Coalesce(_settingsFileOverride, ''));

    -- Make sure _job exists in sw.t_jobs
    If Not Exists (SELECT job FROM sw.t_jobs WHERE job = _job) Then
        _message := format('Job %s not found in sw.t_jobs', _job);
        _returnCode := 'U5302';
        RETURN;
    End If;

    ----------------------------------------------
    -- Get the job parameters as XML
    ----------------------------------------------

    CREATE TEMP TABLE Job_Parameters (
        Job int NOT NULL,
        Parameters xml NULL
    );

    _debugMode := _infoOnly;

    -- Get parameters for the job as XML

    _xmlParameters := sw.create_parameters_for_job (
                            _job,
                            _settingsFileOverride => _settingsFileOverride,
                            _debugMode            => _debugMode);

    If _infoOnly Then
        RAISE INFO '';
        RAISE INFO 'Parameters for job %: %', _job, _xmlParameters;
    Else
        -- Update sw.t_job_parameters (or insert a new row if the job isn't present)

        If Exists (SELECT job FROM sw.t_job_parameters WHERE job = _job) Then
            UPDATE sw.t_job_parameters
            SET Parameters = Coalesce(_xmlParameters, Parameters)
            WHERE Job = _job;
        Else
            INSERT INTO sw.t_job_parameters (job, parameters)
            VALUES (_job, _xmlParameters);
        End If;

    End If;

    ----------------------------------------------
    -- Possibly update the input folder using the
    -- Special_Processing param in the job parameters
    ----------------------------------------------

    If _infoOnly Then
        _showResultsMode := 1;
    Else
        _showResultsMode := 0;
    End If;

    CALL sw.update_input_folder_using_special_processing_param (
                _jobList         => _job::text,
                _infoOnly        => _infoOnly,
                _showResultsMode => _showResultsMode,
                _message         => _message,           -- Output
                _returnCode      => _returnCode);       -- Output

    If _infoOnly And _message <> '' Then
        RAISE INFO '%', _message;
    End If;

    DROP TABLE Job_Parameters;
END
$$;


ALTER PROCEDURE sw.update_job_parameters(IN _job integer, IN _infoonly boolean, IN _settingsfileoverride text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_job_parameters(IN _job integer, IN _infoonly boolean, IN _settingsfileoverride text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.update_job_parameters(IN _job integer, IN _infoonly boolean, IN _settingsfileoverride text, INOUT _message text, INOUT _returncode text) IS 'UpdateJobParameters';

