--
CREATE OR REPLACE PROCEDURE public.copy_requested_run
(
    _requestID int,
    _datasetID int,
    _status text,
    _notation text,
    _requestNameAppendText text = '',
    _requestNameOverride text = '',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = '',
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Make copy of given requested run and associate it with given dataset
**
**  Arguments:
**    _status                  Active, Completed, or Inactive
**    _notation                Requested run comment
**    _requestNameAppendText   Text appended to the name of the newly created request; append nothing if null or ''
**    _requestNameOverride     New request name to use; if blank, will be based on the existing request name, but will append _requestNameAppendText
**
**  Auth:   grk
**  Date:   02/26/2010
**          03/03/2010 grk - Added status field
**          08/04/2010 mem - Now using the Created date from the original request as the Created date for the new request
**          08/30/2010 mem - Now clearing _message after a successful call to Update_Requested_Run_Copy_Factors
**          12/13/2011 mem - Added parameter _callingUser, which is sent to Update_Requested_Run_Copy_Factors
**          04/25/2012 mem - Fixed _callingUser bug when updating _callingUserUnconsume
**          02/21/2013 mem - Now verifying that a new row was added to T_Requested_Run
**          05/08/2013 mem - Now copying Vialing_Conc and Vialing_Vol
**          11/16/2016 mem - Call update_cached_requested_run_eus_users to update T_Active_Requested_Run_Cached_EUS_Users
**          02/23/2017 mem - Add column cart_config_id
**          03/07/2017 mem - Add parameter _requestNameAppendText
**                         - Assure that the newly created request has a unique name
**          08/06/2018 mem - Rename Operator PRN column to RDS_Requestor_PRN
**          10/19/2020 mem - Rename the instrument group column to instrument_group
**          01/19/2021 mem - Add parameters _requestNameOverride and _infoOnly
**          02/10/2023 mem - Call update_cached_requested_run_batch_stats
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _stateID int := 0;
    _newRequestID int;
    _oldRequestName text;
    _newRequestName text;
    _stateNameList text := NULL;
    _iteration int;
    _callingUserUnconsume text;
    _batchID int;
    _msg text;
BEGIN
    _message := '';
    _returnCode := '';

    _requestNameAppendText := Trim(Coalesce(_requestNameAppendText, ''));
    _requestNameOverride := Trim(Coalesce(_requestNameOverride, ''));

    _callingUser := Coalesce(_callingUser, '');
    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- We are done if there is no associated request
    ---------------------------------------------------

    _requestID := Coalesce(_requestID, 0);
    If _requestID = 0 Then
        _message := 'Source request ID is 0; nothing to do';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make sure the source request exists
    ---------------------------------------------------

    SELECT request_name
    INTO _oldRequestName
    FROM t_requested_run
    WHERE request_id = _requestID

    If Not FOUND Then
        _message := format('Source request not found in t_requested_run: %s', _requestID);
        CALL post_log_entry ('Error', _message, 'Copy_Requested_Run');
        RETURN;
    End If;

    ---------------------------------------------------
    -- Validate _status
    ---------------------------------------------------

    SELECT state_id
    INTO _stateID
    FROM t_requested_run_state_name
    WHERE state_name = _status;

    If Not FOUND Then

        SELECT string_agg(state_name, ', ' ORDER BY state_id)
        INTO _stateNameList
        FROM t_requested_run_state_name

        _message := format('Invalid requested run state: %s; valid states are %s', _status, _stateNameList);
        CALL post_log_entry ('Error', _message, 'Copy_Requested_Run');

        RETURN;
    End If;

    ---------------------------------------------------
    -- Determine the name for the new request
    -- Note that _requestNameAppendText may be blank
    ---------------------------------------------------

    If _requestNameOverride = '' Then
        _newRequestName := format('%s%s' _oldRequestName, _requestNameAppendText);
    Else
        _newRequestName := _requestNameOverride;
    End If;

    _iteration := 1;

    WHILE true
    LOOP
        If Not Exists (SELECT * FROM t_requested_run WHERE request_name = _newRequestName) Then
            -- Break out of the while loop
            EXIT;
        End If;

        _iteration := _iteration + 1;
        _newRequestName := format('%s%s%s', _oldRequestName, _requestNameAppendText, _iteration);

    END LOOP;

    If _infoOnly Then

        -- ToDo: Update this to use RAISE INFO


        SELECT
            request_id As Source_Request_ID,
            request_name As Source_Request_Name,
            _newRequestName As New_Request_Name,
            _notation As Comment,
            requester_username,
            created,                -- Pass along the original request's 'created' date into the new entry
            instrument_group,
            request_type_id,
            instrument_setting,
            special_instructions,
            wellplate,
            well,
            vialing_conc,
            vialing_vol,
            priority,
            note,
            exp_id,
            request_run_start,
            request_run_finish,
            request_internal_standard,
            work_package,
            batch_id,
            blocking_factor,
            block,
            run_order,
            eus_proposal_id,
            eus_usage_type_id,
            cart_id,
            cart_config_id,
            cart_column,
            separation_group,
            mrm_attachment,
            _status,
            'auto',
            CASE WHEN Coalesce(_datasetID, 0) = 0 THEN NULL ELSE _datasetID END
        FROM t_requested_run
        WHERE request_id = _requestID

        RETURN;
    End If;

    ---------------------------------------------------
    -- Make copy
    ---------------------------------------------------

    -- Make new request
    --
    INSERT INTO t_requested_run
    (
        comment,
        request_name,
        requester_username,
        created,
        instrument_group,
        request_type_id,
        instrument_setting,
        special_instructions,
        wellplate,
        well,
        vialing_conc,
        vialing_vol,
        priority,
        note,
        exp_id,
        request_run_start,
        request_run_finish,
        request_internal_standard,
        work_package,
        batch_id,
        blocking_factor,
        block,
        run_order,
        eus_proposal_id,
        eus_usage_type_id,
        cart_id,
        cart_config_id,
        cart_column,
        separation_group,
        mrm_attachment,
        state_name,
        origin,
        dataset_id
    )
    SELECT
        _notation,
        _newRequestName,
        requester_username,
        created,                -- Pass along the original request's 'created' date into the new entry
        instrument_group,
        request_type_id,
        instrument_setting,
        special_instructions,
        wellplate,
        well,
        vialing_conc,
        vialing_vol,
        priority,
        note,
        exp_id,
        request_run_start,
        request_run_finish,
        request_internal_standard,
        work_package,
        batch_id,
        blocking_factor,
        block,
        run_order,
        eus_proposal_id,
        eus_usage_type_id,
        cart_id,
        cart_config_id,
        cart_column,
        separation_group,
        mrm_attachment,
        _status,
        'auto',
        CASE WHEN Coalesce(_datasetID, 0) = 0 THEN NULL ELSE _datasetID END
    FROM t_requested_run
    WHERE request_id = _requestID
    RETURNING request_id
    INTO _newRequestID;

    If Not FOUND Then
        If Not Exists (Select * from t_requested_run Where request_id = _requestID) Then
            _message := format('Problem trying to renumber request in history; RequestID not found: %s', _requestID);
        Else
            _message := format('Problem trying to renumber request in history; No rows added for RequestID %s', _requestID);
        End If;

        CALL post_log_entry ('Error', _message, 'Copy_Requested_Run');
        RETURN;
    End If;

    If char_length(_callingUser) > 0 Then
        CALL alter_event_log_entry_user (11, _newRequestID, _stateID, _callingUser);
    End If;

    ------------------------------------------------------------
    -- Copy factors from the request being unconsumed to the
    -- renumbered copy being retained in the history
    ------------------------------------------------------------

    -- First define the calling user text
    --

    If Coalesce(_callingUser, '') <> '' Then
        _callingUserUnconsume := format('(unconsume for %s)', _callingUser);
    Else
        _callingUserUnconsume := '(unconsume)';
    End If;

    -- Now copy the factors
    --
    CALL update_requested_run_copy_factors (
                        _requestID,
                        _newRequestID,
                        _message => _message,           -- Output
                        _callingUserUnconsume,
                        _returnCode => _returnCode);    -- Output

    If _returnCode <> '' Then
        _message := format('Problem copying factors to new request; _returnCode = %s', _returnCode);
        CALL post_log_entry ('Error', _message, 'Copy_Requested_Run');
        RETURN;
    Else
        -- _message may contain the text 'Nothing to copy'
        -- We don't need that text appearing on the web page, so we'll clear _message
        _message := '';
    End If;

    ---------------------------------------------------
    -- Copy proposal users for new auto request
    -- from original request
    ---------------------------------------------------

    INSERT INTO t_requested_run_eus_users (eus_person_id, request_id)
    SELECT eus_person_id, _newRequestID
    FROM t_requested_run_eus_users
    WHERE request_id = _requestID;


    ---------------------------------------------------
    -- Make sure that t_active_requested_run_cached_eus_users is up-to-date
    ---------------------------------------------------

    CALL update_cached_requested_run_eus_users (
            _newRequestID,
            _message => _message,           -- Output
            _returnCode => _returnCode);    -- Output

    ---------------------------------------------------
    -- Update stats in t_cached_requested_run_batch_stats
    ---------------------------------------------------

    SELECT Batch_ID
    INTO _batchID
    FROM t_requested_run
    WHERE request_id = _requestID;

    If _batchID > 0 Then
        CALL update_cached_requested_run_batch_stats (
                    _batchID,
                    _message => _msg,               -- Output
                    _returnCode => _returnCode);    -- Output

        If _returnCode <> '' Then
            _message := public.append_to_text(_message, _msg, 0, '; ', 1024);
        End If;
    End If;
END
$$;

COMMENT ON PROCEDURE public.copy_requested_run IS 'CopyRequestedRun';
