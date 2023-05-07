--
CREATE OR REPLACE PROCEDURE sw.get_job_step_param_value
(
    _job int,
    _step int,
    _section text = '',
    _paramName text = '',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    INOUT _firstParameterValue text = '',
    _debugMode boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Get a single job step parameter value
**
**  Note: Data comes from sw.T_Job_Parameters, not from the public schema tables
**
**  Arguments:
**    _section               Optional section name to filter on, for example: JobParameters
**    _paramName             Parameter name to find, for example: SourceJob
**    _firstParameterValue   The value of the first parameter matched in the retrieved job parameters
**
**  Auth:   mem
**  Date:   03/09/2021 mem - Initial release
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
BEGIN
    _message := '';
    _returnCode := '';

    _firstParameterValue := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _section := Coalesce(_section, '');
    _paramName := Coalesce(_paramName, '');

    If _paramName= '' Then
        _message := '_paramName cannot be empty';
        _returnCode := 'U5400';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Temporary table to hold job parameters
    ---------------------------------------------------
    --
    CREATE TEMP TABLE Tmp_JobParamsTable (
        Section text,
        Name text,
        Value text
    )

    ---------------------------------------------------
    -- Call get_job_step_params_work to populate the temporary table
    ---------------------------------------------------

    Call sw.get_job_step_params_work (
            _job,
            _step,
            _message => _message,           -- Output
            _returnCode => _returnCode,     -- Output
            _debugMode => _debugMode);

    If _returnCode <> '' Then
        DROP TABLE Tmp_JobParamsTable;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Possibly filter the parameters
    ---------------------------------------------------

    If _section <> '' Then
        DELETE FROM Tmp_JobParamsTable
        WHERE Not Section Like _section
    End If;

    If _paramName <> '' Then
        DELETE FROM Tmp_JobParamsTable
        WHERE Not Name Like _paramName
    End If;

    ---------------------------------------------------
    -- Find the value for the first parameter (sorting on section name then parameter name)
    ---------------------------------------------------

    SELECT Value
    INTO _firstParameterValue
    FROM Tmp_JobParamsTable
    ORDER BY Section, Name
    LIMIT 1;

    DROP TABLE Tmp_JobParamsTable;

END
$$;

COMMENT ON PROCEDURE sw.get_job_step_param_value IS 'GetJobStepParamValue';
