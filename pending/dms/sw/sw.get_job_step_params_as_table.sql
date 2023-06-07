--
CREATE OR REPLACE FUNCTION sw.get_job_step_params_as_table
(
    _job int,
    _step int,
    _section text = '',
    _paramName text = '',
    _debugMode boolean = false
)
RETURNS TABLE (
    Section text,
    Name text,
    Value text
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Get job step parameters for given job step
**
**      Data comes from sw.T_Job_Parameters, not from the public schema tables
**
**  Arguments:
**    _section               Optional section name to filter on, for example: JobParameters
**    _paramName             Optional parameter name to filter on, for example: SourceJob
**
**  Auth:   mem
**  Date:   12/04/2009 mem - Initial release
**          01/05/2018 mem - Add parameters _section, _paramName, and _firstParameterValue
**          02/12/2020 mem - Allow _section and _paramName to have wildcards
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
BEGIN

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
    );

    ---------------------------------------------------
    -- Query get_job_step_params_work to populate the temporary table
    ---------------------------------------------------

    INSERT INTO Tmp_JobParamsTable (Section, Name, Value)
    SELECT Section, Name, Value
    FROM sw.get_job_step_params_work (_job, _step);

    If Not FOUND Then
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

    RETURN QUERY
    SELECT Section, Name, Value
    FROM Tmp_JobParamsTable
    ORDER BY Section, Name, Value;

    DROP TABLE Tmp_JobParamsTable;

END
$$;

COMMENT ON FUNCTION sw.get_job_step_params_as_table IS 'GetJobStepParamsAsTable';
