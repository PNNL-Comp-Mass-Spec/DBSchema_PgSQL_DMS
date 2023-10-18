--
-- Name: copy_requested_run(integer, integer, text, text, text, text, text, text, text, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.copy_requested_run(IN _requestid integer, IN _datasetid integer, IN _status text, IN _comment text, IN _requestnameappendtext text DEFAULT ''::text, IN _requestnameoverride text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Make a copy of a given requested run and associate it with the given dataset
**      If _datasetID is 0 or null, the new requested run will have a null dataset ID
**
**  Arguments:
**    _requestID                Requested run ID to copy
**    _datasetID                Dataset ID (use 0 or null if there is not a dataset to associate with the new requested run)
**    _status                   State to use for the new requested run: 'Active', 'Completed', or 'Inactive'
**    _comment                  Requested run comment
**    _requestNameAppendText    Text appended to the name of the newly created request; append nothing if null or ''
**    _requestNameOverride      New request name to use; if blank, will be based on the existing request name, but will append _requestNameAppendText
**    _message                  Output: status message
**    _returnCode               Output: Return code
**    _callingUser              Username of the calling user
**    _infoOnly                 When true, preview the requested run that would be created
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
**          09/13/2023 mem - If there is an existing requested run with a conflicting name, use @requestNameOverride if defined
**                         - Include an underscore before appending @iteration when generating a unique name for the new requested run
**                         - Ported to PostgreSQL
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**
*****************************************************/
DECLARE
    _stateID int;
    _newRequestID int;
    _oldRequestName text;
    _newRequestName citext;
    _stateNameList text := NULL;
    _iteration int;
    _callingUserUnconsume text;
    _batchID int;
    _msg text;
    _alterEnteredByMessage text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _requestID             := Coalesce(_requestID, 0);
    _datasetID             := Coalesce(_datasetID, 0);
    _status                := Trim(Coalesce(_status, ''));
    _comment               := Trim(Coalesce(_comment, ''));
    _requestNameAppendText := Trim(Coalesce(_requestNameAppendText, ''));
    _requestNameOverride   := Trim(Coalesce(_requestNameOverride, ''));
    _callingUser           := Trim(Coalesce(_callingUser, ''));
    _infoOnly              := Coalesce(_infoOnly, false);

    If _requestID = 0 Then
        _message := 'Source request ID is 0; nothing to do';
        _returnCode := 'U5251';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make sure the source request exists
    ---------------------------------------------------

    SELECT request_name
    INTO _oldRequestName
    FROM t_requested_run
    WHERE request_id = _requestID;

    If Not FOUND Then
        _message := format('Source request not found in t_requested_run: %s', _requestID);

        CALL post_log_entry ('Error', _message, 'Copy_Requested_Run');

        _returnCode := 'U5252';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Validate _status
    ---------------------------------------------------

    SELECT state_id
    INTO _stateID
    FROM t_requested_run_state_name
    WHERE state_name = _status::citext;

    If Not FOUND Then
        SELECT string_agg(state_name, ', ' ORDER BY state_id)
        INTO _stateNameList
        FROM t_requested_run_state_name;

        _message := format('Invalid requested run state: %s; valid states are %s', _status, _stateNameList);

        CALL post_log_entry ('Error', _message, 'Copy_Requested_Run');

        _returnCode := 'U5253';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Determine the name for the new request
    -- Note that _requestNameAppendText may be blank
    ---------------------------------------------------

    If _requestNameOverride = '' Then
        _newRequestName := format('%s%s', _oldRequestName, _requestNameAppendText);
    Else
        _newRequestName := _requestNameOverride;
    End If;

    _iteration := 1;

    WHILE true
    LOOP
        If Not Exists (SELECT request_name FROM t_requested_run WHERE request_name = _newRequestName) Then
            -- Break out of the while loop
            EXIT;
        End If;

        _iteration := _iteration + 1;

        If _requestNameOverride = '' Then
            _newRequestName := format('%s%s_%s', _oldRequestName, _requestNameAppendText, _iteration);
        Else
            _newRequestName := format('%s_%s', _requestNameOverride, _iteration);
        End If;

    END LOOP;

    If _infoOnly Then

        RAISE INFO '';

        _formatSpecifier := '%-17s %-60s %-60s %-50s %-18s %-20s %-25s %-15s %-8s %-10s %-20s %-20s %-25s %-12s %-8s %-15s %-6s %-9s %-15s %-17s %-7s %-14s %-20s %-30s %-10s %-10s %-10s';

        _infoHead := format(_formatSpecifier,
                            'Source_Request_ID',
                            'Source_Request_Name',
                            'New_Request_Name',
                            'Comment',
                            'Requester_Username',
                            'Created',
                            'Instrument_Group',
                            'Request_Type_Id',
                            'Priority',
                            'Exp_Id',
                            'Request_Run_Start',
                            'Request_Run_Finish',
                            'Request_Internal_Standard',
                            'Work_Package',
                            'Batch_ID',
                            'Blocking_Factor',
                            'Block',
                            'Run_Order',
                            'EUS_Proposal_ID',
                            'EUS_Usage_Type_ID',
                            'Cart_ID',
                            'Cart_Config_ID',
                            'Cart_Column',
                            'Separation_Group',
                            'State_Name',
                            'Origin',
                            'Dataset_ID'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '-----------------',
                                     '------------------------------------------------------------',
                                     '------------------------------------------------------------',
                                     '--------------------------------------------------',
                                     '------------------',
                                     '--------------------',
                                     '-------------------------',
                                     '---------------',
                                     '--------',
                                     '----------',
                                     '--------------------',
                                     '--------------------',
                                     '-------------------------',
                                     '------------',
                                     '--------',
                                     '---------------',
                                     '------',
                                     '---------',
                                     '---------------',
                                     '-----------------',
                                     '-------',
                                     '--------------',
                                     '--------------------',
                                     '------------------------------',
                                     '----------',
                                     '----------',
                                     '----------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT
                request_id As Source_Request_ID,
                request_name As Source_Request_Name,
                _newRequestName As New_Request_Name,
                _comment As Comment,
                requester_username,
                public.timestamp_text(created) As created,      -- Pass along the original request's 'created' date into the new entry
                instrument_group,
                request_type_id,
                priority,
                exp_id,
                public.timestamp_text(request_run_start) As request_run_start,
                public.timestamp_text(request_run_finish) As request_run_finish,
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
                _status As State_Name,
                'auto' As Origin,
                CASE WHEN _datasetID = 0 THEN NULL ELSE _datasetID END AS Dataset_ID
            FROM t_requested_run
            WHERE request_id = _requestID
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Source_Request_ID,
                                _previewData.Source_Request_Name,
                                _previewData.New_Request_Name,
                                _previewData.Comment,
                                _previewData.Requester_Username,
                                _previewData.Created,
                                _previewData.Instrument_Group,
                                _previewData.Request_Type_Id,
                                _previewData.Priority,
                                _previewData.Exp_Id,
                                _previewData.Request_Run_Start,
                                _previewData.Request_Run_Finish,
                                _previewData.Request_Internal_Standard,
                                _previewData.Work_Package,
                                _previewData.Batch_Id,
                                _previewData.Blocking_Factor,
                                _previewData.Block,
                                _previewData.Run_Order,
                                _previewData.Eus_Proposal_Id,
                                _previewData.Eus_Usage_Type_Id,
                                _previewData.Cart_Id,
                                _previewData.Cart_Config_Id,
                                _previewData.Cart_Column,
                                _previewData.Separation_Group,
                                _previewData.State_Name,
                                _previewData.Origin,
                                _previewData.Dataset_ID
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Copy the requested run
    ---------------------------------------------------

    INSERT INTO t_requested_run( comment,
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
                                 dataset_id )
    SELECT _comment,
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
           CASE WHEN _datasetID = 0 THEN NULL ELSE _datasetID END AS Dataset_ID
    FROM t_requested_run
    WHERE request_id = _requestID
    RETURNING request_id
    INTO _newRequestID;

    If Not FOUND Then
        If Not Exists (SELECT request_id FROM t_requested_run WHERE request_id = _requestID) Then
            _message := format('Problem trying to copy an existing requested run; source request ID not found: %s', _requestID);
        Else
            _message := format('Problem trying to copy an existing requested run; no rows added for request ID %s', _requestID);
        End If;

        CALL post_log_entry ('Error', _message, 'Copy_Requested_Run');

        _returnCode := 'U5254';
        RETURN;
    End If;

    If char_length(_callingUser) > 0 Then
        CALL public.alter_event_log_entry_user ('public', 11, _newRequestID, _stateID, _callingUser, _message => _alterEnteredByMessage);
    End If;

    ------------------------------------------------------------
    -- Copy factors from the source requested run to the new one
    ------------------------------------------------------------

    -- First define the calling user text

    If char_length(_callingUser) > 0 Then
        _callingUserUnconsume := format('(unconsume for %s)', _callingUser);
    Else
        _callingUserUnconsume := '(unconsume)';
    End If;

    -- Now copy the factors

    CALL public.update_requested_run_copy_factors (
                    _requestID,
                    _newRequestID,
                    _message     => _message,                   -- Output
                    _returnCode  => _returnCode,                -- Output
                    _callingUser => _callingUserUnconsume);

    If _returnCode <> '' Then
        _message := format('Problem copying factors from requested run %s to requested run %s; _returnCode = %s', _requestID, _newRequestID, _returnCode);
        CALL post_log_entry ('Error', _message, 'Copy_Requested_Run');
        RETURN;
    End If;

    -- _message may contain the text 'Nothing to copy'
    -- We don't need that text appearing on the web page, so clear _message
    _message := '';

    ---------------------------------------------------
    -- Copy proposal users for new auto request from original request
    ---------------------------------------------------

    INSERT INTO t_requested_run_eus_users (eus_person_id, request_id)
    SELECT eus_person_id, _newRequestID
    FROM t_requested_run_eus_users
    WHERE request_id = _requestID;

    ---------------------------------------------------
    -- Make sure that t_active_requested_run_cached_eus_users is up-to-date
    ---------------------------------------------------

    CALL public.update_cached_requested_run_eus_users (
                    _newRequestID,
                    _message    => _message,        -- Output
                    _returnCode => _returnCode);    -- Output

    ---------------------------------------------------
    -- Update stats in t_cached_requested_run_batch_stats
    ---------------------------------------------------

    SELECT batch_id
    INTO _batchID
    FROM t_requested_run
    WHERE request_id = _requestID;

    If Coalesce(_batchID, 0) > 0 Then
        CALL public.update_cached_requested_run_batch_stats (
                        _batchID,
                        _fullRefresh => false,
                        _message     => _msg,           -- Output
                        _returnCode  => _returnCode);   -- Output

        If _returnCode <> '' Then
            _message := public.append_to_text(_message, _msg);
        End If;
    End If;
END
$$;


ALTER PROCEDURE public.copy_requested_run(IN _requestid integer, IN _datasetid integer, IN _status text, IN _comment text, IN _requestnameappendtext text, IN _requestnameoverride text, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE copy_requested_run(IN _requestid integer, IN _datasetid integer, IN _status text, IN _comment text, IN _requestnameappendtext text, IN _requestnameoverride text, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _infoonly boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.copy_requested_run(IN _requestid integer, IN _datasetid integer, IN _status text, IN _comment text, IN _requestnameappendtext text, IN _requestnameoverride text, INOUT _message text, INOUT _returncode text, IN _callinguser text, IN _infoonly boolean) IS 'CopyRequestedRun';

