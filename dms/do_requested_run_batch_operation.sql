--
-- Name: do_requested_run_batch_operation(integer, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.do_requested_run_batch_operation(IN _batchid integer, IN _mode text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Lock, unlock, or delete a requested run batch
**
**  Arguments:
**    _batchID      Batch ID
**    _mode         Mode: 'LockBatch', 'UnlockBatch', 'Lock', 'Unlock', 'Delete'
**                  Supported, but unused modes (as of July 2017): 'FreeMembers', 'GrantHiPri', 'DenyHiPri'
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   grk
**  Date:   01/12/2006
**          09/20/2006 jds - Added support for Granting High Priority and Denying High Priority for fields Actual_Bath_Priority and Requested_Batch_Priority
**          08/27/2009 grk - Delete batch fixes requested run references in history table
**          02/26/2010 grk - Merged T_Requested_Run_History with T_Requested_Run
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          07/25/2017 mem - Remove mode BatchOrder since unused
**          08/01/2017 mem - Use THROW if not authorized
**          08/01/2022 mem - Exit the procedure if _batchID is 0
**          02/10/2023 mem - Call update_cached_requested_run_batch_stats
**          03/31/2023 mem - Ported to PostgreSQL
**                         - When deleting a batch, archive it in T_Deleted_Requested_Run_Batch
**          05/31/2023 mem - Use procedure name without schema when calling verify_sp_authorized()
**          06/11/2023 mem - Add missing variable _nameWithSchema
**          09/01/2023 mem - Remove unnecessary cast to citext for string constants
**          09/08/2023 mem - Adjust capitalization of keywords
**          01/20/2024 mem - Remove reference to deprecated column Requested_Instrument_Group when copying data from T_Requested_Run_Batches to T_Deleted_Requested_Run_Batch
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _batchExists boolean := false;
    _locked citext;
    _message2 text;
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

    _batchID := Coalesce(_batchID, 0);

    If _batchID = 0 Then
        RAISE EXCEPTION 'Batch operation tasks are not allowed for Batch 0' USING ERRCODE = 'U5201';
    End If;

    _mode := Trim(Coalesce(_mode, ''));

    ---------------------------------------------------
    -- Is batch in table?
    ---------------------------------------------------

    SELECT locked   -- 'Yes' or 'No'
    INTO _locked
    FROM t_requested_run_batches
    WHERE batch_id = _batchID;

    If FOUND Then
        _batchExists := true;
    End If;

    ---------------------------------------------------
    -- Lock run order
    ---------------------------------------------------

    If _mode::citext In ('LockBatch', 'Lock') Then
        If _batchExists Then
            UPDATE t_requested_run_batches
            SET locked = 'Yes'
            WHERE batch_id = _batchID;

        End If;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Unlock run order
    ---------------------------------------------------

    If _mode::citext In ('UnlockBatch', 'Unlock') Then
        If _batchExists Then
            UPDATE t_requested_run_batches
            SET locked = 'No'
            WHERE batch_id = _batchID;
        End If;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Remove current member requests from batch
    ---------------------------------------------------

    If _mode::citext In ('FreeMembers', 'Delete') Then
        If _locked = 'Yes' Then
            _message := 'Cannot remove member requests of locked batch';
            RAISE WARNING '%', _message;

            _returnCode := 'U5201';
            RETURN;
        Else
            UPDATE t_requested_run
            SET batch_id = 0
            WHERE batch_id = _batchID;

            ---------------------------------------------------
            -- Update stats in t_cached_requested_run_batch_stats
            ---------------------------------------------------

            CALL public.update_cached_requested_run_batch_stats (
                            _batchID,
                            _message    => _message2,       -- Output
                            _returnCode => _returnCode);    -- Output

            If _mode::citext = 'FreeMembers' Then
                RETURN;
            End If;
        End If;
    End If;

    ---------------------------------------------------
    -- Delete batch
    ---------------------------------------------------

    If _mode::citext = 'Delete' Then
        If _locked = 'yes' Then
            _message := 'Cannot delete locked batch';
            RAISE WARNING '%', _message;

            _returnCode := 'U5202';
            RETURN;
        Else
            INSERT INTO T_Deleted_Requested_Run_Batch (Batch_ID, Batch, Description, Owner_User_ID, Created, Locked,
                                                       Last_Ordered, Requested_Batch_Priority, Actual_Batch_Priority,
                                                       Requested_Completion_Date, Justification_for_High_Priority, Comment,
                                                       Batch_Group_ID, Batch_Group_Order)
            SELECT Batch_ID, Batch, Description, Owner_User_ID, Created, Locked,
                   Last_Ordered, Requested_Batch_Priority, Actual_Batch_Priority,
                   Requested_Completion_Date, Justification_for_High_Priority, Comment,
                   Batch_Group_ID, Batch_Group_Order
            FROM T_Requested_Run_Batches
            WHERE Batch_ID = _batchID;

            DELETE FROM t_requested_run_batches
            WHERE batch_id = _batchID;

            RETURN;
        End If;
    End If;

    ---------------------------------------------------
    -- Grant High Priority
    ---------------------------------------------------

    If _mode::citext = 'GrantHiPri' Then
        UPDATE t_requested_run_batches
        SET actual_batch_priority = 'High'
        WHERE batch_id = _batchID;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Deny High Priority
    ---------------------------------------------------

    If _mode::citext = 'DenyHiPri' Then
        UPDATE t_requested_run_batches
        SET actual_batch_priority = 'Normal',
            requested_batch_priority = 'Normal'
        WHERE batch_id = _batchID;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Check for invalid mode
    ---------------------------------------------------

    If _mode = '' Then
        RETURN;
    End If;

    ---------------------------------------------------
    -- Mode was unrecognized
    ---------------------------------------------------

    _message := format('Mode "%s" was unrecognized', _mode);
    RAISE WARNING '%', _message;

    _returnCode := 'U5203';

END
$$;


ALTER PROCEDURE public.do_requested_run_batch_operation(IN _batchid integer, IN _mode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE do_requested_run_batch_operation(IN _batchid integer, IN _mode text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.do_requested_run_batch_operation(IN _batchid integer, IN _mode text, INOUT _message text, INOUT _returncode text) IS 'DoRequestedRunBatchOperation';

