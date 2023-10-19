--
-- Name: unconsume_scheduled_run(text, boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.unconsume_scheduled_run(IN _datasetname text, IN _retainhistory boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      This procedure recycles user-entered requested runs (where appropriate)
**      and makes sure there is an active requested run for each dataset (unless the dataset is being deleted)
**
**      It disassociates the currently-associated requested run from the given dataset if the requested run was user-entered
**      (as opposed to automatically created when the dataset was created and requestID was 0)
**
**      If the original requested run was user-entered and _retainHistory is true,
**      copy the original requested run to a new one and associate that one with the given dataset
**
**      If the given dataset is to be deleted, the _retainHistory flag must be false,
**      otherwise a foreign key constraint will fail when the attempt to delete the dataset is made
**      and the associated request is still hanging around.
**
**  Arguments:
**    _datasetName      Dataset name
**    _retainHistory    If true and the requested run associated with the dataset was not auto-created, copy the original requested run to a new one and associate that one with the given dataset
**                      If false and the requested run was auto-created, delete the requested run
**                      See the code for other situations
**
**  Auth:   grk
**  Date:   03/01/2004 grk - Initial release
**          01/13/2006 grk - Handling for new blocking columns in request and history tables.
**          01/17/2006 grk - Handling for new EUS tracking columns in request and history tables.
**          03/10/2006 grk - Fixed logic to handle absence of associated request
**          03/10/2006 grk - Fixed logic to handle null batchID on old requests
**          05/01/2007 grk - Modified logic to optionally retain original history (Ticket #446)
**          07/17/2007 grk - Increased size of comment field (Ticket #500)
**          04/08/2008 grk - Added handling for separation field (Ticket #658)
**          03/26/2009 grk - Added MRM transition list attachment (Ticket #727)
**          02/24/2010 grk - Added handling for requested run factors
**          02/26/2010 grk - Merged T_Requested_Run_History with T_Requested_Run
**          03/02/2010 grk - Added status field to requested run
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
**          06/12/2018 mem - Send _maxLength to Append_To_Text
**          06/14/2019 mem - Change cart to Unknown when making the request active again
**          10/23/2021 mem - If recycling a request with queue state 3 (Analyzed), change the queue state to 2 (Assigned)
**          09/16/2023 mem - Ported to PostgreSQL
**          10/18/2023 mem - Fix typo in format string
**
*****************************************************/
DECLARE
    _datasetID int;
    _requestComment citext;
    _requestID int;
    _requestOrigin citext;
    _currentQueueState int;
    _requestIDOriginal int := 0;
    _copyRequestedRun boolean := false;
    _recycleOriginalRequest boolean := false;
    _autoCreatedRequest boolean := false;
    _newCartID int;
    _warningMessage text;
    _comment text;
    _addnlText text;
    _charIndex int;
    _extracted text;
    _originalRequestStatus citext;
    _originalRequesetDatasetID int;
    _newStatus text;
    _newQueueState int;
    _stateID int;
    _alterEnteredByMessage text;
BEGIN
    _message := Coalesce(_message, '');
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _datasetName   := Trim(Coalesce(_datasetName, ''));
    _retainHistory := Coalesce(_retainHistory, false);

    ---------------------------------------------------
    -- Resolve dataset name to ID
    ---------------------------------------------------

    SELECT dataset_id
    INTO _datasetID
    FROM t_dataset
    WHERE dataset = _datasetName;

    If Not FOUND Then
        _message := format('Dataset does not exist: "%s"', _datasetName);
        _returnCode := 'U5141';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Look for requested run for dataset
    ---------------------------------------------------

    SELECT request_id,
           comment,
           origin,
           queue_state
    INTO _requestID, _requestComment, _requestOrigin, _currentQueueState
    FROM t_requested_run
    WHERE dataset_id = _datasetID;

    If Not FOUND Then
        -- Dataset does not have a requested run
        _message := format('Dataset ID %s does not have a requested run; nothing to unconsume', _datasetID);
        RAISE INFO '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Was request automatically created by dataset entry?
    ---------------------------------------------------

    If _requestOrigin = 'auto' Then
        _autoCreatedRequest := true;
    End If;

    ---------------------------------------------------
    -- Determine the ID of the 'unknown' cart
    ---------------------------------------------------

    SELECT cart_id
    INTO _newCartID
    FROM t_lc_cart
    WHERE cart_name = 'unknown';

    If Not FOUND Then
        _warningMessage := 'Could not find the cart named "unknown" in t_lc_cart; the cart_id of the recycled requested run will be left unchanged';
        CALL post_log_entry ('Error', _warningMessage, 'Unconsume_Scheduled_Run');
    End If;

    ---------------------------------------------------
    -- Reset request if it was not automatically created
    ---------------------------------------------------

    If Not _autoCreatedRequest Then
        ---------------------------------------------------
        -- Original request was user-entered,
        -- We will copy it (if commanded to) and set status to 'Completed'
        ---------------------------------------------------

        _requestIDOriginal := _requestID;
        _recycleOriginalRequest := true;

        If _retainHistory Then
            _copyRequestedRun := true;
        End If;

    Else
        ---------------------------------------------------
        -- Original request was auto created
        -- Delete it (if commanded to)
        ---------------------------------------------------

        If Not _retainHistory Then
            CALL public.delete_requested_run (
                                 _requestID,
                                 _skipDatasetCheck => true,
                                 _message          => _message,         -- Output
                                 _returnCode       => _returnCode,      -- Output
                                 _callingUser      => _callingUser);

            If _returnCode <> '' Then
                ROLLBACK;
                RETURN;
            End If;
        Else

            ---------------------------------------------------
            -- Original request was auto-created
            -- Examine the request comment to determine if it was a recycled request
            ---------------------------------------------------

            If Not _requestComment SIMILAR TO '%Automatically created by recycling request [0-9]%[0-9] from dataset [0-9]%' Then

                _addnlText := format('Not recycling request %s for dataset %s since it is an AutoRequest', _requestID, _datasetName);
                _message := public.append_to_text(_message, _addnlText);

            Else

                -- Determine the original request ID
                -- Use Lower() since Position() uses case sensitive matching, even if the variable is citext

                _charIndex := Position(Lower('by recycling request') In Lower(_requestComment));

                If _charIndex > 0 Then

                    _extracted := LTrim(SUBSTRING(_requestComment, _charIndex + char_length('by recycling request'), 20));

                    -- Comment is now of the form: '286793 from dataset'
                    -- Find the space after the number

                    _charIndex := Position(' ' In _extracted);

                    If _charIndex > 0 Then

                        _extracted := Trim(SUBSTRING(_extracted, 1, _charindex));

                        -- Original requested ID has been determined; copy the original request

                        _requestIDOriginal := public.try_cast(_extracted, 0);
                        _recycleOriginalRequest := true;

                        -- Make sure the original request actually exists

                        If Not Exists (SELECT request_id FROM t_requested_run WHERE request_id = _requestIDOriginal) Then
                            -- Original request doesn't exist; recycle this recycled one
                            _requestIDOriginal := _requestID;
                        End If;

                        -- Make sure that the original request is not active
                        -- In addition, lookup the dataset ID of the original request

                        SELECT state_name, dataset_id
                        INTO _originalRequestStatus, _originalRequesetDatasetID
                        FROM t_requested_run
                        WHERE request_id = _requestIDOriginal;

                        If _originalRequestStatus = 'Active' Then
                            -- The original request is active, don't recycle anything

                            If _requestIDOriginal = _requestID Then
                                _addnlText := format('Not recycling request %s for dataset %s since it is already active', _requestID, _datasetName);

                                CALL post_log_entry ('Warning', _addnlText, 'Unconsume_Scheduled_Run');

                                _addnlText := format('Not recycling request %s since it is already active', _requestID);
                                _message := public.append_to_text(_message, _addnlText);
                            Else
                                _addnlText := format('Not recycling request %s for dataset %s since the dataset already has an active request (%s)', _requestID, _datasetName, _extracted);

                                CALL post_log_entry ('Warning', _addnlText, 'Unconsume_Scheduled_Run');

                                _addnlText := format('Not recycling request %s since the dataset already has an active request (%s)', _requestID, _extracted);
                                _message := public.append_to_text(_message, _addnlText);
                            End If;

                            _requestIDOriginal := 0;
                        Else
                            _copyRequestedRun := true;
                            _datasetID := _originalRequesetDatasetID;
                        End If;

                    End If;
                End If;
            End If;

        End If;

    End If;

    _requestIDOriginal := Coalesce(_requestIDOriginal, 0);

    If _requestIDOriginal > 0 And _copyRequestedRun Then
        ---------------------------------------------------
        -- Copy the requested run and associate the dataset with the newly created requested run
        ---------------------------------------------------

        -- Warning: The text 'Automatically created by recycling request' is used earlier in this procedure; thus, do not update it here
        --
        _comment := format('Automatically created by recycling request %s from dataset %s on %s',
                            _requestIDOriginal, _datasetID, to_char(CURRENT_TIMESTAMP, 'mm/dd/yyyy'));

        CALL public.copy_requested_run (
                _requestIDOriginal,
                _datasetID,
                'Completed',
                _comment,
                _requestNameAppendText => '_Recycled',
                _requestNameOverride   => '',
                _message               => _message,         -- Output
                _returnCode            => _returnCode,      -- Output
                _callingUser           => _callingUser,
                _infoOnly              => false);

        If _returnCode <> '' Then
            RETURN;
        End If;
    End If;

    If _requestIDOriginal = 0 Or Not _recycleOriginalRequest Then
        RETURN;
    End If;

    ---------------------------------------------------
    -- Recycle the original request
    ---------------------------------------------------

    -- Create annotation to be appended to comment

    _comment := format('(recycled from dataset %s on %s)', _datasetID, to_char(CURRENT_TIMESTAMP, 'mm/dd/yyyy'));

    If char_length(_requestComment) + char_length(_comment) > 1024 Then
        -- Dataset comment could become too long; do not append the additional note
        _comment := '';
    End If;

    -- Reset the requested run to 'Active'
    -- Do not update Created; we want to keep it as the original date for planning purposes

    If _currentQueueState In (2, 3) Then    -- 2=Assigned, 3=Analyzed
        _newQueueState := 2;                -- Assigned
    Else
        _newQueueState := 1;                -- Unassigned;
    End If;

    _newStatus := 'Active';

    UPDATE t_requested_run
    SET state_name = _newStatus,
        request_run_start = NULL,
        request_run_finish = NULL,
        dataset_id = NULL,
        comment = CASE WHEN Trim(Coalesce(comment, '')) = ''
                       THEN _comment
                       ELSE format('%s %s', comment, _comment)
                  END,
        cart_id = Coalesce(_newCartID, cart_id),
        queue_state = _newQueueState
    WHERE request_id = _requestIDOriginal;

    If char_length(_callingUser) > 0 Then

        SELECT state_id
        INTO _stateID
        FROM t_requested_run_state_name
        WHERE state_name = _newStatus;

        CALL public.alter_event_log_entry_user ('public', 11, _requestIDOriginal, _stateID, _callingUser, _message => _alterEnteredByMessage);
    End If;

    ---------------------------------------------------
    -- Make sure that t_active_requested_run_cached_eus_users is up-to-date
    ---------------------------------------------------

    CALL public.update_cached_requested_run_eus_users (
                    _requestIDOriginal,
                    _message    => _message,        -- Output
                    _returnCode => _returnCode);    -- Output

END
$$;


ALTER PROCEDURE public.unconsume_scheduled_run(IN _datasetname text, IN _retainhistory boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE unconsume_scheduled_run(IN _datasetname text, IN _retainhistory boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.unconsume_scheduled_run(IN _datasetname text, IN _retainhistory boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UnconsumeScheduledRun';

