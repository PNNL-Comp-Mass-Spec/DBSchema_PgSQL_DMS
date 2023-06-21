--
-- Name: get_task_step_params_as_table(integer, integer, text); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.get_task_step_params_as_table(_job integer, _step integer, _paramname text DEFAULT ''::text) RETURNS TABLE(section public.citext, name public.citext, value public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Get capture task job step parameters for given job step
**
**      Data comes from table cap.t_task_parameters
**
**  Arguments:
**    _job          Capture task job number
**    _step         Job step
**    _paramName    Optional parameter name to filter on (supports wildcards)
**
**  Auth:   mem
**  Date:   05/05/2010 mem - Initial release
**          02/12/2020 mem - Add argument _paramName, which can be used to filter the results
**          06/06/2023 mem - Ported to PostgreSQL
**          06/20/2023 mem - Use citext for columns in the output table
**
*****************************************************/
DECLARE

BEGIN
    _paramName := Trim(Coalesce(_paramName, ''));

    ---------------------------------------------------
    -- Temporary table to hold capture task job parameters
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_JobParamsTable (
        Section citext,
        Name citext,
        Value citext
    );

    ---------------------------------------------------
    -- Query get_task_step_params to populate the temporary table
    ---------------------------------------------------

    INSERT INTO Tmp_JobParamsTable (Section, Name, Value)
    SELECT Src.Section, Src.Name, Src.Value
    FROM cap.get_task_step_params (_job, _step) Src;

    If Not FOUND Then
        RETURN;
    End If;

    ---------------------------------------------------
    -- Return the contents of Tmp_JobParamsTable
    ---------------------------------------------------

    If _paramName = '' Or _paramName = '%' Then
        RETURN QUERY
        SELECT Src.Section, Src.Name, Src.Value
        FROM Tmp_JobParamsTable Src
        ORDER BY Src.Section, Src.Name, Src.Value;
    Else
        RETURN QUERY
        SELECT Src.Section, Src.Name, Src.Value
        FROM Tmp_JobParamsTable Src
        WHERE Src.Name ILIKE _paramName
        ORDER BY Src.Section, Src.Name, Src.Value;

        -- RAISE INFO 'Only showing parameters that match %', _paramName;
    End If;

    DROP TABLE Tmp_JobParamsTable;
END
$$;


ALTER FUNCTION cap.get_task_step_params_as_table(_job integer, _step integer, _paramname text) OWNER TO d3l243;

--
-- Name: FUNCTION get_task_step_params_as_table(_job integer, _step integer, _paramname text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON FUNCTION cap.get_task_step_params_as_table(_job integer, _step integer, _paramname text) IS 'GetTaskStepParamsAsTable or GetJobStepParamsAsTable';

