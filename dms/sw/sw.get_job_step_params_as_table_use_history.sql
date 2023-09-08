--
-- Name: get_job_step_params_as_table_use_history(integer, integer, text, text); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.get_job_step_params_as_table_use_history(_job integer, _step integer, _section text DEFAULT ''::text, _paramname text DEFAULT ''::text) RETURNS TABLE(section public.citext, name public.citext, value public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Get job step parameters for given job step
**
**      Data comes from sw.T_Job_Parameters_History, not from the public schema tables
**
**  Arguments:
**    _job int          Job number
**    _step int         Step number
**    _section          Optional section name to filter on, for example: 'JobParameters'
**    _paramName        Optional parameter name to filter on, for example: 'Instrument', 'Dataset%', or 'StepTool'
**
**  Auth:   mem
**  Date:   07/31/2013 mem - Initial release
**          01/05/2018 mem - Add parameters _section, _paramName, and _firstParameterValue
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

    ---------------------------------------------------
    -- Temporary table to hold job parameters
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_JobParamsTable (
        Section citext,
        Name citext,
        Value citext
    );

    ---------------------------------------------------
    -- Query get_job_step_params_from_history_work to populate the temporary table
    ---------------------------------------------------

    INSERT INTO Tmp_JobParamsTable (Section, Name, Value)
    SELECT Src.Section, Src.Name, Src.Value
    FROM sw.get_job_step_params_from_history_work (_job, _step) Src;

    If Not FOUND Then
        DROP TABLE Tmp_JobParamsTable;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Possibly filter the parameters
    ---------------------------------------------------

    If _section <> '' Then
        DELETE FROM Tmp_JobParamsTable Target
        WHERE Not Target.Section ILike _section;
    End If;

    If _paramName <> '' Then
        DELETE FROM Tmp_JobParamsTable Target
        WHERE Not Target.Name ILike _paramName;
    End If;

    ---------------------------------------------------
    -- Return the contents of Tmp_JobParamsTable
    ---------------------------------------------------

    RETURN QUERY
    SELECT Src.Section, Src.Name, Src.Value
    FROM Tmp_JobParamsTable Src;

    DROP TABLE Tmp_JobParamsTable;

END
$$;


ALTER FUNCTION sw.get_job_step_params_as_table_use_history(_job integer, _step integer, _section text, _paramname text) OWNER TO d3l243;

--
-- Name: FUNCTION get_job_step_params_as_table_use_history(_job integer, _step integer, _section text, _paramname text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON FUNCTION sw.get_job_step_params_as_table_use_history(_job integer, _step integer, _section text, _paramname text) IS 'GetJobStepParamsAsTableUseHistory';

