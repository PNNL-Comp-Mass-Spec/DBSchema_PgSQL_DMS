--
CREATE OR REPLACE PROCEDURE sw.set_folder_create_task_complete
(
    _taskID int,
    _completionCode int,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Update state, finish time, and completion code in t_data_folder_create_queue
**
**  Arguments:
**    _completionCode   0 means success; non-zero means failure
**    _message          Output message
**
**  Auth:   mem
**  Date:   03/17/2011 mem - Initial version
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
    _processor text;
    _state int;
    _stepState int;
BEGIN
    _message := '';
    _returnCode:= '';

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
    -- Get current state of this task
    ---------------------------------------------------
    --
    _processor := '';
    --
    _state := 0;
    --
    SELECT
        _state = state,
        _processor = processor
    FROM sw.t_data_folder_create_queue
    WHERE (entry_id = _taskID)
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;
    --
    If _state <> 2 Then
        _myError := 67;
        _message := 'Task ' || _taskID::text;

        If _myRowCount = 0 Then
            _message := _message || ' was not found in sw.t_data_folder_create_queue';
        Else
            _message := _message || ' is not in correct state to be completed; expecting State=2 but actually ' || _state::text;
        End If;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Determine completion state
    ---------------------------------------------------
    --

    If _completionCode = 0 Then
        _stepState := 3;
    Else
        _stepState := 4;
    End If;

    ---------------------------------------------------
    -- Update job step
    ---------------------------------------------------
    --
    UPDATE sw.t_data_folder_create_queue
    SET    state = _stepState,
           finish = CURRENT_TIMESTAMP,
           completion_code = _completionCode
    WHERE  (entry_id = _taskID);

END
$$;

COMMENT ON PROCEDURE sw.set_folder_create_task_complete IS 'SetFolderCreateTaskComplete';

