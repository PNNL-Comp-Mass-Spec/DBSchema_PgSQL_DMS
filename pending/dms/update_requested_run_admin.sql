--
CREATE OR REPLACE PROCEDURE public.update_requested_run_admin
(
    _requestList text,
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
**      Requested run admin operations
**      Will only update Active and Inactive requests
**
**      Example contents of _requestList:
**        <r i="545499" /><r i="545498" /><r i="545497" /><r i="545496" /><r i="545495" />
**
**      Description of the modes
**        'Active'    sets the requests to the Active state
**        'Inactive'  sets the requests to the Inactive state
**        'Delete'    deletes the requests
**        'UnassignInstrument' will change the Queue_State to 1 for requests that have a Queue_State of 2 ("Assigned"); skips any with a Queue_State of 3 ("Analyzed")
**
**  Arguments:
**    _requestList   XML describing list of Requested Run IDs
**    _mode          'Active', 'Inactive', 'Delete', or 'UnassignInstrument'
**
**  Auth:   grk
**  Date:   03/09/2010
**          09/02/2011 mem - Now calling Post_Usage_Log_Entry
**          12/12/2011 mem - Now calling alter_event_log_entry_user_multi_id
**          11/16/2016 mem - Call update_cached_requested_run_eus_users for updated Requested runs
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          07/01/2019 mem - Add additional debug logging
**          10/20/2020 mem - Add mode 'UnassignInstrument'
**          10/21/2020 mem - Set Queue_Instrument_ID to null when unassigning
**          10/23/2020 mem - Allow updating 'fraction' based requests
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          05/23/2023 mem - Allow deleting requests of type 'auto' or 'fraction'
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _matchCount int := 0;
    _updateCount int := 0;
    _xml AS xml;
    _usageMessage text := '';
    _stateID int := 0;
    _logMessage text;
    _debugEnabled boolean := false;
    _argLength Int;
    _requestID int := -100000;
    _alterEnteredByMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
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

    -- Set to true to log the contents of _requestList

    If _debugEnabled Then
        _logMessage := _requestList;
        CALL post_log_entry ('Debug', _logMessage, 'Update_Requested_Run_Admin');

        _argLength := char_length(_requestList);

        _logMessage := format('%s characters in _requestList', _argLength);
        CALL post_log_entry ('Debug', _logMessage, 'Update_Requested_Run_Admin');
    End If;

    _mode := Trim(Lower(Coalesce(_mode, '')));

    -----------------------------------------------------------
    -- Temp table to hold list of requests
    -----------------------------------------------------------

    CREATE TEMP TABLE Tmp_Requests (
        Item text,              -- Request ID, as text
        Status citext NULL,
        Origin citext NULL,
        request_id int NULL
    );

    -----------------------------------------------------------
    -- Convert _requestList to rooted XML
    -----------------------------------------------------------

    _xml := public.try_cast('<root>' || _requestList || '</root>', null::xml);

    If _xml Is Null Then
        _message := 'Request list is not valid XML';
        RAISE EXCEPTION '%', _message;
    End If;

    -----------------------------------------------------------
    -- Populate temp table with request IDs (storing as text for now)
    -----------------------------------------------------------

    INSERT INTO Tmp_Requests ( Item )
    SELECT unnest(xpath('//root/r/@i', _xml));
    --
    GET DIAGNOSTICS _matchCount = ROW_COUNT;

    If _debugEnabled Then
        _logMessage := format('%s %s inserted into Tmp_Requests', _matchCount, public.check_plural(_matchCount, 'row', 'rows'));
        CALL post_log_entry ('Debug', _logMessage, 'Update_Requested_Run_Admin');
    End If;

    -----------------------------------------------------------
    -- Validate the request list
    -----------------------------------------------------------
    -- Convert request IDs from text to integer
    --
    UPDATE Tmp_Requests
    SET request_id = public.try_cast(Item, null::int);

    If Exists (SELECT Item FROM Tmp_Requests WHERE request_id IS NULL) Then
        _message := 'Found non-integer request IDs';
        _returnCode := 'U5112';

        DROP TABLE Tmp_Requests;
        RETURN;
    End If;

    UPDATE Tmp_Requests
    SET Status = t_requested_run.state_name,
        Origin = t_requested_run.origin
    FROM t_requested_run
    WHERE Tmp_Requests.request_id = t_requested_run.request_id;

    If Exists (SELECT Item FROM Tmp_Requests WHERE Status IS NULL) Then
        _message := 'There were invalid request IDs';
        _returnCode := 'U5113';

        DROP TABLE Tmp_Requests;
        RETURN;
    End If;

    If Exists (SELECT Item FROM Tmp_Requests WHERE Not Status::citext IN ('Active', 'Inactive')) Then
        _message := 'Cannot change requests that are in status other than "Active" or "Inactive"';
        _returnCode := 'U5114';

        DROP TABLE Tmp_Requests;
        RETURN;
    End If;

    If Exists (SELECT Item FROM Tmp_Requests WHERE Not Origin::citext In ('user', 'fraction') And _mode::citext <> 'Delete') Then
        _message := 'Cannot change requests that were not entered by user';
        _returnCode := 'U5115';

        DROP TABLE Tmp_Requests;
        RETURN;
    End If;

    -----------------------------------------------------------
    -- Populate a temporary table with the list of Requested Run IDs to be updated or deleted
    -----------------------------------------------------------

    CREATE TEMP TABLE Tmp_ID_Update_List (
        TargetID int NOT NULL
    );

    CREATE UNIQUE INDEX IX_Tmp_ID_Update_List ON Tmp_ID_Update_List (TargetID);

    INSERT INTO Tmp_ID_Update_List (TargetID)
    SELECT DISTINCT request_id
    FROM Tmp_Requests
    WHERE Not request_id Is Null
    ORDER BY request_id;

    -----------------------------------------------------------
    -- Update status
    -----------------------------------------------------------

    If _mode = 'active' Or _mode = 'inactive' Then
        UPDATE t_requested_run
        SET state_name = _mode
        WHERE request_id IN ( SELECT request_id FROM Tmp_Requests ) AND
              state_name <> 'Completed'
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        _usageMessage := format('Updated %s %s', _updateCount, public.check_plural(_updateCount, 'request', 'requests'));

        If char_length(_callingUser) > 0 Then
            -- _callingUser is defined; call public.alter_event_log_entry_user_multi_id
            -- to alter the entered_by field in t_event_log
            -- This procedure uses Tmp_ID_Update_List
            --
            SELECT state_id
            INTO _stateID
            FROM t_requested_run_state_name
            WHERE state_name = _mode;

            CALL public.alter_event_log_entry_user_multi_id ('public', 11, _stateID, _callingUser, _message => _alterEnteredByMessage);
        End If;

        -- Call update_cached_requested_run_eus_users for each entry in Tmp_Requests
        --
        FOR _requestID IN
            SELECT request_id
            FROM Tmp_Requests
            ORDER BY request_id
        LOOP
            CALL public.update_cached_requested_run_eus_users (
                            _requestID,
                            _message => _message,           -- Output
                            _returnCode => _returnCode);    -- Output
        END LOOP;

    End If;

    -----------------------------------------------------------
    -- Delete requests
    -----------------------------------------------------------

    If _mode = 'delete' Then
        DELETE FROM t_requested_run
        WHERE request_id IN ( SELECT request_id FROM Tmp_Requests ) AND
              state_name <> 'Completed';
        --
        GET DIAGNOSTICS _matchCount = ROW_COUNT;

        _usageMessage := format('Deleted %s %s', _matchCount, public.check_plural(_matchCount, 'request', 'requests'));

        If char_length(_callingUser) > 0 Then
            -- _callingUser is defined; call public.alter_event_log_entry_user_multi_id
            -- to alter the entered_by field in t_event_log
            -- This procedure uses Tmp_ID_Update_List
            --
            _stateID := 0;

            CALL public.alter_event_log_entry_user_multi_id ('public', 11, _stateID, _callingUser, _message => _alterEnteredByMessage);
        End If;

        -- Remove any cached EUS user lists
        DELETE FROM t_active_requested_run_cached_eus_users
        WHERE EXISTS ( SELECT request_id
                       FROM Tmp_Requests
                       WHERE request_id = t_active_requested_run_cached_eus_users.request_id);

    End If;

    -----------------------------------------------------------
    -- Unassign requests
    -----------------------------------------------------------

    If _mode::citext = 'UnassignInstrument' Then

        UPDATE t_requested_run
        SET queue_state = 1,
            queue_instrument_id = Null
        WHERE request_id IN ( SELECT request_id FROM Tmp_Requests ) AND
              state_name <> 'Completed' AND
              (queue_state = 2 OR Not queue_instrument_id Is NULL);
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        _usageMessage := format('Unassigned %s %s from the queued instrument', _updateCount, public.check_plural(_updateCount, 'request', 'requests'));

    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    CALL post_usage_log_entry ('update_requested_run_admin', _usageMessage);

    DROP TABLE Tmp_Requests;
    DROP TABLE Tmp_ID_Update_List;
END
$$;

COMMENT ON PROCEDURE public.update_requested_run_admin IS 'UpdateRequestedRunAdmin';

