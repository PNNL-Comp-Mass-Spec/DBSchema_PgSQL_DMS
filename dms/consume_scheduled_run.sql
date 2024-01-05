--
-- Name: consume_scheduled_run(integer, integer, text, text, text, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.consume_scheduled_run(IN _datasetid integer, IN _requestid integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text, IN _logdebugmessages boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Associate given requested run with the given dataset
**
**  Arguments:
**    _datasetID            Dataset ID
**    _requestID            Requested run ID
**    _message              Status message
**    _returnCode           Return code
**    _callingUser          Username of the calling user
**    _logDebugMessages     If true, log debug messages
**
**  Auth:   grk
**  Date:   02/13/2003 grk - Initial release
**          01/05/2002 grk - Added stuff for Internal Standard and cart parameters
**          03/01/2004 grk - Added validation for experiments matching between request and dataset
**          10/12/2005 grk - Added stuff to copy new work package and proposal fields.
**          01/13/2006 grk - Handling for new blocking columns in request and history tables.
**          01/17/2006 grk - Handling for new EUS tracking columns in request and history tables.
**          04/08/2008 grk - Added handling for separation field (Ticket #658)
**          03/26/2009 grk - Added MRM transition list attachment (Ticket #727)
**          02/26/2010 grk - Merged T_Requested_Run_History with T_Requested_Run
**          11/29/2011 mem - Now calling Add_Requested_Run_To_Existing_Dataset if re-using an existing request
**          12/05/2011 mem - Updated call to Add_Requested_Run_To_Existing_Dataset to include _datasetName
**                         - Now copying batch and blocking info from the existing request to the new auto-request created by Add_Requested_Run_To_Existing_Dataset
**          12/12/2011 mem - Updated log message when re-using an existing request
**          12/14/2011 mem - Added parameter _callingUser, which is passed to Add_Requested_Run_To_Existing_Dataset and alter_event_log_entry_user
**          11/16/2016 mem - Call update_cached_requested_run_eus_users to update T_Active_Requested_Run_Cached_EUS_Users
**          11/21/2016 mem - Add parameter _logDebugMessages
**          05/22/2017 mem - No longer abort the addition if a request already exists named AutoReq_DatasetName
**          09/13/2023 mem - Ported to PostgreSQL
**          12/28/2023 mem - Use a variable for target type when calling alter_event_log_entry_user()
**
*****************************************************/
DECLARE
    _existingDatasetID int;
    _logMessage text;
    _experimentID int;
    _reqExperimentID int;
    _existingDatasetName text;
    _newAutoRequestID int;
    _stateName text;
    _stateID int;
    _targetType int;
    _alterEnteredByMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _datasetID := Coalesce(_datasetID, 0);
    _requestID := Coalesce(_requestID, 0);

    ---------------------------------------------------
    -- Validate that experiments match
    ---------------------------------------------------

    -- Get experiment ID from dataset

    SELECT exp_id
    INTO _experimentID
    FROM t_dataset
    WHERE dataset_id = _datasetID;

    If Not FOUND Then
        _message := format('Dataset ID %s not found in t_dataset', _datasetID);
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    -- Get experiment ID from requested run

    SELECT exp_id
    INTO _reqExperimentID
    FROM t_requested_run
    WHERE request_id = _requestID;

    If Not FOUND Then
        _message := format('Requested Run ID %s not found in t_requested_run', _requestID);
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    If Coalesce(_experimentID, -1) <> Coalesce(_reqExperimentID, -2) Then
        _message := format('Experiment ID for dataset does not match the one associated with the requested run: %s vs. %s', _experimentID, _reqExperimentID);
        RAISE WARNING '%', _message;

        _returnCode := 'U5203';
        RETURN;
    End If;

    If _logDebugMessages Then
        _logMessage := format('Creating a new auto-request for dataset ID %s', _existingDatasetID);
        CALL post_log_entry ('Debug', _logMessage, 'Consume_Scheduled_Run');
    End If;

    BEGIN

        -- If request already has a dataset associated with it, we need to create a new auto-request for that dataset

        SELECT dataset_id
        INTO _existingDatasetID
        FROM t_requested_run
        WHERE request_id = _requestID AND Not dataset_id Is Null;

        If FOUND And _existingDatasetID > 0 And _existingDatasetID <> _datasetID Then

            ---------------------------------------------------
            -- Create new auto-request, but only if the dataset doesn't already have one
            ---------------------------------------------------

            SELECT dataset
            INTO _existingDatasetName
            FROM t_dataset
            WHERE dataset_id = _existingDatasetID;

            -- Change DatasetID to Null for this request before calling Add_Requested_Run_To_Existing_Dataset
            UPDATE t_requested_run
            SET dataset_id = Null
            WHERE request_id = _requestID;

            CALL public.add_requested_run_to_existing_dataset (
                            _datasetID         => _existingDatasetID,
                            _datasetName       => '',
                            _templateRequestID => _requestID,
                            _mode              => 'add',
                            _message           => _message,         -- Output
                            _returnCode        => _returnCode,      -- Output
                            _callingUser       => _callingUser);

            -- Lookup the request ID created for _existingDatasetName

            SELECT request_id
            INTO _newAutoRequestID
            FROM t_requested_run
            WHERE dataset_id = _existingDatasetID;

            If FOUND Then

                _logMessage := format('Added new automatic requested run since re-using request %s; dataset "%s" is now associated with request %s',
                                      _requestID, _existingDatasetName, _newAutoRequestID);

                CALL post_log_entry ('Warning', _logMessage, 'Consume_Scheduled_Run');

                -- Copy batch and blocking information from the existing request to the new request

                UPDATE t_requested_run Target
                SET batch_id = Source.batch_id,
                    blocking_factor = Source.blocking_factor,
                    block = Source.block,
                    run_order = Source.run_order
                FROM ( SELECT RR.batch_id,
                              RR.blocking_factor,
                              RR.block,
                              RR.run_order
                       FROM t_requested_run RR
                       WHERE RR.request_id = _requestID
                    ) Source
                WHERE Target.request_id = _newAutoRequestID;

            Else

                _logMessage := format('Tried to add a new automatic requested run for dataset "%s" since re-using request %s; however, add_requested_run_to_existing_dataset was unable to auto-create a new requested run',
                                      _existingDatasetName, _requestID);

                CALL post_log_entry ('Error', _logMessage, 'Consume_Scheduled_Run');

            End If;

        End If;

        ---------------------------------------------------
        -- Change the state of the Requested Run to Completed
        ---------------------------------------------------

        _stateName := 'Completed';

        UPDATE t_requested_run
        SET dataset_id = _datasetID,
            state_name = _stateName
        WHERE request_id = _requestID;

        -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
        If Trim(Coalesce(_callingUser, '')) <> '' Then

            SELECT state_id
            INTO _stateID
            FROM t_requested_run_state_name
            WHERE state_name = _stateName;

            _targetType := 11;
            CALL public.alter_event_log_entry_user ('public', _targetType, _requestID, _stateID, _callingUser, _message => _alterEnteredByMessage);
        End If;

    END;

    If _logDebugMessages Then
        _logMessage := format('Call update_cached_requested_run_eus_users for %s', _requestID);
        CALL post_log_entry ('Debug', _logMessage, 'Consume_Scheduled_Run');
    End If;

    ---------------------------------------------------
    -- Make sure that t_active_requested_run_cached_eus_users is up-to-date
    -- This procedure will delete the cached EUS user list from t_active_requested_run_cached_eus_users for this request ID
    ---------------------------------------------------

    CALL public.update_cached_requested_run_eus_users (
                    _requestID,
                    _message    => _message,        -- Output
                    _returnCode => _returnCode);    -- Output

END
$$;


ALTER PROCEDURE public.consume_scheduled_run(IN _datasetid integer, IN _requestid integer, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _logdebugmessages boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE consume_scheduled_run(IN _datasetid integer, IN _requestid integer, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _logdebugmessages boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.consume_scheduled_run(IN _datasetid integer, IN _requestid integer, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _logdebugmessages boolean) IS 'ConsumeScheduledRun';

