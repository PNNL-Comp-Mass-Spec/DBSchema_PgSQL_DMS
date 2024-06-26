--
-- Name: do_requested_run_batch_group_operation(integer, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.do_requested_run_batch_group_operation(IN _batchgroupid integer, IN _mode text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Delete a requested run batch group
**
**  Arguments:
**    _batchGroupID     Batch group ID
**    _mode             Mode: 'Delete'
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   03/31/2023 mem - Initial version
**          05/31/2023 mem - Use procedure name without schema when calling verify_sp_authorized()
**          06/11/2023 mem - Add missing variable _nameWithSchema
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

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

    _batchGroupID = Coalesce(_batchGroupID, 0);
    _mode = Coalesce(_mode, '');

    If _batchGroupID < 1 Then
        RAISE EXCEPTION 'Batch group ID must be a positive number' USING ERRCODE = 'U5201';
    End If;

    _mode := Trim(Coalesce(_mode, ''));

    ---------------------------------------------------
    -- Is batch group in table?
    ---------------------------------------------------

    If Not Exists (SELECT Batch_Group_ID FROM T_Requested_Run_Batch_Group WHERE Batch_Group_ID = _batchGroupID) Then
        _message := format('Batch group does not exist: %s', _batchGroupID);
        RAISE EXCEPTION '%', _message USING ERRCODE = 'U5202';
    End If;

    ---------------------------------------------------
    -- Delete batch group
    ---------------------------------------------------

    If _mode::citext = 'Delete' Then
         -- Assure that the batch group is not used by any batches
        If Exists (SELECT Batch_Group_ID FROM T_Requested_Run_Batches WHERE Batch_Group_ID = _batchGroupID) Then
            _message := format('Cannot delete batch group since used by one or more requested run batches: %s', _batchGroupID);
            RAISE EXCEPTION '%', _message USING ERRCODE = 'U5203';
        Else
            INSERT INTO T_Deleted_Requested_Run_Batch_Group (
                Batch_Group_ID, Batch_Group, Description, Owner_User_ID, Created
            )
            SELECT Batch_Group_ID, Batch_Group, Description, Owner_User_ID, Created
            FROM T_Requested_Run_Batch_Group
            WHERE Batch_Group_ID = _batchGroupID;

            DELETE FROM T_Requested_Run_Batch_Group
            WHERE Batch_Group_ID = _batchGroupID;

            RETURN;
        End If;
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

    _returnCode := 'U5204';

END
$$;


ALTER PROCEDURE public.do_requested_run_batch_group_operation(IN _batchgroupid integer, IN _mode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

