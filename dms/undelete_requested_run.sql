--
-- Name: undelete_requested_run(integer, boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.undelete_requested_run(IN _requestid integer, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Restore a deleted requested run
**
**  Arguments:
**    _requestID    Requested run ID to undelete
**    _infoOnly     Set to true to preview the restore, false to actually undelete
**
**  Auth:   mem
**  Date:   03/30/2023 mem - Initial version
**          03/31/2023 mem - Restore requested run batches and batch groups if the requested run refers to a deleted batch or batch group
**          05/31/2023 mem - Use implicit string concatenation
**                         - Use procedure name without schema when calling verify_sp_authorized()
**          06/11/2023 mem - Add missing variable _nameWithSchema
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _entryID int;
    _batchID int;
    _eusPersonID int;
    _batchGroupID int;
    _deletedBatchEntryID int := 0;
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

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Validate the requested run ID
    ---------------------------------------------------

    If Coalesce(_requestID, 0) = 0 Then
        _message := '_requestID is 0; nothing to do';
        RAISE INFO '%', _message;
        RETURN;
    End If;

    -- Verify that the deleted requested run exists, and lookup the batch ID and EUS person ID
    --
    SELECT Entry_ID,
           Batch_ID,
           EUS_Person_Id
    INTO _entryID, _batchID, _eusPersonID
    FROM T_Deleted_Requested_Run
    WHERE Request_ID = _requestID
    ORDER BY Entry_Id DESC
    LIMIT 1;

    If Not FOUND Then
        _message = format('Requested Run ID %s not found in T_Deleted_Requested_Run; unable to restore', _requestID);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make sure the requested run does not already exist
    ---------------------------------------------------

    If Exists (SELECT request_id FROM T_Requested_Run WHERE request_id = _requestID) Then
        _message = format('Requested Run ID %s already exists in T_Requested_Run; unable to undelete', _requestID);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If Exists (Select target_id From T_Factor Where type = 'Run_Request' And target_id = _requestID) Then
        _message = format('Requested Run ID %s not found in T_Requested_Run, but found in T_Factor; delete from T_Factor then call this procedure again', _requestID);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If Exists (Select Request_ID From T_Requested_Run_EUS_Users Where Request_ID = _requestID) Then
        _message = format('Requested Run ID %s not found in T_Requested_Run, but found in T_Requested_Run_EUS_Users; delete from T_Requested_Run_EUS_Users then call this procedure again', _requestID);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    If _infoOnly Then
        _message = format('Would restore requested run ID %s by copying Entry_ID %s from T_Deleted_Requested_Run to T_Requested_Run', _requestID, _entryID);
        RAISE INFO '%', _message;
        RETURN;
    End If;

    ---------------------------------------------------
    -- See if the deleted requested run references a deleted requested run batch
    ---------------------------------------------------

    If _batchID > 0 And Not Exists (Select Batch_ID From T_Requested_Run_Batches Where Batch_ID = _batchID) Then
        -- Need to undelete the batch
        SELECT Entry_ID,
               Batch_Group_ID
        INTO _deletedBatchEntryID, _batchGroupID
        FROM T_Deleted_Requested_Run_Batch
        WHERE Batch_ID = _batchID
        ORDER BY Entry_ID DESC
        LIMIT 1;

        If Not FOUND Then
            _message := format('Requested run ID %s refers to batch %s, which does not exist, and cannot be restored from T_Deleted_Requested_Run_Batch; see entry %s in T_Deleted_Requested_Run',
                                _requestID, _batchID, _entryID);

            RAISE WARNING '%', _message;
            RETURN;
        End If;

        ---------------------------------------------------
        -- See if the deleted requested run batch references a deleted batch group
        ---------------------------------------------------

        If Coalesce(_batchGroupID, 0) > 0 And Not Exists (Select Batch_Group_ID From T_Requested_Run_Batch_Group Where Batch_Group_ID = _batchGroupID) Then
            -- Need to undelete the batch group
            SELECT Entry_ID
            INTO _deletedBatchGroupEntryID
            FROM T_Deleted_Requested_Run_Batch_Group
            WHERE Batch_Group_ID = _batchGroupID
            ORDER BY Entry_ID DESC
            LIMIT 1;

            If Not FOUND Then
                _message := format('Requested run ID %s refers to batch %s, which refers to batch group %s, '
                                   'but that batch group does not exist and cannot be restored from T_Deleted_Requested_Run_Batch_Group; '
                                   'see entry %s in T_Deleted_Requested_Run '
                                   'and entry %s in T_Deleted_Requested_Run_Batch',
                                   _requestID, _batchID, _batchGroupID, _entryID, _deletedBatchEntryID);

                RAISE WARNING '%', _message;
                RETURN;
            End If;
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

        If _deletedBatchEntryID > 0 Then

            ---------------------------------------------------
            -- Add the deleted requested run batch to T_Requested_Run_Batches
            ---------------------------------------------------

            INSERT INTO T_Requested_Run_Batches (
                    Batch_ID, Batch, Description, Owner_User_ID, Created, Locked,
                    Last_Ordered, Requested_Batch_Priority, Actual_Batch_Priority,
                    Requested_Completion_Date, Justification_for_High_Priority, Comment,
                    Requested_Instrument_Group, Batch_Group_ID, Batch_Group_Order
                )
            OVERRIDING SYSTEM VALUE
            SELECT Batch_ID, Batch, Description, Owner_User_ID, Created, Locked,
                   Last_Ordered, Requested_Batch_Priority, Actual_Batch_Priority,
                   Requested_Completion_Date, Justification_for_High_Priority, Comment,
                   Requested_Instrument_Group, Batch_Group_ID, Batch_Group_Order
            FROM T_Deleted_Requested_Run_Batch
            WHERE Entry_ID = _deletedBatchEntryID;

        End If;

        ---------------------------------------------------
        -- Add the requested run to T_Requested_Run
        ---------------------------------------------------

        INSERT INTO T_Requested_Run (
                Request_Id, Request_Name, Requester_Username, Comment, Created, Instrument_Group,
                Request_Type_Id, Instrument_Setting, Special_Instructions, Wellplate, Well, Priority, Note, Exp_Id,
                Request_Run_Start, Request_Run_Finish, Request_Internal_Standard, Work_Package, Batch_Id,
                Blocking_Factor, Block, Run_Order, EUS_Proposal_Id, EUS_Usage_Type_Id,
                Cart_Id, Cart_Config_Id, Cart_Column, Separation_Group, Mrm_Attachment,
                Dataset_Id, Origin, State_Name, Request_Name_Code, Vialing_Conc, Vialing_Vol, Location_Id,
                Queue_State, Queue_Instrument_Id, Queue_Date, Entered, Updated, Updated_By
            )
        OVERRIDING SYSTEM VALUE
        SELECT Request_Id, Request_Name, Requester_Username, Comment, Created, Instrument_Group,
               Request_Type_Id, Instrument_Setting, Special_Instructions, Wellplate, Well, Priority, Note, Exp_Id,
               Request_Run_Start, Request_Run_Finish, Request_Internal_Standard, Work_Package, Batch_Id,
               Blocking_Factor, Block, Run_Order, EUS_Proposal_Id, EUS_Usage_Type_Id,
               Cart_Id, Cart_Config_Id, Cart_Column, Separation_Group, Mrm_Attachment,
               Dataset_Id, Origin, State_Name, Request_Name_Code, Vialing_Conc, Vialing_Vol, Location_Id,
               Queue_State, Queue_Instrument_Id, Queue_Date, Entered, Updated, Updated_By
        FROM T_Deleted_Requested_Run
        WHERE Entry_ID = _entryID;

        If Coalesce(_eusPersonID, 0) > 0 Then
            Insert Into T_Requested_Run_EUS_Users (Request_id, EUS_Person_ID)
            Values (_requestID, _eusPersonID);
        End If;

        ---------------------------------------------------
        -- Add any factors to T_Factor
        ---------------------------------------------------

        INSERT INTO T_Factor (Factor_ID, Type, Target_ID, Name, Value, Last_Updated)
        OVERRIDING SYSTEM VALUE
        SELECT Factor_ID, Type, Target_ID, Name, Value, Last_Updated
        FROM T_Deleted_Factor
        WHERE Type = 'Run_Request' AND
              Target_ID = _requestID And
              Deleted_Requested_Run_Entry_ID = _entryID;

        COMMIT;
    END;

    _message := format('Restored requested run ID %s', _requestID);
    RAISE INFO '%', _message;

    ---------------------------------------------------
    -- Update stats in T_Cached_Requested_Run_Batch_Stats
    ---------------------------------------------------

    If _batchID > 0 Then

        CALL public.update_cached_requested_run_batch_stats (
                        _batchID,
                        _fullrefresh => false,
                        _message     => _message2,      -- Output
                        _returncode  => _returncode);   -- Output

        If _returnCode <> '' Then
            _message := _message2;
        End If;

    End If;

END
$$;


ALTER PROCEDURE public.undelete_requested_run(IN _requestid integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

