--
-- Name: undelete_requested_run_batch(integer, boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.undelete_requested_run_batch(IN _batchid integer, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Restore a deleted requested run
**
**  Arguments:
**    _batchID          Requested run batch ID to undelete
**    _infoOnly         When true, preview the restore
**    _message          Status message
**    _returnCode       Return code
**    _callinguser      Username of the calling user
**
**  Auth:   mem
**  Date:   03/31/2023 mem - Initial version
**          05/31/2023 mem - Combine string literals
**                         - Use procedure name without schema when calling verify_sp_authorized()
**          06/11/2023 mem - Add missing variable _nameWithSchema
**          01/19/2024 mem - Remove reference to deprecated column Requested_Instrument_Group when copying data from t_deleted_requested_run_batch to t_requested_run_batches
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _entryID int;
    _batchGroupID int;
    _deletedBatchGroupEntryID int := 0;
    _message2 text;
BEGIN
    _message := '';
    _returnCode := '';

    _infoOnly := Coalesce(_infoOnly, false);

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
    -- Validate the requested run ID
    ---------------------------------------------------

    If Coalesce(_batchID, 0) = 0 Then
        _message := '_batchID is 0; nothing to do';
        RAISE INFO '%', _message;
        RETURN;
    End If;

    -- Verify that the deleted requested run exists, and lookup the batch ID and EUS person ID

    SELECT Entry_ID,
           Batch_Group_ID
    INTO _entryID, _batchGroupID
    FROM T_Deleted_Requested_Run_Batch
    WHERE Batch_ID = _batchID
    ORDER BY Entry_Id DESC
    LIMIT 1;

    If Not FOUND Then
        _message := format('Requested Run Batch ID %s not found in T_Deleted_Requested_Run_Batch; unable to restore', _batchID);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make sure the requested run batch does not already exist
    ---------------------------------------------------

    If Exists (SELECT batch_id FROM T_Requested_Run_Batches WHERE batch_id = _batchID) Then
        _message := format('Requested Run Batch ID %s already exists in T_Requested_Run_Batches; unable to undelete', _batchID);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _infoOnly Then
        _message := format('Would restore requested run batch ID %s by copying Entry_ID %s from T_Deleted_Requested_Run_Batch to T_Requested_Run_Batches', _batchID, _entryID);
        RAISE INFO '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- See if the deleted requested run batch references a deleted batch group
    ---------------------------------------------------

    If Coalesce(_batchGroupID, 0) > 0 And Not Exists (SELECT Batch_Group_ID FROM T_Requested_Run_Batch_Group WHERE Batch_Group_ID = _batchGroupID) Then

        -- Need to undelete the batch group
        SELECT Entry_ID
        INTO _deletedBatchGroupEntryID
        FROM T_Deleted_Requested_Run_Batch_Group
        WHERE Batch_Group_ID = _batchGroupID
        ORDER BY Entry_ID DESC
        LIMIT 1;

        If Not FOUND Then
            _message := format('Requested run batch %s refers to batch group %s, which does not exist and cannot be restored from T_Deleted_Requested_Run_Batch_Group; see entry %s in T_Deleted_Requested_Run_Batch',
                               _batchID, _batchGroupID, _entryID);

            RAISE WARNING '%', _message;
            RETURN;
        End If;
    End If;

    BEGIN
        If _deletedBatchGroupEntryID > 0 Then

            ---------------------------------------------------
            -- Add the deleted requested run batch group to T_Requested_Run_Batch_Group
            ---------------------------------------------------

            INSERT INTO T_Requested_Run_Batch_Group (Batch_Group_ID, Batch_Group, Description, Owner_User_ID, Created)
            OVERRIDING SYSTEM VALUE
            SELECT Batch_Group_ID, Batch_Group, Description, Owner_User_ID, Created
            FROM T_Deleted_Requested_Run_Batch_Group
            WHERE Entry_ID = _deletedBatchGroupEntryID;

        End If;

        ---------------------------------------------------
        -- Add the deleted requested run batch to T_Requested_Run_Batches
        ---------------------------------------------------

        INSERT INTO T_Requested_Run_Batches (
            Batch_ID, Batch, Description, Owner_User_ID, Created, Locked,
            Last_Ordered, Requested_Batch_Priority, Actual_Batch_Priority,
            Requested_Completion_Date, Justification_for_High_Priority, Comment,
            -- Deprecated in January 2024
            -- Requested_Instrument_Group,
            Batch_Group_ID, Batch_Group_Order
        )
        OVERRIDING SYSTEM VALUE
        SELECT Batch_ID, Batch, Description, Owner_User_ID, Created, Locked,
               Last_Ordered, Requested_Batch_Priority, Actual_Batch_Priority,
               Requested_Completion_Date, Justification_for_High_Priority, Comment,
               -- Requested_Instrument_Group,
               Batch_Group_ID, Batch_Group_Order
        FROM T_Deleted_Requested_Run_Batch
        WHERE Entry_ID = _entryID;

        COMMIT;
    END;

    _message := format('Restored requested run batch ID %s', _batchID);
    RAISE INFO '%', _message;

    ---------------------------------------------------
    -- Update stats in T_Cached_Requested_Run_Batch_Stats
    ---------------------------------------------------

    CALL public.update_cached_requested_run_batch_stats (
            _batchID,
            _fullRefresh => false,
            _message     => _message2,      -- Output
            _returncode  => _returncode);   -- Output

    If _returnCode <> '' Then
        _message := _message2;
    End If;

END
$$;


ALTER PROCEDURE public.undelete_requested_run_batch(IN _batchid integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

