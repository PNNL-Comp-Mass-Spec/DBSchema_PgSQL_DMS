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
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _authorized boolean;

    _processor text;
    _state int;
    _stepState int;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name
    INTO _currentSchema, _currentProcedure
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
    WHERE entry_id = _taskID;

    If Not FOUND Then
        _returnCode := 'U5267';
        _message := format('Task %s was not found in sw.t_data_folder_create_queue', _taskID);
        RETURN;
    End If;

    If _state <> 2 Then
        _returnCode := 'U5268';
        _message := format('Task %s is not in correct state to be completed; expecting State=2 but actually %s', _taskID, _state);
        RETURN;
    End If;

    ---------------------------------------------------
    -- Determine completion state
    ---------------------------------------------------

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
    WHERE entry_id = _taskID;

END
$$;

COMMENT ON PROCEDURE sw.set_folder_create_task_complete IS 'SetFolderCreateTaskComplete';

