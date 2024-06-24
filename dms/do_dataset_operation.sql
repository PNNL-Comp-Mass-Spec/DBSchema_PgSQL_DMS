--
-- Name: do_dataset_operation(text, text, text, text, text, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.do_dataset_operation(IN _datasetnameorid text, IN _mode text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text, IN _showdebug boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Perform dataset operation defined by _mode
**
**  Arguments:
**    _datasetNameOrID  Dataset name or dataset ID
**    _mode             Mode: 'delete', 'reset', 'createjobs'; legacy version supported 'burn' and 'delete_all'
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**    _showDebug        When true, show debug messages
**
**  Auth:   grk
**  Date:   04/08/2002
**          08/07/2003 grk - Allowed reset from 'Not Ready' state
**          05/05/2005 grk - Removed default value from mode
**          03/24/2006 grk - Added 'restore' mode
**          09/15/2006 grk - Repair 'restore' mode
**          03/27/2008 mem - Added optional parameter _callingUser; if provided, will call alter_event_log_entry_user (Ticket #644)
**          07/15/2008 jds - Added 'delete_all' mode (Ticket #644) - deletes a dataset without any restrictions
**          08/19/2010 grk - Use try-catch for error handling
**          05/25/2011 mem - Fixed bug that reported 'mode was unrecognized' for valid modes
**                         - Removed 'restore' mode
**          01/12/2012 mem - Now preventing deletion if _mode is 'delete' and the dataset exists in cap.V_Capture_Tasks_Active_Or_Complete
**          11/14/2013 mem - Now preventing reset if the first step of dataset capture succeeded
**          02/23/2016 mem - Add set XACT_ABORT on
**          01/10/2017 mem - Add _mode 'createjobs' which adds the dataset to T_Predefined_Analysis_Scheduling_Queue so that default jobs will be created
**                           (duplicate jobs are not created)
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/04/2017 mem - Use _logErrors to toggle logging errors caught by the try/catch block
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/03/2017 mem - Allow resetting a dataset if DatasetIntegrity failed
**          08/08/2017 mem - Use function Remove_Capture_Errors_From_String to remove common dataset capture errors when resetting a dataset
**          09/07/2018 mem - Remove mode 'delete_all'; if you need to delete a dataset, manually call procedure Delete_Dataset
**                         - Rename _datasetName to _datasetNameOrID
**          09/27/2018 mem - Use named parameter names when calling Delete_Dataset
**          11/16/2018 mem - Pass _infoOnly to Delete_Dataset
**          02/04/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _msg text;
    _datasetID int := 0;
    _currentState int;
    _newState int;
    _currentComment text;
    _result int;
    _validMode boolean := false;
    _logErrors boolean := false;
    _candidateDatasetID int;
    _datasetName text := '';
    _datasetStateName text;
    _enteredMax timestamp;
    _elapsedHours numeric;
    _allowReset boolean := false;
    _logMessage text;
    _targetType int;
    _alterEnteredByMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
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

    BEGIN
        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _datasetNameOrID    := Trim(Coalesce(_datasetNameOrID, ''));
        _mode               := Trim(Lower(Coalesce(_mode, '')));
        _callingUser        := Trim(Coalesce(_callingUser, ''));
        _showDebug          := Coalesce(_showDebug, false);
        _candidateDatasetID := public.try_cast(_datasetNameOrID, null::int);

        ---------------------------------------------------
        -- Get datasetID and current state
        ---------------------------------------------------

        If Coalesce(_candidateDatasetID, 0) > 0 Then
            If _showDebug Then
                RAISE INFO 'Resolve ID % to dataset name and ID', _candidateDatasetID;
            End If;

            SELECT dataset_state_id,
                   comment,
                   dataset_id,
                   dataset
            INTO _currentState, _currentComment, _datasetID, _datasetName
            FROM t_dataset
            WHERE dataset_id = _candidateDatasetID;
        Else
            If _showDebug Then
                RAISE INFO 'Resolve % to dataset name and ID', _datasetName;
            End If;

            SELECT dataset_state_id,
                   comment,
                   dataset_id,
                   dataset
            INTO _currentState, _currentComment, _datasetID, _datasetName
            FROM t_dataset
            WHERE dataset = _datasetNameOrID::citext;
        End If;

        If Not FOUND Then
            _message := format('"%s" does not match a dataset name or dataset ID', _datasetNameOrID);
            RAISE EXCEPTION '%', _message;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Schedule the dataset for predefined job processing
        ---------------------------------------------------

        If _mode = Lower('Createjobs') Then
            If _showDebug Then
                RAISE INFO 'Add dataset ID % to t_predefined_analysis_scheduling_queue (if appropriate)', _datasetID;
            End If;

            If _callingUser = '' Then
                _callingUser := SESSION_USER;
            End If;

            If Exists (SELECT dataset_id FROM t_predefined_analysis_scheduling_queue WHERE dataset_id = _datasetID AND state = 'New') Then

                SELECT MAX(entered)
                INTO _enteredMax
                FROM t_predefined_analysis_scheduling_queue
                WHERE dataset_id = _datasetID AND state = 'New';

                _elapsedHours := Extract(epoch from CURRENT_TIMESTAMP - Coalesce(_enteredMax, CURRENT_TIMESTAMP)) / 3600;

                _logErrors := false;

                If _elapsedHours >= 0.5 Then
                    RAISE EXCEPTION 'Default job creation for dataset ID % has been waiting for % hours; please contact a DMS administrator to diagnose the delay',
                                    _datasetID, Round(_elapsedHours, 1);
                Else
                    RAISE EXCEPTION 'Dataset ID % is already scheduled to have default jobs created; please wait at least 5 minutes', _datasetID;
                End If;

            End If;

            INSERT INTO t_predefined_analysis_scheduling_queue (dataset_id, calling_user)
            VALUES (_datasetID, _callingUser);

            _validMode := true;
        End If;

        ---------------------------------------------------
        -- Delete dataset, but only if it is in 'new' state
        ---------------------------------------------------

        If _mode = 'delete' Then

            If _currentState <> 1 Then
                _logErrors := false;
                RAISE EXCEPTION 'Dataset "%" must be in "new" state to be deleted by user', _datasetName;
            End If;

            ---------------------------------------------------
            -- Verify that the dataset does not have an active or completed capture job
            ---------------------------------------------------

            If Exists (SELECT Dataset_ID FROM cap.V_Capture_Tasks_Active_Or_Complete WHERE Dataset_ID = _datasetID AND State <= 2) Then
                RAISE EXCEPTION 'Dataset "%" is being processed by the capture task pipeline; unable to delete', _datasetName;
            End If;

            If Exists (SELECT Dataset_ID FROM cap.V_Capture_Tasks_Active_Or_Complete WHERE Dataset_ID = _datasetID AND State > 2) Then
                RAISE EXCEPTION 'Dataset "%" has been processed by the capture task pipeline; unable to delete', _datasetName;
            End If;

            ---------------------------------------------------
            -- Delete the dataset
            ---------------------------------------------------

            If _showDebug Then
                RAISE INFO 'Call delete_dataset for dataset %', _datasetName;
            End If;

            CALL public.delete_dataset (
                            _datasetName => _datasetName,
                            _infoOnly    => false,
                            _message     => _message,       -- Output
                            _returnCode  => _returnCode,    -- Output
                            _callingUser => _callingUser,
                            _showDebug   => _showDebug);

            If _returnCode <> '' Then
                If _showDebug Then
                    RAISE INFO 'Return code is %; show message %', _returnCode, _message;
                End If;

                RAISE EXCEPTION 'Could not delete dataset "%"%',
                                    _datasetName,
                                    CASE WHEN Coalesce(_message, '') = ''
                                         THEN ''
                                         ELSE format(': %s', _message)
                                    END;
            End If;

            _validMode := true;
        End If;

        ---------------------------------------------------
        -- Reset state of failed dataset to 'new'
        -- This is used by the 'Retry Capture' button on the dataset detail report page
        ---------------------------------------------------

        If _mode = 'reset' Then

            If Not _currentState In (5, 9) Then     -- 'Failed' or 'Not ready'
                _logErrors := false;

                SELECT dataset_state
                INTO _datasetStateName
                FROM t_dataset_state_name
                WHERE dataset_state_id = _currentState;

                RAISE EXCEPTION 'Dataset "%" cannot be reset since capture state ("%") is not "Failed" or "Not Ready"', _datasetName, _datasetStateName;
            End If;

            -- Do not allow a reset if the dataset succeeded the first step of capture
            -- However, do allow a reset if the DatasetIntegrity step failed and we haven't already retried capture of this dataset once

            If Exists (SELECT Job FROM cap.V_Task_Steps WHERE Dataset_ID = _datasetID AND Tool = 'DatasetCapture' AND State IN (1, 2, 4, 5)) Then

                If Exists (SELECT Job FROM cap.V_Task_Steps WHERE Dataset_ID = _datasetID AND Tool = 'DatasetIntegrity' AND State = 6) AND
                   Exists (SELECT Job FROM cap.V_Task_Steps WHERE Dataset_ID = _datasetID AND Tool = 'DatasetCapture'   AND State = 5)
                Then
                    _msg := format('Retrying capture of dataset %s at user request (dataset was captured, but DatasetIntegrity failed)', _datasetName);

                    If Exists (SELECT entry_id FROM t_log_entries WHERE message LIKE _msg || '%') Then
                        _msg := format('Dataset "%s" cannot be reset because it has already been reset once', _datasetName);

                        If _callingUser = '' Then
                            _logMessage := format('%s; user %s', _msg, SESSION_USER);
                        Else
                            _logMessage := format('%s; user %s', _msg, _callingUser);
                        End If;

                        CALL post_log_entry ('Error', _logMessage, 'Do_Dataset_Operation');

                        _msg := format('%s; please contact a system administrator for further assistance', _msg);
                    Else
                        _allowReset := true;

                        If _callingUser = '' Then
                            _msg := format('%s; user %s', _msg, SESSION_USER);
                        Else
                            _msg := format('%s; user %s', _msg, _callingUser);
                        End If;

                        CALL post_log_entry ('Warning', _msg, 'Do_Dataset_Operation');
                    End If;

                Else
                    _msg := format('Dataset "%s" cannot be reset because it has already been successfully captured; please contact a system administrator for further assistance', _datasetName);
                End If;

                If Not _allowReset Then
                    _logErrors := false;
                    RAISE EXCEPTION '%', _msg;
                End If;
            End If;

            -- Update state of dataset to new (1)

            _newState := 1;

            If _showDebug Then
                RAISE INFO 'Update state of dataset % to %', _datasetID, _newState;
            End If;

            UPDATE t_dataset
            SET dataset_state_id = _newState,
                comment          = public.remove_capture_errors_from_string(comment)
            WHERE dataset_id = _datasetID;

            If Not FOUND Then
                RAISE EXCEPTION 'Reset was unsuccessful for dataset "%" (t_dataset was not updated)', _datasetName;
            End If;

            If Trim(Coalesce(_callingUser, '')) <> '' Then
                _targetType := 4;
                CALL public.alter_event_log_entry_user ('public', _targetType, _datasetID, _newState, _callingUser, _message => _alterEnteredByMessage);
            End If;

            _validMode := true;
        End If;

        If _validMode Then
            RETURN;
        End If;

        ---------------------------------------------------
        -- Mode was unrecognized
        ---------------------------------------------------

        RAISE EXCEPTION 'Mode "%" was unrecognized', _mode;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _logMessage := format('%s; Dataset %s', _exceptionMessage, _datasetNameOrID);

            _message := local_error_handler (
                            _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

END
$$;


ALTER PROCEDURE public.do_dataset_operation(IN _datasetnameorid text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _showdebug boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE do_dataset_operation(IN _datasetnameorid text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _showdebug boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.do_dataset_operation(IN _datasetnameorid text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _showdebug boolean) IS 'DoDatasetOperation';

