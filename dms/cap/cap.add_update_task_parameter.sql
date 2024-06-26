--
-- Name: add_update_task_parameter(integer, text, text, text, boolean, text, text, boolean, boolean); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.add_update_task_parameter(IN _job integer, IN _section text, IN _paramname text, IN _value text, IN _deleteparam boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infoonly boolean DEFAULT false, IN _showdebug boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add or update an entry in the XML parameters for a given capture task job
**      Alternatively, use _deleteParam => true to delete the given parameter
**
**  Arguments:
**    _job              Capture task job number
**    _section          Section name, e.g.   JobParameters
**    _paramName        Parameter name, e.g. SourceJob
**    _value            Value for parameter _paramName in section _section
**    _deleteParam      When false, adds/updates the given parameter; when true, deletes the parameter
**    _message          Status message
**    _returnCode       Return code
**    _infoOnly         When true, preview changes
**    _showDebug        When true, set _showDebug to true when calling get_current_function_info()
**
**  Example usage:
**      CALL cap.add_update_task_parameter (6016849, 'DatasetQC', 'CreateDatasetInfoFile', 'False', _infoOnly => true);
**      CALL cap.add_update_task_parameter (6016849, 'DatasetQC', 'CreateDatasetInfoFile', 'False', _infoOnly => false);
**      CALL cap.add_update_task_parameter (6016849, 'DatasetQC', 'CreateDatasetInfoFile', 'True',  _infoOnly => false, _deleteParam => true);
**
**  Auth:   mem
**  Date:   03/22/2011 mem - Initial Version
**          04/04/2011 mem - Expanded [Value] to varchar(4000) in Tmp_Task_Parameters
**          01/19/2012 mem - Now using Add_Update_Job_Parameter_XML
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/23/2022 mem - Ported to PostgreSQL
**          08/24/2022 mem - Switch from get_current_function_name() to get_current_function_info()
**          08/26/2022 mem - Verify_sp_authorized now has boolean parameters
**          08/27/2022 mem - Change arguments _infoOnly and _deleteParam from int to boolean
**          09/01/2022 mem - Send '<auto>' to get_current_function_info()
**          04/27/2023 mem - Use boolean for data type name
**          05/04/2023 mem - Add _returnCode procedure argument
**          05/22/2023 mem - Capitalize reserved word
**          05/31/2023 mem - Use procedure name without schema when calling verify_sp_authorized()
**          07/19/2023 mem - Add missing variable declaration
**          09/07/2023 mem - Align assignment statements
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          12/08/2023 mem - Select a single column when using If Not Exists()
**                         - Add _showDebug procedure argument
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _existingParamsFound boolean = false;
    _xmlParameters xml;
    _results record;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    _showDebug := Coalesce(_showDebug, false);

    If _infoOnly Or _showDebug Then
        RAISE INFO '';
    End If;

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug);

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        BEGIN
            -- Commit changes to persist the message logged to public.t_log_entries
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
            -- The commit failed, likely because this procedure was called from the DMS website, which wraps procedure calls in a transaction
            -- Ignore the commit error (t_log_entries will not be updated, but _message will be updated)
        END;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _job         := Coalesce(_job, 0);
    _section     := Trim(Coalesce(_section, ''));
    _paramName   := Trim(Coalesce(_paramName, ''));
    _value       := Coalesce(_value, '');
    _deleteParam := Coalesce(_deleteParam, false);
    _infoOnly    := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Lookup the current parameters stored in cap.t_task_parameters for this capture task job
    ---------------------------------------------------

    SELECT parameters
    INTO _xmlParameters
    FROM cap.t_task_parameters
    WHERE job = _job;

    If FOUND Then
        _existingParamsFound := true;
    Else
        If Not Exists (SELECT job FROM cap.t_tasks WHERE job = _job) Then
            _message := format('Error: capture task job %s not found in cap.t_task_parameters or cap.t_tasks', _job);

            RAISE WARNING '%', _message;
            RETURN;
        End If;

        _message := format('Warning: capture task job %s not found in cap.t_task_parameters, but was found in cap.t_tasks; will add a new row to t_task_parameters', _job);

        If _infoOnly Then
            RAISE INFO '%', _message;
        End If;

        _xmlParameters := ''::xml;
    End If;

    ---------------------------------------------------
    -- Use function add_update_task_parameter_xml to update the XML
    ---------------------------------------------------

    SELECT updated_xml, success, message
    INTO _results
    FROM cap.add_update_task_parameter_xml(
            _xmlParameters,
            _section,
            _paramName,
            _value,
            _deleteParam,
            _showDebug => _infoOnly);

    _message := _results.message;

    If Not _results.success Then
        RAISE WARNING 'Function add_update_task_parameter_xml was unable to update the XML for capture task job %: %',
            _job,
            CASE WHEN Coalesce(_message, '') = '' THEN 'Unknown reason' ELSE _message END;

    ElsIf Not _infoOnly Then
        ---------------------------------------------------
        -- Update cap.t_task_parameters
        -- Note: Ordering by Section name but not by parameter name
        ---------------------------------------------------

        If _existingParamsFound Then
            UPDATE cap.t_task_parameters
            SET parameters = _results.updated_xml
            WHERE job = _job;
        Else
            INSERT INTO cap.t_task_parameters (
                job,
                parameters
            ) VALUES (
                _job,
                _results.updated_xml
            );
        End If;

    End If;

END
$$;


ALTER PROCEDURE cap.add_update_task_parameter(IN _job integer, IN _section text, IN _paramname text, IN _value text, IN _deleteparam boolean, INOUT _message text, INOUT _returncode text, IN _infoonly boolean, IN _showdebug boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_task_parameter(IN _job integer, IN _section text, IN _paramname text, IN _value text, IN _deleteparam boolean, INOUT _message text, INOUT _returncode text, IN _infoonly boolean, IN _showdebug boolean); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.add_update_task_parameter(IN _job integer, IN _section text, IN _paramname text, IN _value text, IN _deleteparam boolean, INOUT _message text, INOUT _returncode text, IN _infoonly boolean, IN _showdebug boolean) IS 'AddUpdateTaskParameter';

