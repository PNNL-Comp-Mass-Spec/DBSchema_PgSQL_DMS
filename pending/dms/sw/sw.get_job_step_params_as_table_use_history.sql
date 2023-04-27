--
CREATE OR REPLACE PROCEDURE sw.get_job_step_params_as_table_use_history
(
    _job int,
    _step int,
    _section text = '',
    _paramName text = '',
    INOUT _message text = '',
    INOUT _returnCode text = '',
    INOUT _firstParameterValue text = '',
    _debugMode boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Get job step parameters for given job step
**
**  Note: Data comes from sw.T_Job_Parameters_History, not from the public schema tables
**
**  Arguments:
**    _section               Optional section name to filter on, for example: JobParameters
**    _paramName             Optional parameter name to filter on, for example: SourceJob
**    _firstParameterValue   The value of the first parameter in the retrieved job parameters; useful when using both _section and _paramName
**
**  Auth:   mem
**  Date:   07/31/2013 mem - Initial release
**          01/05/2018 mem - Add parameters _section, _paramName, and _firstParameterValue
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
BEGIN
    _message := '';
    _returnCode := '';

    _firstParameterValue := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _section := Coalesce(_section, '');
    _paramName := Coalesce(_paramName, '');

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
    -- Call get_job_step_params_from_history_work to populate the temporary table
    ---------------------------------------------------

    Call sw.get_job_step_params_from_history_work (
                _job,
                _step,
                _message => _message,           -- Output
                _returnCode => _returnCode,     -- Output
                _debugMode => _debugMode)

    If _returnCode <> '' Then
        DROP TABLE Tmp_JobParamsTable;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Possibly filter the parameters
    ---------------------------------------------------

    If _section <> '' Then
        DELETE FROM Tmp_JobParamsTable
        WHERE Section <> _section
    End If;

    If _paramName <> '' Then
        DELETE FROM Tmp_JobParamsTable
        WHERE Name <> _paramName
    End If;

    ---------------------------------------------------
    -- Cache the first parameter value (sorting on section name then parameter name)
    ---------------------------------------------------

    SELECT Value
    INTO _firstParameterValue
    FROM Tmp_JobParamsTable
    ORDER BY Section, Name
    LIMIT 1;

    ---------------------------------------------------
    -- Return the contents of Tmp_JobParamsTable
    ---------------------------------------------------

    SELECT *
    FROM Tmp_JobParamsTable
    ORDER BY Section, Name, Value

    DROP TABLE Tmp_JobParamsTable;

END
$$;

COMMENT ON PROCEDURE sw.get_job_step_params_as_table_use_history IS 'GetJobStepParamsAsTableUseHistory';
