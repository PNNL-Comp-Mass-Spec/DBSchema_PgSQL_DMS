--
-- Name: get_job_step_param_value(integer, integer, text, text); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.get_job_step_param_value(_job integer, _step integer, _paramname text DEFAULT ''::text, _section text DEFAULT ''::text) RETURNS TABLE(section public.citext, name public.citext, value public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Get a single job step parameter value, given the parameter name (supports wildcards)
**      If multiple sections have the same parameter, returns the first one (sorting by Section name)
**      To see all of the parameters that match a wildcard-based name, use sw.get_job_step_params_as_table()
**
**      Data comes from sw.T_Job_Parameters, not from the public schema tables
**
**  Arguments:
**    _job int          Job number
**    _step int         Step number
**    _paramName        Parameter name to find, for example: 'Instrument', 'Dataset%', or 'StepTool'
**    _section          Optional section name to filter on, for example: 'JobParameters'
**
**  Auth:   mem
**  Date:   03/09/2021 mem - Initial release
**          06/08/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**
*****************************************************/
DECLARE
BEGIN

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _section   := Trim(Coalesce(_section, ''));
    _paramName := Trim(Coalesce(_paramName, ''));

    If _paramName= '' Then
        RAISE WARNING '_paramName cannot be empty';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Temporary table to hold job parameters
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_JobParamsTable (
        Section citext,
        Name citext,
        Value citext
    );

    ---------------------------------------------------
    -- Query get_job_step_params_work to populate the temporary table
    ---------------------------------------------------

    INSERT INTO Tmp_JobParamsTable (Section, Name, Value)
    SELECT Src.Section, Src.Name, Src.Value
    FROM sw.get_job_step_params_work(_job, _step) Src;

    If Not FOUND Then
        DROP TABLE Tmp_JobParamsTable;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Possibly filter the parameters
    ---------------------------------------------------

    If _section <> '' Then
        DELETE FROM Tmp_JobParamsTable Target
        WHERE NOT Target.Section ILIKE _section;
    End If;

    If _paramName <> '' Then
        DELETE FROM Tmp_JobParamsTable Target
        WHERE NOT Target.Name ILIKE _paramName;
    End If;

    ---------------------------------------------------
    -- Return the parameter value
    ---------------------------------------------------

    RETURN QUERY
    SELECT Src.Section, Src.Name, Src.Value
    FROM Tmp_JobParamsTable Src
    ORDER BY Src.Section
    LIMIT 1;

    DROP TABLE Tmp_JobParamsTable;

END
$$;


ALTER FUNCTION sw.get_job_step_param_value(_job integer, _step integer, _paramname text, _section text) OWNER TO d3l243;

--
-- Name: FUNCTION get_job_step_param_value(_job integer, _step integer, _paramname text, _section text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON FUNCTION sw.get_job_step_param_value(_job integer, _step integer, _paramname text, _section text) IS 'GetJobStepParamValue';

