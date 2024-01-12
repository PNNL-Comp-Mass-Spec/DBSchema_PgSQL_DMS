--
-- Name: add_update_step_tools(text, text, text, integer, integer, integer, integer, text, text, text, text, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.add_update_step_tools(IN _name text, IN _type text, IN _description text, IN _sharedresultversion integer, IN _filterversion integer, IN _cpuload integer, IN _memoryusagemb integer, IN _parametertemplate text, IN _paramfilestoragepath text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit existing tools in sw.t_step_tools
**
**  Arguments:
**    _name                     Step tool name
**    _type                     Step tool type
**    _description              Step tool description
**    _sharedResultVersion      Shared result version (0 if the step tool does not create shared results)
**    _filterVersion            Filter version
**    _cpuLoad                  Number of CPU cores that the step tool can use simultaneously
**    _memoryUsageMB            Maximum expected memory usage, in MB
**    _parameterTemplate        Parameter template XML (as text)
**    _paramFileStoragePath     Parameter file storage path (network share)
**    _mode                     Mode: 'add' or 'update'
**    _message                  Status message
**    _returnCode               Return code
**    _callingUser              Username of the calling user
**
**  Excerpt from an example parameter template (for Mz_Refinery):
**
**      <section name="MSXMLGenerator">
**        <item key="MSXMLGenerator" value="MSConvert.exe" />
**        <item key="MSXMLOutputType" value="mzML" />
**        <item key="CentroidMSXML" value="True" />
**        <item key="CentroidPeakCountToRetain" value="-1" />
**        <item key="RecalculatePrecursors" value="False" />
**      </section>
**      <section name="MzRefinery">
**        <item key="MzRefParamFile" value="MzMLRef_NoMods.txt" />
**      </section>
**
**  Auth:   grk
**  Date:   09/24/2008
**          12/17/2009 mem - Added parameter _paramFileStoragePath
**          10/17/2011 mem - Added parameter _memoryUsageMB
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          07/28/2023 mem - Ported to PostgreSQL
**          01/03/2024 mem - Update warning messages
**          01/11/2024 mem - Check for an empty step tool name
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _existingRowCount int := 0;
    _parameterTemplateXML xml;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    If Trim(Coalesce(_parameterTemplate, '')) <> '' Then
        _parameterTemplateXML := public.try_cast(_parameterTemplate, null::xml);

        If _parameterTemplateXML Is Null Then
            _message := format('Parameter template is not valid XML: ', _parameterTemplate);
            RAISE WARNING '%', _message;

            _returnCode := 'U5201';
            RETURN;
        End If;

    Else
        _parameterTemplateXML := null;
    End If;

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    _name := Trim(Coalesce(_name, ''));

    If _name = '' Then
        _message := 'Step tool name must be specified';
        _returnCode := 'U5202';
        RETURN;
    End If;

    SELECT COUNT(step_tool_id)
    INTO _existingRowCount
    FROM sw.t_step_tools
    WHERE step_tool = _name::citext;

    _mode := Trim(Lower(Coalesce(_mode, '')));

    -- Cannot update a non-existent entry

    If _mode = 'update' And _existingRowCount = 0 Then
        _message := format('Cannot update: step tool "%s" does not exist', _name);
        RAISE WARNING '%', _message;

        _returnCode := 'U5203';
        RETURN;
    End If;

    -- Cannot add an existing entry

    If _mode = 'add' And _existingRowCount > 0 Then
        _message := format('Cannot add: step tool "%s" already exists', _name);
        RAISE WARNING '%', _message;

        _returnCode := 'U5204';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    If _mode = 'add' Then

        INSERT INTO sw.t_step_tools (
            step_tool,
            type,
            description,
            shared_result_version,
            filter_version,
            cpu_load,
            memory_usage_mb,
            parameter_template,
            param_file_storage_path
        ) VALUES (
            _name,
            _type,
            _description,
            _sharedResultVersion,
            _filterVersion,
            _cpuLoad,
            _memoryUsageMB,
            _parameterTemplateXML,
            _paramFileStoragePath
        );

    End If;

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------

    If _mode = 'update' Then

        UPDATE sw.t_step_tools
        SET type = _type,
            description = _description,
            shared_result_version = _sharedResultVersion,
            filter_version = _filterVersion,
            cpu_load = _cpuLoad,
            memory_usage_mb = _memoryUsageMB,
            parameter_template = _parameterTemplateXML,
            param_file_storage_path = _paramFileStoragePath
        WHERE step_tool = _name;

    End If;

END
$$;


ALTER PROCEDURE sw.add_update_step_tools(IN _name text, IN _type text, IN _description text, IN _sharedresultversion integer, IN _filterversion integer, IN _cpuload integer, IN _memoryusagemb integer, IN _parametertemplate text, IN _paramfilestoragepath text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_step_tools(IN _name text, IN _type text, IN _description text, IN _sharedresultversion integer, IN _filterversion integer, IN _cpuload integer, IN _memoryusagemb integer, IN _parametertemplate text, IN _paramfilestoragepath text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.add_update_step_tools(IN _name text, IN _type text, IN _description text, IN _sharedresultversion integer, IN _filterversion integer, IN _cpuload integer, IN _memoryusagemb integer, IN _parametertemplate text, IN _paramfilestoragepath text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateStepTools';

