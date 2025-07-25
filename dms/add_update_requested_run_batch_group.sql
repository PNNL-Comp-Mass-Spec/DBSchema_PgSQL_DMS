--
-- Name: add_update_requested_run_batch_group(integer, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_requested_run_batch_group(INOUT _id integer, IN _name text, IN _description text, IN _requestedrunbatchlist text, IN _ownerusername text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit existing requested run batch group
**
**  Arguments:
**    _id                       Batch Group ID to update if _mode is 'update'; otherwise, the ID of the newly created batch group
**    _name                     Batch group name
**    _description              Description
**    _requestedRunBatchList    Requested run batch IDs
**    _ownerUsername            Will typically contain an instrument group, not an instrument name; could also contain '(lookup)'
**    _mode                     Mode: 'add', 'update', or 'PreviewAdd'
**    _message                  Status message
**    _returnCode               Return code
**
**  Auth:   mem
**  Date:   02/15/2023 - initial version
**          05/10/2023 mem - Capitalize procedure name sent to post_log_entry
**          05/30/2023 mem - Use format() for string concatenation
**          05/31/2023 mem - Use procedure name without schema when calling verify_sp_authorized()
**          06/11/2023 mem - Add missing variable _nameWithSchema
**          09/07/2023 mem - Align assignment statements
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_list_ordered for a comma-separated list
**          10/12/2023 mem - Add/update variables
**                         - Only drop temp table if actually created
**          01/03/2024 mem - Update warning messages
**          01/11/2024 mem - Check for empty strings instead of using char_length()
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**          07/19/2025 mem - Raise an exception if _mode is undefined or unsupported
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _logErrors boolean := false;
    _tempTableCreated boolean := false;
    _userID int;
    _firstInvalid text;
    _matchCount int;
    _updateCount int;
    _newUsername text;
    _invalidIDs text;
    _batchGroupIDConfirm int;
    _debugMsg text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
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

    BEGIN
        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _id                    := Coalesce(_id, 0);
        _name                  := Trim(Replace(Replace(_name, chr(10), ' '), chr(9), ' '));
        _description           := Trim(Coalesce(_description, ''));
        _requestedRunBatchList := Trim(Coalesce(_requestedRunBatchList, ''));
        _ownerUsername         := Trim(Coalesce(_ownerUsername, ''));
        _mode                  := Trim(Lower(Coalesce(_mode, '')));

        If _mode = '' Then
            RAISE EXCEPTION 'Empty string specified for parameter _mode';
        ElsIf Not _mode IN ('add', 'update', 'check_add', 'check_update', Lower('PreviewAdd'), Lower('PreviewUpdate')) Then
            RAISE EXCEPTION 'Unsupported value for parameter _mode: %', _mode;
        End If;

        If _name = '' Then
            _message := 'Must define a batch group name';
            _returnCode := 'U5201';
            RAISE EXCEPTION '%', _message;
        End If;

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        If _mode In ('add', Lower('PreviewAdd')) Then
            If Exists (SELECT Batch_Group FROM t_requested_run_batch_group WHERE Batch_Group = _name::citext) Then
                _message := format('Cannot add: batch group "%s" already exists', _name);
                _returnCode := 'U5203';
                RAISE EXCEPTION '%', _message;
            End If;
        End If;

        If _mode = 'update' Then
            -- Cannot update a non-existent entry

            If Not Exists (SELECT Batch_Group_ID FROM t_requested_run_batch_group WHERE Batch_Group_ID = _id) Then
                _message := format('Cannot update: batch group ID %s does not exist', _id);
                _returnCode := 'U5205';
                RAISE EXCEPTION '%', _message;
            End If;
        End If;

       _logErrors := true;

        ---------------------------------------------------
        -- Resolve user ID for owner username
        ---------------------------------------------------

        _userID := public.get_user_id(_ownerUsername);

        If _userID > 0 Then
            -- Function get_user_id recognizes both a username and the form 'LastName, FirstName (Username)'
            -- Assure that _ownerUsername contains simply the username

            SELECT username
            INTO _ownerUsername
            FROM t_users
            WHERE user_id = _userID;
        Else
            -- Could not find entry in database for username _ownerUsername
            -- Try to auto-resolve the name

            CALL public.auto_resolve_name_to_username (
                        _ownerUsername,
                        _matchCount       => _matchCount,   -- Output
                        _matchingUsername => _newUsername,  -- Output
                        _matchingUserID   => _userID);      -- Output

            If _matchCount = 1 Then
                -- Single match found; update _ownerUsername
                _ownerUsername := _newUsername;
            Else
                _logErrors := false;

                If _matchCount = 0 Then
                    _message := format('Invalid owner username: "%s" does not exist', _ownerUsername);
                Else
                    _message := format('Invalid owner username: "%s" matches more than one user', _ownerUsername);
                End If;

                _returnCode := 'U5207';
                RAISE EXCEPTION '%', _message;
            End If;
        End If;

        ---------------------------------------------------
        -- Create temporary table for batches in list
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_BatchIDs (
            Entry_ID int NOT NULL,
            Batch_ID_Text text NULL,
            Batch_ID int NULL,
            Batch_Group_Order int NULL
        );

        _tempTableCreated := true;

        ---------------------------------------------------
        -- Populate temporary table from list
        ---------------------------------------------------

        INSERT INTO Tmp_BatchIDs (Entry_ID, Batch_ID_Text)
        SELECT MIN(Entry_ID), Value
        FROM public.parse_delimited_list_ordered(_requestedRunBatchList)
        GROUP BY Value;

        ---------------------------------------------------
        -- Convert Batch IDs to integers
        ---------------------------------------------------

        UPDATE Tmp_BatchIDs
        SET Batch_ID = public.try_cast(Batch_ID_Text, null::int);

        If Exists (SELECT Entry_ID FROM Tmp_BatchIDs WHERE Batch_ID IS NULL) Then
            SELECT Batch_ID_Text
            INTO _firstInvalid
            FROM Tmp_BatchIDs
            WHERE Batch_ID IS NULL;

            _logErrors := false;
            _message := format('Batch IDs must be integers, not names; first invalid item: %s', _firstInvalid);

            _returnCode := 'U5208';
            RAISE EXCEPTION '%', _message;
        End If;

        ---------------------------------------------------
        -- Verify that batch IDs exist
        ---------------------------------------------------

        SELECT COUNT(*)
        INTO _matchCount
        FROM Tmp_BatchIDs
        WHERE NOT (Batch_ID IN
        (
            SELECT batch_id
            FROM t_requested_run_batches)
        );

        If _matchCount <> 0 Then
            SELECT string_agg(Batch_ID_Text, ', ' ORDER BY Batch_ID_Text)
            INTO _invalidIDs
            FROM Tmp_BatchIDs
            WHERE NOT Batch_ID IN (SELECT Batch_ID FROM t_requested_run_batches);

            _logErrors := false;
            _message := format('Batch ID list contains batches that do not exist: %s', _invalidIDs);

            _returnCode := 'U5209';
            RAISE EXCEPTION '%', _message;
        End If;

        ---------------------------------------------------
        -- Update Batch_Group_Order in Tmp_BatchIDs
        ---------------------------------------------------

        UPDATE Tmp_BatchIDs
        SET Batch_Group_Order = RankQ.Batch_Group_Order
        FROM (SELECT Batch_ID,
                     Row_Number() OVER (ORDER BY Entry_ID) AS Batch_Group_Order
              FROM Tmp_BatchIDs) RankQ
        WHERE Tmp_BatchIDs.Batch_ID = RankQ.Batch_ID;
        --
        GET DIAGNOSTICS _updateCount = ROW_COUNT;

        ---------------------------------------------------
        -- Action for preview mode
        ---------------------------------------------------

        If _mode = Lower('PreviewAdd') Then
            _message := format('Would create batch group "%s" with %s batches', _name, _updateCount);

            DROP TABLE Tmp_BatchIDs;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then
            INSERT INTO t_requested_run_batch_group (
                Batch_Group,
                Description,
                Owner_User_ID
            ) VALUES (
                _name,
                _description,
                _userID
            )
            RETURNING batch_group_id
            INTO _id;

            -- As a precaution, query t_requested_run_batch_group using Batch name to make sure we have the correct Exp_ID

            SELECT batch_group_id
            INTO _batchGroupIDConfirm
            FROM t_requested_run_batch_group
            WHERE batch_group = _name;

            If _id <> Coalesce(_batchGroupIDConfirm, _id) Then
                _debugMsg := format('Warning: Inconsistent identity values when adding batch group%s: Found ID %s but the INSERT INTO query reported %s',
                                    _name, _batchGroupIDConfirm, _id);

                CALL post_log_entry ('Error', _debugMsg, 'Add_Update_Requested_Run_Batch');

                _id := _batchIDConfirm;
            End If;
        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then
            UPDATE t_requested_run_batch_group
            SET Batch_Group   = _name,
                Description   = _description,
                Owner_User_ID = _userID
            WHERE Batch_Group_ID = _id;
        End If;

        ---------------------------------------------------
        -- Update member batches
        ---------------------------------------------------

        If _mode In ('add', 'update') Then
            If _id > 0 Then
                -- Remove any existing references to the batch group
                -- from requested run batches

                UPDATE t_requested_run_batches
                SET Batch_Group_ID = null
                WHERE Batch_Group_ID = _id AND
                      NOT t_requested_run_batches.Batch_Group_ID IN (SELECT Batch_ID
                                                                     FROM Tmp_BatchIDs);
            End If;

            -- Add a reference to this batch group to the batches in the list

            UPDATE t_requested_run_batches
            SET Batch_Group_ID    = _id,
                Batch_Group_Order = Src.Batch_Group_Order
            FROM Tmp_BatchIDs Src
            WHERE t_requested_run_batches.batch_id = Src.Batch_ID;
        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    If _tempTableCreated Then
        DROP TABLE IF EXISTS Tmp_BatchIDs;
    End If;
END
$$;


ALTER PROCEDURE public.add_update_requested_run_batch_group(INOUT _id integer, IN _name text, IN _description text, IN _requestedrunbatchlist text, IN _ownerusername text, IN _mode text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_requested_run_batch_group(INOUT _id integer, IN _name text, IN _description text, IN _requestedrunbatchlist text, IN _ownerusername text, IN _mode text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_requested_run_batch_group(INOUT _id integer, IN _name text, IN _description text, IN _requestedrunbatchlist text, IN _ownerusername text, IN _mode text, INOUT _message text, INOUT _returncode text) IS 'AddUpdateRequestedRunBatchGroup';

