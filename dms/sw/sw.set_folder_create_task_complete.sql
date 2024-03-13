--
-- Name: set_folder_create_task_complete(integer, integer, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.set_folder_create_task_complete(IN _taskid integer, IN _completioncode integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update state, finish time, and completion code in sw.t_data_folder_create_queue
**
**  Arguments:
**    _taskID           Folder create task ID
**    _completionCode   Completion code: 0 means success; non-zero means failure
**    _message          Status message
**    _returnCode       Return code
**
**
**  Auth:   mem
**  Date:   03/17/2011 mem - Initial version
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/09/2023 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
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

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Get current state of this task
    ---------------------------------------------------

    If Coalesce(_taskID, 0) = 0 Then
        _returnCode := 'U5266';
        _message := format('Parameter _taskID is null or 0', _taskID);
        RETURN;
    End If;

    _completionCode := Coalesce(_completionCode, 0);

    SELECT state, processor
    INTO _state, _processor
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

    UPDATE sw.t_data_folder_create_queue
    SET state = _stepState,
        finish = CURRENT_TIMESTAMP,
        completion_code = _completionCode
    WHERE entry_id = _taskID;

END
$$;


ALTER PROCEDURE sw.set_folder_create_task_complete(IN _taskid integer, IN _completioncode integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE set_folder_create_task_complete(IN _taskid integer, IN _completioncode integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.set_folder_create_task_complete(IN _taskid integer, IN _completioncode integer, INOUT _message text, INOUT _returncode text) IS 'SetFolderCreateTaskComplete';

