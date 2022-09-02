--
-- Name: add_update_task_parameter(integer, text, text, text, boolean, text, boolean); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.add_update_task_parameter(IN _job integer, IN _section text, IN _paramname text, IN _value text, IN _deleteparam boolean DEFAULT false, INOUT _message text DEFAULT ''::text, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds or updates an entry in the XML parameters for a given capture task job
**      Alternatively, use _deleteParam=true to delete the given parameter
**
**  Arguments:
**    _section          Section name, e.g.   JobParameters
**    _paramName        Parameter name, e.g. SourceJob
**    _value            Value for parameter _paramName in section _section
**    _deleteParam      When false, adds/updates the given parameter; when true, deletes the parameter
**
**  Example Usage:
**
**      Call cap.add_update_task_parameter (5280268, 'DatasetQC', 'CreateDatasetInfoFile', 'False', _infoOnly => true);
**      Call cap.add_update_task_parameter (5280268, 'DatasetQC', 'CreateDatasetInfoFile', 'False', _infoOnly => false);
**      Call cap.add_update_task_parameter (5280268, 'DatasetQC', 'CreateDatasetInfoFile', 'True',  _infoOnly => false, _deleteParam => true);
**
**  Auth:   mem
**  Date:   03/22/2011 mem - Initial Version
**          04/04/2011 mem - Expanded [Value] to varchar(4000) in _task_Parameters
**          01/19/2012 mem - Now using AddUpdateJobParameterXML
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/23/2022 mem - Ported to PostgreSQL
**          08/24/2022 mem - Switch from get_current_function_name() to get_current_function_info()
**          08/26/2022 mem - verify_sp_authorized now has boolean parameters
**          08/27/2022 mem - Change arguments _infoOnly and _deleteParam from int to boolean
**          09/01/2022 mem - Send '<auto>' to get_current_function_info()
**
*****************************************************/
DECLARE
    _showDebug bool;
    _schemaName text;
    _nameWithSchema text;
    _authorized bool;
    _existingParamsFound bool = false;
    _xmlParameters xml;
    _results record;
BEGIN

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    _showDebug := Coalesce(_infoOnly, false);

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    -----------------------------------------------
    -- Validate the inputs
    -----------------------------------------------

    _job := Coalesce(_job, 0);
    _section := Coalesce(_section, '');
    _paramName := Coalesce(_paramName, '');
    _value := Coalesce(_value, '');
    _deleteParam := Coalesce(_deleteParam, false);
    _infoOnly := Coalesce(_infoOnly, false);

    _message = '';

    ---------------------------------------------------
    -- Lookup the current parameters stored in t_task_parameters for this capture task job
    ---------------------------------------------------
    --
    SELECT Parameters
    INTO _xmlParameters
    FROM cap.t_task_parameters
    WHERE Job = _job;

    If FOUND Then
        _existingParamsFound := true;
    Else
        If Not Exists (Select * FROM cap.t_tasks WHERE job = _job) Then
            _message := format('Error: capture task job %s not found in t_task_parameters or t_tasks', _job);

            RAISE WARNING '%', _message;
            Return;
        End If;

        _message := format('Warning: capture task job %s not found in t_task_parameters, but was found in t_tasks; will add a new row to t_task_parameters', _job);

        If _infoOnly Then
            RAISE INFO '%', _message;
        End If;

        _xmlParameters := ''::xml;
    End If;

    ---------------------------------------------------
    -- Use function_update_task_parameter_xml to update the XML
    ---------------------------------------------------
    --
    SELECT updated_xml, success, message
    INTO _results
    FROM cap.add_update_task_parameter_xml(_xmlParameters, _section, _paramName, _value, _deleteParam, _showDebug => _infoOnly);

    _message := _results.message;

    If Not _results.success Then
        RAISE WARNING 'Function add_update_task_parameter_xml was unable to update the XML for capture task job %: %',
            _job,
            Case When Coalesce(_message, '') = '' Then 'Unknown reason' Else _message End;

    ElsIf Not _infoOnly Then
        ---------------------------------------------------
        -- Update T_task_Parameters
        -- Note: Ordering by Section name but not by parameter name
        ---------------------------------------------------
        --
        If _existingParamsFound Then
            UPDATE cap.t_task_parameters
            SET parameters = _results.updated_xml
            WHERE Job = _job;
        Else
            INSERT INTO cap.t_task_parameters( job, parameters )
            VALUES (_job, _results.updated_xml);
        End If;

    End If;

END
$$;


ALTER PROCEDURE cap.add_update_task_parameter(IN _job integer, IN _section text, IN _paramname text, IN _value text, IN _deleteparam boolean, INOUT _message text, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_task_parameter(IN _job integer, IN _section text, IN _paramname text, IN _value text, IN _deleteparam boolean, INOUT _message text, IN _infoonly boolean); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.add_update_task_parameter(IN _job integer, IN _section text, IN _paramname text, IN _value text, IN _deleteparam boolean, INOUT _message text, IN _infoonly boolean) IS 'AddUpdateJobParameter';

