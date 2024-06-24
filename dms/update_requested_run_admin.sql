--
-- Name: update_requested_run_admin(text, text, boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_requested_run_admin(IN _requestlist text, IN _mode text, IN _debugmode boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Requested run admin operations; only updates Active and Inactive requested runs
**
**      Example contents of _requestList:
**        <r i="545499" /><r i="545498" /><r i="545497" /><r i="545496" /><r i="545495" />
**
**  Arguments:
**    _requestList      XML describing requested run IDs to update
**    _mode             Mode: 'Active', 'Inactive', 'Delete', or 'UnassignInstrument'
**    _debugMode        When true, log the contents of _requestList in t_log_entries, and also log the number of requested runs updated
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Available modes:
**      'Active'                Sets the requested runs to the Active state
**      'Inactive'              Sets the requested runs to the Inactive state
**      'Delete'                Deletes the requested runs
**      'UnassignInstrument'    Changes the queue state to 1 for requested runs that have a queue state of 2 ("Assigned"); skips any with a queue state of 3 ("Analyzed")
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
**          10/23/2020 mem - Allow updating 'fraction' based requested runs
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          05/23/2023 mem - Allow deleting requested runs of type 'auto' or 'fraction'
**          03/07/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          05/21/2024 mem - Call update_cached_requested_run_batch_stats after deleting requested runs
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _matchCount int := 0;
    _updateCount int := 0;
    _xml xml;
    _usageMessage text := '';
    _stateID int := 0;
    _logMessage text;
    _argLength int;
    _requestID int;
    _batchID int;
    _msg text;
    _targetType int;
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

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _requestList := Trim(Coalesce(_requestList, ''));
    _mode        := Trim(Lower(Coalesce(_mode, '')));
    _debugMode   := Coalesce(_debugMode, false);
    _callingUser := Trim(Coalesce(_callingUser, ''));

    If _debugMode Then
        _logMessage := _requestList;
        CALL post_log_entry ('Debug', _logMessage, 'Update_Requested_Run_Admin');

        _argLength := char_length(_requestList);

        _logMessage := format('%s characters in _requestList', _argLength);
        CALL post_log_entry ('Debug', _logMessage, 'Update_Requested_Run_Admin');
    End If;

    -----------------------------------------------------------
    -- Temp table to hold requested run IDs
    -----------------------------------------------------------

    CREATE TEMP TABLE Tmp_Requests (
        Item text,              -- Requested run ID, as text
        Status citext NULL,
        Origin citext NULL,
        Request_ID int NULL
    );

    -----------------------------------------------------------
    -- Convert _requestList to rooted XML
    -----------------------------------------------------------

    _xml := public.try_cast('<root>' || _requestList || '</root>', null::xml);

    If _xml Is Null Then
        _message := 'Requested run ID list is not valid XML';
        RAISE EXCEPTION '%', _message;
    End If;

    -----------------------------------------------------------
    -- Populate temp table with requested run IDs (storing as text for now)
    -----------------------------------------------------------

    INSERT INTO Tmp_Requests (Item)
    SELECT unnest(xpath('//root/r/@i', _xml));
    --
    GET DIAGNOSTICS _matchCount = ROW_COUNT;

    If _debugMode Then
        _logMessage := format('Parsed %s requested run %s from the XML', _matchCount, public.check_plural(_matchCount, 'ID', 'IDs'));
        CALL post_log_entry ('Debug', _logMessage, 'Update_Requested_Run_Admin');
    End If;

    -----------------------------------------------------------
    -- Validate the requested run ID list
    -----------------------------------------------------------

    -- Convert requested run IDs from text to integer

    UPDATE Tmp_Requests
    SET Request_ID = public.try_cast(Item, null::int);

    If Exists (SELECT Item FROM Tmp_Requests WHERE Request_ID IS NULL) Then
        _message := 'Found non-integer requested run IDs';
        RAISE WARNING '%', _message;

        _returnCode := 'U5112';
        DROP TABLE Tmp_Requests;

        RETURN;
    End If;

    UPDATE Tmp_Requests
    SET Status = t_requested_run.state_name,
        Origin = t_requested_run.origin
    FROM t_requested_run
    WHERE Tmp_Requests.Request_ID = t_requested_run.request_id;

    If Exists (SELECT Item FROM Tmp_Requests WHERE Status IS NULL) Then
        _message := 'There were invalid requested run IDs';
        RAISE WARNING '%', _message;

        _returnCode := 'U5113';
        DROP TABLE Tmp_Requests;

        RETURN;
    End If;

    If Exists (SELECT Item FROM Tmp_Requests WHERE NOT Status::citext IN ('Active', 'Inactive')) Then
        _message := 'Cannot change requested runs that are in status other than "Active" or "Inactive"';
        RAISE WARNING '%', _message;

        _returnCode := 'U5114';
        DROP TABLE Tmp_Requests;

        RETURN;
    End If;

    If Exists (SELECT Item FROM Tmp_Requests WHERE NOT Origin::citext IN ('user', 'fraction') AND _mode <> 'delete') Then
        _message := 'Cannot change requested runs that were not entered by user';
        RAISE WARNING '%', _message;

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
    SELECT DISTINCT Request_ID
    FROM Tmp_Requests
    WHERE NOT Request_ID IS NULL
    ORDER BY Request_ID;

    If _mode IN ('active', 'inactive') Then
        -----------------------------------------------------------
        -- Update status
        -----------------------------------------------------------

        UPDATE t_requested_run
        SET state_name = CASE WHEN _mode = 'active'   THEN 'Active'
                              WHEN _mode = 'inactive' THEN 'Inactive'
                              ELSE state_name
                         END
        WHERE request_id IN (SELECT Request_ID FROM Tmp_Requests) AND
              state_name <> 'Completed';
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        _usageMessage := format('Updated %s requested %s', _updateCount, public.check_plural(_updateCount, 'run', 'runs'));

        If _callingUser <> '' Then
            -- _callingUser is defined; call public.alter_event_log_entry_user_multi_id to alter the entered_by field in t_event_log
            -- That procedure uses Tmp_ID_Update_List

            SELECT state_id
            INTO _stateID
            FROM t_requested_run_state_name
            WHERE state_name = _mode::citext;

            _targetType := 11;
            CALL public.alter_event_log_entry_user_multi_id ('public', _targetType, _stateID, _callingUser, _message => _alterEnteredByMessage);
        End If;

        -----------------------------------------------------------
        -- Call update_cached_requested_run_eus_users for each entry in Tmp_Requests
        -----------------------------------------------------------

        FOR _requestID IN
            SELECT request_id
            FROM Tmp_Requests
            ORDER BY request_id
        LOOP
            CALL public.update_cached_requested_run_eus_users (
                            _requestID  => _requestID,
                            _message    => _message,        -- Output
                            _returnCode => _returnCode);    -- Output
        END LOOP;

    End If;

    If _mode = 'delete' Then
        -----------------------------------------------------------
        -- Delete requested runs
        -----------------------------------------------------------

        CREATE TEMPORARY TABLE Tmp_Batch_IDs (
            Batch_ID int NOT NULL
        );

        INSERT INTO Tmp_Batch_IDs (Batch_ID)
        SELECT DISTINCT batch_id
        FROM t_requested_run
        WHERE request_id IN (SELECT Request_ID FROM Tmp_Requests) AND
              state_name <> 'Completed';

        DELETE FROM t_requested_run
        WHERE request_id IN (SELECT request_id FROM Tmp_Requests) AND
              state_name <> 'Completed';
        --
        GET DIAGNOSTICS _matchCount = ROW_COUNT;

        _usageMessage := format('Deleted %s requested %s', _matchCount, public.check_plural(_matchCount, 'run', 'runs'));

        If _callingUser <> '' Then
            -- _callingUser is defined; call public.alter_event_log_entry_user_multi_id to alter the entered_by field in t_event_log
            -- That procedure uses Tmp_ID_Update_List

            _targetType := 11;
            _stateID := 0;

            CALL public.alter_event_log_entry_user_multi_id ('public', _targetType, _stateID, _callingUser, _message => _alterEnteredByMessage);
        End If;

        -- Remove any cached EUS user lists
        DELETE FROM t_active_requested_run_cached_eus_users
        WHERE EXISTS (SELECT Request_ID
                      FROM Tmp_Requests
                      WHERE Request_ID = t_active_requested_run_cached_eus_users.request_id);

        -----------------------------------------------------------
        -- Update batches associated with the deleted requested runs
        -- (skipping Batch_ID 0)
        -----------------------------------------------------------

        FOR _batchID IN
            SELECT Batch_ID
            FROM Tmp_Batch_IDs
            ORDER BY Batch_ID
        LOOP

            If _batchID = 0 Then
                RAISE INFO 'Skipping call to update_cached_requested_run_batch_stats for batch 0';
                CONTINUE;
            End If;

            RAISE INFO 'Calling update_cached_requested_run_batch_stats for batch %', _batchID;

            CALL public.update_cached_requested_run_batch_stats (
                            _batchID    => _batchID,
                            _message    => _msg,            -- Output
                            _returnCode => _returnCode);    -- Output

            If _returnCode <> '' Then
                _message := public.append_to_text(_message, _msg);
            End If;
        END LOOP;

        DROP TABLE Tmp_Batch_IDs;
    End If;

    If _mode = Lower('UnassignInstrument') Then
        -----------------------------------------------------------
        -- Unassign requested runs
        -----------------------------------------------------------

        UPDATE t_requested_run
        SET queue_state = 1,
            queue_instrument_id = NULL
        WHERE request_id IN (SELECT Request_ID FROM Tmp_Requests) AND
              state_name <> 'Completed' AND
              (queue_state = 2 OR NOT queue_instrument_id IS NULL);
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        _usageMessage := format('Unassigned %s requested %s from the queued instrument', _updateCount, public.check_plural(_updateCount, 'run', 'runs'));

    End If;

    If _usageMessage = '' Then
        _usageMessage := format('Unrecognized mode: %s', _mode);
        RAISE WARNING '%', _usageMessage;
    Else
        RAISE INFO '%', _usageMessage;
    End If;

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    CALL post_usage_log_entry ('update_requested_run_admin', _usageMessage);

    DROP TABLE Tmp_Requests;
    DROP TABLE Tmp_ID_Update_List;
END
$$;


ALTER PROCEDURE public.update_requested_run_admin(IN _requestlist text, IN _mode text, IN _debugmode boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_requested_run_admin(IN _requestlist text, IN _mode text, IN _debugmode boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_requested_run_admin(IN _requestlist text, IN _mode text, IN _debugmode boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateRequestedRunAdmin';

