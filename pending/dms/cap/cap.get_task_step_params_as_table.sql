--
CREATE OR REPLACE PROCEDURE cap.get_task_step_params_as_table
(
    _job int,
    _step int,
    _paramName text = '',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _debugMode boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Get capture task job step parameters for given job step
**
**      Note: Data comes from table cap.t_task_parameters
**
**  Arguments:
**    _paramName   Optional parameter name to filter on (supports wildcards)
**
**  Auth:   mem
**  Date:   05/05/2010 mem - Initial release
**          02/12/2020 mem - Add argument _paramName, which can be used to filter the results
**
*****************************************************/
DECLARE

BEGIN
    _message := '';
    _returnCode := '';

    _paramName := Trim(Coalesce(_paramName, ''));

    ---------------------------------------------------
    -- Temporary table to hold capture task job parameters
    ---------------------------------------------------
    --
    CREATE TEMP TABLE ParamTab (
        Section text,
        Name text,
        Value text
    )

    ---------------------------------------------------
    -- Call get_task_step_params to populate the temporary table
    ---------------------------------------------------

    CALL cap.get_task_step_params (_job, _step, _message => _message, _returnCode => _returnCode, _debugMode => _debugMode);

    If _returnCode <> '' Then
        RETURN;
    End If;

    ---------------------------------------------------
    -- Return the contents of Tmp_JobParamsTable
    ---------------------------------------------------

    If _paramName = '' Or _paramName = '%' Then
        SELECT *
        FROM Tmp_ParamTab
        ORDER BY [Section], [Name], [Value]
    Else
        SELECT *
        FROM Tmp_ParamTab
        Where Name Like _paramName
        ORDER BY [Section], [Name], [Value]

        RAISE INFO '%', 'Only showing parameters match ' || _paramName;
    End If;

    DROP TABLE ParamTab;
END
$$;

COMMENT ON PROCEDURE cap.get_task_step_params_as_table IS 'GetJobStepParamsAsTable';
