--
-- Name: set_dataset_create_task_complete(integer, integer, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.set_dataset_create_task_complete(IN _entryid integer, IN _completioncode integer, IN _completionmessage text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update t_dataset_create_queue after completing a dataset creation task
**
**  Arguments:
**    _entryID              Entry_ID to update
**    _completionCode       Completion code; 0 means success; non-zero means failure
**    _completionMessage    Error message to store in T_Dataset_Create_Queue when @completionCode is non-zero
**    _message              Status message
**    _returnCode           Return code
**
**  Return values:
**      0 for success, non-zero if an error
**
**  Auth:   mem
**          10/25/2023 mem - Initial version
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _stateID int;
    _datasetName text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _logMessage text;
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

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _entryID            := Coalesce(_entryID, 0);
        _completionCode     := Coalesce(_completionCode, 0);
        _completionMessage  := Coalesce(_completionMessage, '');

        ---------------------------------------------------
        -- Get current state of this dataset create task
        ---------------------------------------------------

        SELECT state_id, dataset
        INTO _stateID, _datasetName
        FROM t_dataset_create_queue
        WHERE Entry_ID = _entryID;

        If Not FOUND Then
            _message := format('Entry_ID %s was not found in T_Dataset_Create_Queue', _entryID);
            _returnCode := 'U5267';
            RETURN;
        End If;

        If _stateID <> 2 Then
            _message := format('Entry_ID %s is not in correct state to be completed; expecting State=2 in T_Dataset_Create_Queue but actually %s (dataset %s)', _entryID, _stateID, _datasetName);
            _returnCode := 'U5268';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Determine completion state
        ---------------------------------------------------

        If _completionCode = 0 Then
            _stateID = 3;
        Else
            _stateID = 4;
        End If;

        ---------------------------------------------------
        -- Update the state, finish time, and completion code
        ---------------------------------------------------

        UPDATE t_dataset_create_queue
        SET State_ID           = _stateID,
            Finish             = CURRENT_TIMESTAMP,
            Completion_Code    = _completionCode,
            Completion_Message = _completionMessage
        WHERE Entry_ID = _entryID;

        ---------------------------------------------------
        -- Make an entry in t_log_entries if the completion code is non-zero
        ---------------------------------------------------

        If _completionCode <> 0 Then
            _logMessage := format('Dataset creation task %s reported completion code %s: %s (dataset %s)',
                                    _entryID, _completionCode, _completionMessage, _datasetName);

            RAISE WARNING '%', _logMessage;
            CALL post_log_entry ('Error', _logMessage, 'Set_Dataset_Create_Task_Complete');
        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _logMessage := format('Error updating T_Dataset_Create_Queue for Entry_ID %s: %s', _entryID, _exceptionMessage);

        _message := local_error_handler (
                        _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;
END
$$;


ALTER PROCEDURE public.set_dataset_create_task_complete(IN _entryid integer, IN _completioncode integer, IN _completionmessage text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

