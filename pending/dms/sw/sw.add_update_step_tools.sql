--
CREATE OR REPLACE PROCEDURE sw.add_update_step_tools
(
    _name text,
    _type text,
    _description text,
    _sharedResultVersion int,
    _filterVersion int,
    _cPULoad int,
    _memoryUsageMB int,
    _parameterTemplate text,
    _paramFileStoragePath text,
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new or edits existing T_Step_Tools
**
**  Arguments:
**    _mode   'add' or 'update'
**
**  Auth:   grk
**  Date:   09/24/2008
**          12/17/2009 mem - Added parameter _paramFileStoragePath
**          10/17/2011 mem - Added parameter _memoryUsageMB
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean := false;

    _existingRowCount int := 0;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    SELECT COUNT(*)
    INTO _existingRowCount
    FROM  sw.t_step_tools
    WHERE step_tool = _name::citext;

    _mode := Trim(Lower(Coalesce(_mode, '')));

    -- Cannot update a non-existent entry
    --
    If _mode = 'update' And _existingRowCount = 0 Then
        _message := format('Could not find step tool "%s" in the database', _name);
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    -- Cannot add an existing entry
    --
    If _mode = 'add' And _existingRowCount > 0 Then
        _message := format('"%s" already exists in database', _name);
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
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
            _cPULoad,
            _memoryUsageMB,
            _parameterTemplate,
            _paramFileStoragePath
        )

    End If; -- add mode

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------
    --
    If _mode = 'update' Then

        UPDATE sw.t_step_tools
        SET type = _type,
            description = _description,
            shared_result_version = _sharedResultVersion,
            filter_version = _filterVersion,
            cpu_load = _cPULoad,
            memory_usage_mb = _memoryUsageMB,
            parameter_template = _parameterTemplate,
            param_file_storage_path = _paramFileStoragePath
        WHERE step_tool = _name;

    End If; -- update mode

END
$$;

COMMENT ON PROCEDURE sw.add_update_step_tools IS 'AddUpdateStepTools';
