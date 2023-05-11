--
CREATE OR REPLACE PROCEDURE public.unconsume_scheduled_run
(
    _datasetName text,
    _retainHistory boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      The intent is to recycle user-entered requests
**      (where appropriate) and make sure there is
**      a requested run for each dataset (unless
**      dataset is being deleted).
**
**      Disassociates the currently-associated requested run
**      from the given dataset if the requested run was
**      user-entered (as opposted to automatically created
**      when dataset was created with requestID = 0).
**
**      If original requested run was user-entered and _retainHistory is true,
**      copy the original requested run to a new one and associate that one with the given dataset.
**
**      If the given dataset is to be deleted, the _retainHistory flag
**      must be false, otherwise a foreign key constraint will fail
**      when the attempt to delete the dataset is made and the associated
**      request is still hanging around.
**
**  Auth:   grk
**  Date:   3/1/2004 grk - Initial release
**          01/13/2006 grk - Handling for new blocking columns in request and history tables.
**          01/17/2006 grk - Handling for new EUS tracking columns in request and history tables.
**          03/10/2006 grk - Fixed logic to handle absence of associated request
**          03/10/2006 grk - Fixed logic to handle null batchID on old requests
**          05/01/2007 grk - Modified logic to optionally retain original history (Ticket #446)
**          07/17/2007 grk - Increased size of comment field (Ticket #500)
**          04/08/2008 grk - Added handling for separation field (Ticket #658)
**          03/26/2009 grk - Added MRM transition list attachment (Ticket #727)
**          02/24/2010 grk - Added handling for requested run factors
**          02/26/2010 grk - merged T_Requested_Run_History with T_Requested_Run
**          03/02/2010 grk - added status field to requested run
**          08/04/2010 mem - No longer updating the "date created" date for the recycled request
**          12/13/2011 mem - Added parameter _callingUser, which is sent to CopyRequestedRun, alter_event_log_entry_user, and DeleteRequestedRun
**          02/20/2013 mem - Added ability to lookup the original request from an auto-created recycled request
**          02/21/2013 mem - Now validating that the RequestID extracted from 'Automatically created by recycling request 12345' actually exists
**          05/08/2013 mem - Removed parameters _wellplateName and _wellNumber since no longer used
**          07/08/2014 mem - Now checking for empty requested run comment
**          03/22/2016 mem - Now passing _skipDatasetCheck to DeleteRequestedRun
**          11/16/2016 mem - Call update_cached_requested_run_eus_users to update T_Active_Requested_Run_Cached_EUS_Users
**          03/07/2017 mem - Append _Recycled to new requests created when _recycleRequest is yes
**                         - Remove leading space in message ' (recycled from dataset ...'
**          06/12/2018 mem - Send _maxLength to AppendToText
**          06/14/2019 mem - Change cart to Unknown when making the request active again
**          10/23/2021 mem - If recycling a request with queue state 3 (Analyzed), change the queue state to 2 (Assigned)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetID int := 0;
    _requestComment text := '';
    _requestID int := 0;
    _requestOrigin text;
    _currentQueueState int     -- 1:= Unassigned, 2=Assigned, 3=Analyzed;
    _requestIDOriginal int := 0;
    _copyRequestedRun boolean := false;
    _recycleOriginalRequest boolean := false;
    _autoCreatedRequest boolean := false;
    _newCartID int := null;
    _warningMessage text;
    _notation text;
    _addnlText text;
    _charIndex int;
    _extracted text;
    _originalRequestStatus text := '';
    _originalRequesetDatasetID int := 0;
    _requestNameAppendText text := '_Recycled';
    _newStatus text := 'Active';
    _newQueueState int;
    _stateID int := 0;
BEGIN
    _message := Coalesce(_message, '');
    _returnCode := '';

    ---------------------------------------------------
    -- Get datasetID
    ---------------------------------------------------
    --
    SELECT dataset_id INTO _datasetID
    FROM t_dataset
    WHERE dataset = _datasetName;
    --
    If _datasetID = 0 Then
        _message := 'Dataset does not exist"' || _datasetName || '"';
        _returnCode := 'U5141';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Look for associated request for dataset
    ---------------------------------------------------

    SELECT request_id,
           comment,
           origin,
           queue_state
    INTO _requestID, _requestComment, _requestOrigin, _currentQueueState
    FROM t_requested_run
    WHERE dataset_id = _datasetID;

    ---------------------------------------------------
    -- We are done if there is no associated request
    ---------------------------------------------------
    If Not FOUND Then
        RETURN;
    End If;

    ---------------------------------------------------
    -- Was request automatically created by dataset entry?
    ---------------------------------------------------
    --

    If _requestOrigin = 'auto' Then
        _autoCreatedRequest := true;
    End If;

    ---------------------------------------------------
    -- Determine the ID of the 'unknown' cart
    ---------------------------------------------------

    SELECT cart_id INTO _newCartID
    FROM t_lc_cart
    WHERE cart_name = 'unknown'

    If Not FOUND Then
        _warningMessage := 'Could not find the cart named "unknown" in t_lc_cart; the Cart cart_id of the recycled requested run will be left unchanged';
        Call post_log_entry ('Error', _warningMessage, 'Unconsume_Scheduled_Run');
    End If;

    ---------------------------------------------------
    -- Reset request
    -- if it was not automatically created
    ---------------------------------------------------

    If Not _autoCreatedRequest Then
    -- <a1>
        ---------------------------------------------------
        -- Original request was user-entered,
        -- We will copy it (if commanded to) and set status to 'Completed'
        ---------------------------------------------------
        --
        _requestIDOriginal := _requestID;
        _recycleOriginalRequest := true;

        If _retainHistory Then
            _copyRequestedRun := true;
        End If;

    Else
    -- <a2>
        ---------------------------------------------------
        -- Original request was auto created
        -- delete it (if commanded to)
        ---------------------------------------------------
        --
        If Not _retainHistory Then
        -- <b2>
            Call delete_requested_run (
                                 _requestID,
                                 _skipDatasetCheck => true,
                                 _message => _message,              -- Output
                                 _returnCode => _returnCode,        -- Output
                                 _callingUser => _callingUser);

            --
            If _returnCode <> '' Then
                ROLLBACK;
                RETURN;
            End If;
        Else
        -- <b3>

            ---------------------------------------------------
            -- Original request was auto-created
            -- Examine the request comment to determine if it was a recycled request
            ---------------------------------------------------
            --
            If _requestComment SIMILAR TO '%Automatically created by recycling request [0-9]%[0-9] from dataset [0-9]%' Then
            -- <c>

                -- Determine the original request ID
                --

                _charIndex := Position('by recycling request' In _requestComment);

                If _charIndex > 0 Then
                -- <d>
                    _extracted := LTRIM(SUBSTRING(_requestComment, _charIndex + char_length('by recycling request'), 20));

                    -- Comment is now of the form: '286793 from dataset'
                    -- Find the space after the number
                    --
                    _charIndex := Position(' ' In _extracted);

                    If _charIndex > 0 Then
                    -- <e>
                        _extracted := Trim(SUBSTRING(_extracted, 1, _charindex));

                        -- Original requested ID has been determined; copy the original request
                        --
                        _requestIDOriginal := _extracted::int;
                        _recycleOriginalRequest := true;

                        -- Make sure the original request actually exists
                        If Not Exists (SELECT * FROM t_requested_run WHERE request_id = _requestIDOriginal) Then
                            -- Original request doesn't exist; recycle this recycled one
                            _requestIDOriginal := _requestID;
                        End If;

                        -- Make sure that the original request is not active
                        -- In addition, lookup the dataset ID of the original request

                        SELECT state_name, INTO _originalRequestStatus
                               _originalRequesetDatasetID = dataset_id
                        FROM t_requested_run
                        WHERE request_id = _requestIDOriginal

                        If _originalRequestStatus = 'Active' Then
                            -- The original request is active, don't recycle anything

                            If _requestIDOriginal = _requestID Then
                                _addnlText := 'Not recycling request ' || _requestID::text || ' for dataset ' || _datasetName || ' since it is already active';
                                Call post_log_entry ('Warning', _addnlText, 'Unconsume_Scheduled_Run');

                                _addnlText := 'Not recycling request ' || _requestID::text || ' since it is already active';
                                _message := public.append_to_text(_message, _addnlText, 0, '; ', 1024);
                            Else
                                _addnlText := 'Not recycling request ' || _requestID::text || ' for dataset ' || _datasetName || ' since dataset already has an active request (' || _extracted || ')';
                                Call post_log_entry ('Warning', _addnlText, 'Unconsume_Scheduled_Run');

                                _addnlText := 'Not recycling request ' || _requestID::text || ' since dataset already has an active request (' || _extracted || ')';
                                _message := public.append_to_text(_message, _addnlText, 0, '; ', 1024);
                            End If;

                            _requestIDOriginal := 0;
                        Else
                            _copyRequestedRun := true;
                            _datasetID := _originalRequesetDatasetID;
                        End If;

                    End If; -- </e>
                End If; -- </d>
            Else
                _addnlText := 'Not recycling request ' || _requestID::text || ' for dataset ' || _datasetName || ' since AutoRequest';
                _message := public.append_to_text(_message, _addnlText, 0, '; ', 1024);
            End If;

        End If; -- </b3>

    End If; -- <a2>

    If _requestIDOriginal > 0 And _copyRequestedRun Then
    -- <a3>

        ---------------------------------------------------
        -- Copy the request and associate the dataset with the newly created request
        ---------------------------------------------------
        --
        -- Warning: The text 'Automatically created by recycling request' is used earlier in this procedure; thus, do not update it here
        --
        _notation := format('Automatically created by recycling request %s from dataset %s on %s',
                            _requestIDOriginal, _datasetID, to_char(CURRENT_TIMESTAMP, 'mm/dd/yyyy'));

        Call copy_requested_run (
                _requestIDOriginal,
                _datasetID,
                'Completed',
                _notation,
                _requestNameAppendText = _requestNameAppendText,
                _message => _message,               -- Output
                _returnCode => _returnCode,         -- Output
                _callingUser = _callingUser);

        If _returnCode <> '' Then
            RETURN;
        End If;
    End If; -- </a3>

    If _requestIDOriginal > 0 And _recycleOriginalRequest Then
    -- <a4>

        ---------------------------------------------------
        -- Recycle the original request
        ---------------------------------------------------
        --
        -- Create annotation to be appended to comment
        --
        _notation := format('(recycled from dataset %s on %s)',
                            _datasetID, to_char(CURRENT_TIMESTAMP, 'mm/dd/yyyy'));

        If char_length(_requestComment) + char_length(_notation) > 1024 Then
            -- Dataset comment could become too long; do not append the additional note
            _notation := '';
        End If;

        -- Reset the requested run to 'Active'
        -- Do not update Created; we want to keep it as the original date for planning purposes
        --

        If _currentQueueState In (2,3) Then
            _newQueueState := 2     ; -- Assigned
        Else
            _newQueueState := 1     ; -- Unassigned;
        End If;

        Update t_requested_run
        SET
            state_name = _newStatus,
            request_run_start = NULL,
            request_run_finish = NULL,
            dataset_id = NULL,
            comment = CASE WHEN Coalesce(comment, '') = '' THEN _notation ELSE comment || ' ' || _notation End,
            cart_id = Coalesce(_newCartID, cart_id),
            queue_state = _newQueueState
        WHERE
            request_id = _requestIDOriginal

        If char_length(_callingUser) > 0 Then

            SELECT state_id INTO _stateID
            FROM t_requested_run_state_name
            WHERE (state_name = _newStatus)

            Call alter_event_log_entry_user (11, _requestIDOriginal, _stateID, _callingUser);
        End If;

        ---------------------------------------------------
        -- Make sure that t_active_requested_run_cached_eus_users is up-to-date
        ---------------------------------------------------
        --
        Call update_cached_requested_run_eus_users (
            _requestIDOriginal,
            _message => _message,           -- Output
            _returnCode => _returnCode);    -- Output

    End If; -- </a4>

END
$$;

COMMENT ON PROCEDURE public.unconsume_scheduled_run IS 'UnconsumeScheduledRun';

