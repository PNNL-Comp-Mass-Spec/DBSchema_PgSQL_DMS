--
CREATE OR REPLACE PROCEDURE public.do_dataset_operation
(
    _datasetNameOrID text,
    _mode text,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Perform dataset operation defined by 'mode'
**
**  Arguments:
**    _datasetNameOrID   Dataset name or dataset ID
**    _mode              'delete', 'reset', 'createjobs'; legacy version supported 'burn' and 'delete_all'
**
**  Auth:   grk
**  Date:   04/08/2002
**          08/07/2003 grk - allowed reset from 'Not Ready' state
**          05/05/2005 grk - removed default value from mode
**          03/24/2006 grk - added 'restore' mode
**          09/15/2006 grk - repair 'restore' mode
**          03/27/2008 mem - Added optional parameter _callingUser; if provided, will call alter_event_log_entry_user (Ticket #644)
**          07/15/2008 jds - Added 'delete_all' mode (Ticket #644) - deletes a dataset without any restrictions
**          08/19/2010 grk - try-catch for error handling
**          05/25/2011 mem - Fixed bug that reported 'mode was unrecognized' for valid modes
**                         - Removed 'restore' mode
**          01/12/2012 mem - Now preventing deletion if _mode is 'delete' and the dataset exists in S_V_Capture_Jobs_ActiveOrComplete
**          11/14/2013 mem - Now preventing reset if the first step of dataset capture succeeded
**          02/23/2016 mem - Add set XACT_ABORT on
**          01/10/2017 mem - Add _mode 'createjobs' which adds the dataset to T_Predefined_Analysis_Scheduling_Queue so that default jobs will be created
**                           (duplicate jobs are not created)
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/04/2017 mem - Use _logErrors to toggle logging errors caught by the try/catch block
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/03/2017 mem - Allow resetting a dataset if DatasetIntegrity failed
**          08/08/2017 mem - Use function RemoveCaptureErrorsFromString to remove common dataset capture errors when resetting a dataset
**          09/07/2018 mem - Remove mode 'delete_all'; if you need to delete a dataset, manually call procedure DeleteDataset
**                         - Rename _datasetName to _datasetNameOrID
**          09/27/2018 mem - Use named parameter names when calling DeleteDataset
**          11/16/2018 mem - Pass _infoOnly to DeleteDataset
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
    _msg text;
    _logMsg text;
    _datasetID int := 0;
    _currentState int;
    _newState int;
    _currentComment text;
    _result int;
    _validMode boolean := false;
    _logErrors boolean := false;
    _candidateDatasetID int;
    _datasetName text := '';
    _enteredMax timestamp;
    _elapsedHours numeric;
    _allowReset int := 0;
    _logMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN

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
        -- Get datasetID and current state
        ---------------------------------------------------

        _candidateDatasetID := public.try_cast(_datasetNameOrID, null::int);

        If Coalesce(_candidateDatasetID, 0) > 0 Then
            SELECT dataset_state_id,
                   comment,
                   dataset_id,
                   dataset
            INTO _currentState, _currentComment, _datasetID, _datasetName
            FROM t_dataset
            WHERE dataset_id = _candidateDatasetID;
        Else
            SELECT dataset_state_id,
                   comment,
                   dataset_id,
                   dataset
            INTO _currentState, _currentComment, _datasetID, _datasetName
            FROM t_dataset
            WHERE dataset = _datasetNameOrID;
        End If;

        If Not FOUND Then
            _message := format('"%s" does not match a dataset name or dataset ID', _datasetNameOrID);
            RAISE EXCEPTION '%', _message;
        End If;

        _logErrors := true;

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Schedule the dataset for predefined job processing
        ---------------------------------------------------
        --
        If _mode = 'createjobs' Then
            If Coalesce(_callingUser, '') = '' Then
                _callingUser := session_user;
            End If;

            If Exists (SELECT * FROM t_predefined_analysis_scheduling_queue WHERE dataset_id = _datasetID AND state = 'New') Then

                SELECT MAX(entered)
                INTO _enteredMax
                FROM t_predefined_analysis_scheduling_queue
                WHERE dataset_id = _datasetID AND state = 'New';

                _elapsedHours := extract(epoch FROM CURRENT_TIMESTAMP - Coalesce(_enteredMax, CURRENT_TIMESTAMP)) / 3600.0

                _logErrors := false;

                If _elapsedHours >= 0.5 Then
                    RAISE EXCEPTION 'Default job creation for dataset ID % has been waiting for % hours; please contact a DMS administrator to diagnose the delay',
                                    _datasetID, Round(_elapsedHours, 1);
                Else
                    RAISE EXCEPTION 'Dataset ID % is already scheduled to have default jobs created; please wait at least 5 minutes', _datasetID;
                End If;

            End If;

            INSERT INTO t_predefined_analysis_scheduling_queue (dataset_id, calling_user)
            VALUES (_datasetID, _callingUser)
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            _validMode := true;

        End If; -- </createjobs>

        ---------------------------------------------------
        -- Delete dataset if it is in 'new' state only
        ---------------------------------------------------
        --
        If _mode = 'delete' Then

            ---------------------------------------------------
            -- Verify that dataset is still in 'new' state
            ---------------------------------------------------

            If _currentState <> 1 Then
                _logErrors := false;
                _msg := format('Dataset "%s" must be in "new" state to be deleted by user', _datasetName);
                RAISE EXCEPTION '%', _msg;
            End If;

            ---------------------------------------------------
            -- Verify that the dataset does not have an active or completed capture job
            ---------------------------------------------------

            If Exists (SELECT * FROM S_V_Capture_Jobs_ActiveOrComplete WHERE Dataset_ID = _datasetID And State <= 2) Then
                _msg := format('Dataset "%s" is being processed by the DMS_Capture database; unable to delete', _datasetName);
                RAISE EXCEPTION '%', _msg;
            End If;

            If Exists (SELECT * FROM S_V_Capture_Jobs_ActiveOrComplete WHERE Dataset_ID = _datasetID And State > 2) Then
                _msg := format('Dataset "%s" has been processed by the DMS_Capture database; unable to delete', _datasetName);
                RAISE EXCEPTION '%', _msg;
            End If;

            ---------------------------------------------------
            -- Delete the dataset
            ---------------------------------------------------

            Call DeleteDataset (_datasetName, _infoOnly => false, _message => _message, _returnCode => _returnCode, _callingUser => _callingUser);
            --
            If _returnCode <> '' Then
                RAISE EXCEPTION 'Could not delete dataset "%"', _datasetName;
            End If;

            _validMode := true;

        End If; -- </delete>

        ---------------------------------------------------
        -- Reset state of failed dataset to 'new'
        -- This is used by the 'Retry Capture' button on the dataset detail report page
        ---------------------------------------------------
        --
        If _mode = 'reset' Then

            -- If dataset not in failed state, can't reset it
            --
            If _currentState not in (5, 9) -- 'Failed' or 'Not ready' Then
                _logErrors := false;
                _msg := 'Dataset "' || _datasetName || '" cannot be reset if capture not in failed or in not ready state ' || cast(_currentState as text);
                RAISE EXCEPTION '%', _msg;
            End If;

            -- Do not allow a reset if the dataset succeeded the first step of capture
            If Exists (SELECT * FROM S_V_Capture_Job_Steps WHERE Dataset_ID = _datasetID AND Tool = 'DatasetCapture' AND State IN (1,2,4,5)) Then

                If Exists (SELECT * FROM S_V_Capture_Job_Steps WHERE Dataset_ID = _datasetID AND Tool = 'DatasetIntegrity' AND State = 6) AND Then
                   Exists (SELECT * FROM S_V_Capture_Job_Steps WHERE Dataset_ID = _datasetID AND Tool = 'DatasetCapture' AND State = 5);
                End If;
                Begin
                    -- Do allow a reset if the DatasetIntegrity step failed and if we haven't already retried capture of this dataset once
                    _msg := 'Retrying capture of dataset ' || _datasetName || ' at user request (dataset was captured, but DatasetIntegrity failed)';
                    If Exists (SELECT * FROM t_log_entries WHERE message LIKE _msg + '%') Then
                        _msg := 'Dataset "' || _datasetName || '" cannot be reset because it has already been reset once';

                        If _callingUser = '' Then
                            _logMsg := _msg || '; user ' || session_user;
                        Else
                            _logMsg := _msg || '; user ' || _callingUser;
                        End If;

                        Call post_log_entry ('Error', _logMsg, 'DoDatasetOperation');

                        _msg := _msg || '; please contact a system administrator for further assistance';
                    Else
                        _allowReset := 1;
                        If _callingUser = '' Then
                            _msg := _msg || '; user ' || session_user;
                        Else
                            _msg := _msg || '; user ' || _callingUser;
                        End If;

                        Call post_log_entry ('Warning', _msg, 'DoDatasetOperation');
                    End If;

                Else
                    _msg := 'Dataset "' || _datasetName || '" cannot be reset because it has already been successfully captured; please contact a system administrator for further assistance';
                End If;

                If _allowReset = 0 Then
                    _logErrors := false;
                    RAISE EXCEPTION '%', _msg;
                End If;
            End If;

            -- Update state of dataset to new
            --
            _newState := 1        ; -- "new' state

            UPDATE t_dataset
            SET dataset_state_id = _newState,
                comment = dbo.RemoveCaptureErrorsFromString(comment)
            WHERE dataset_id = _datasetID

            If Not FOUND Then
                _msg := 'Reset was unsuccessful for dataset "' || _datasetName || '"';
                RAISE EXCEPTION '%', _msg;
            End If;

            -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
            If char_length(_callingUser) > 0 Then
                Call alter_event_log_entry_user (4, _datasetID, _newState, _callingUser);
            End If;

            _validMode := true;

        End If; -- </reset>

        If Not _validMode Then
            ---------------------------------------------------
            -- Mode was unrecognized
            ---------------------------------------------------

            _msg := 'Mode "' || _mode ||  '" was unrecognized';
            RAISE EXCEPTION '%', _msg;
        End If;


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

COMMENT ON PROCEDURE public.do_dataset_operation IS 'DoDatasetOperation';