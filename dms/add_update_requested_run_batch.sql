--
-- Name: add_update_requested_run_batch(integer, text, text, text, text, text, text, text, text, text, integer, integer, text, text, text, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_requested_run_batch(INOUT _id integer, IN _name text, IN _description text, IN _requestedrunlist text, IN _ownerusername text, IN _requestedbatchpriority text, IN _requestedcompletiondate text, IN _justificationhighpriority text, IN _requestedinstrumentgroup text, IN _comment text, IN _batchgroupid integer DEFAULT NULL::integer, IN _batchgrouporder integer DEFAULT NULL::integer, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _raiseexceptions boolean DEFAULT true)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Adds new or edits existing requested run batch
**
**  Arguments:
**    _id                           Batch ID to update if _mode is 'update'; otherwise, the ID of the newly created batch
**    _name                         Batch name
**    _description                  Description
**    _requestedRunList             Requested run IDs
**    _ownerUsername                Owner username
**    _requestedBatchPriority       Batch prioerity
**    _requestedCompletionDate      Requested completion date
**    _justificationHighPriority    Justification for high priority
**    _requestedInstrumentGroup     Will typically contain an instrument group, not an instrument name
**    _comment                      Batch comment
**    _batchGroupID                 Batch group ID
**    _batchGroupOrder              Batch group order
**    _mode                         'add' or 'update' or 'PreviewAdd'
**    _raiseExceptions              When true, raise an exception; when false, update _returnCode if an error
**
**  Auth:   grk
**  Date:   01/11/2006 - initial version
**          09/15/2006 jds - Added _requestedBatchPriority, _actualBathPriority, _requestedCompletionDate, _justificationHighPriority, and _comment
**          11/04/2006 grk - Added _requestedInstrument
**          12/03/2009 grk - Checking for presence of _justificationHighPriority If priority is high
**          05/05/2010 mem - Now calling auto_resolve_name_to_username to check If _operatorUsername contains a person's real name rather than their username
**          08/04/2010 grk - Use try-catch for error handling
**          08/27/2010 mem - Now auto-switching _requestedInstrument to be instrument group instead of instrument name
**                         - Expanded _requestedCompletionDate to varchar(24) to support long dates of the form 'Jan 01 2010 12:00:00AM'
**          05/14/2013 mem - Expanded _requestedCompletionDate to varchar(32) to support long dates of the form 'Jan 29 2010 12:00:00:000AM'
**          06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          04/28/2017 mem - Disable logging certain messages to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          06/23/2017 mem - Check for _requestedRunList containing request names instead of IDs
**          08/01/2017 mem - Use THROW If not authorized
**          08/18/2017 mem - Log additional errors to T_Log_Entries
**          12/08/2020 mem - Lookup Username from T_Users using the validated user ID
**          05/29/2021 mem - Refactor validation code into new stored procedure
**          05/31/2021 mem - Add support for _mode = 'PreviewAdd'
**                         - Add _raiseExceptions
**          06/02/2021 mem - Expand _requestedRunList to varchar(max)
**          07/24/2022 mem - Remove trailing tabs from batch name
**          08/01/2022 mem - If _mode is 'update' and _id is 0, do not set Batch ID to 0 for other requested runs
**          02/10/2023 mem - Call update_cached_requested_run_batch_stats
**          02/14/2023 mem - Rename variable and use new parameter names for validate_requested_run_batch_params
**          02/16/2023 mem - Add _batchGroupID and _batchGroupOrder
**                         - Rename _requestedInstrument to _requestedInstrumentGroup
**          02/16/2023 mem - Ported to PostgreSQL
**          03/30/2023 mem - Retrieve values from _message and _returnCode when calling update_cached_requested_run_batch_stats
**          05/07/2023 mem - Remove unused variable
**          05/10/2023 mem - Capitalize procedure name sent to post_log_entry
**          05/30/2023 mem - Use format() for string concatenation
**          05/31/2023 mem - Use procedure name without schema when calling verify_sp_authorized()
**          06/11/2023 mem - Add missing variable _nameWithSchema
**          06/16/2023 mem - Use named arguments when calling append_to_text()
**                         - Fix bug reporting number of requested runs that would be associated with the batch
**                         - Use new column name, owner_user_id
**          07/11/2023 mem - Use COUNT(batch_id) instead of COUNT(*)
**          09/07/2023 mem - Use default delimiter and max length when calling append_to_text()
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_list for a comma-separated list
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _logErrors boolean := false;
    _instrumentGroupToUse text;
    _userID int := 0;
    _firstInvalid text;
    _count int;
    _countInvalid int;
    _invalidIDs text := null;
    _batchIDConfirm int := 0;
    _debugMsg text;
    _existingBatchGroupID int := null;
    _matchCount int;
    _duplicateBatchID int;
    _duplicateMessage text;
    _requestedCompletionTimestamp timestamp;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    _raiseExceptions := Coalesce(_raiseExceptions, true);

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

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _mode := Trim(Lower(Coalesce(_mode, '')));

        CALL validate_requested_run_batch_params (
                    _batchID => _id,
                    _name => _name,
                    _description => _description,
                    _ownerUsername => _ownerUsername,
                    _requestedBatchPriority => _requestedCompletionDate,
                    _requestedCompletionDate => '',
                    _justificationHighPriority => _justificationHighPriority,
                    _requestedInstrumentGroup => _requestedInstrumentGroup,
                    _comment => _comment,
                    _batchGroupID => _batchGroupID,                     -- Input/Output
                    _batchGroupOrder => _batchGroupOrder,               -- Input/Output
                    _mode => _mode,
                    _instrumentGroupToUse => _instrumentGroupToUse,     -- Output
                    _userID => _userID,                                 -- Output
                    _message => _message,                               -- Output
                    _returnCode => _returnCode);                        -- Output

        If _returnCode <> '' Then
            If _raiseExceptions Then
                RAISE EXCEPTION '%', _message;
            Else
                RETURN;
            End If;
        End If;

        _name        := Trim(Replace(Replace(_name, chr(10), ' '), chr(9), ' '));
        _description := Trim(Coalesce(_description, ''));

        If char_length(Coalesce(_requestedCompletionDate, '')) = 0 Then
            _requestedCompletionTimestamp := null;
        Else
            _requestedCompletionTimestamp := public.try_cast(_requestedCompletionDate, null::timestamp);
        End If;

        ---------------------------------------------------
        -- Create temporary table for requests in list
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_RequestedRuns (
            RequestIDText text NULL,
            Request_ID int NULL
        );

        ---------------------------------------------------
        -- Populate temporary table from list
        ---------------------------------------------------

        INSERT INTO Tmp_RequestedRuns (RequestIDText)
        SELECT DISTINCT Value
        FROM public.parse_delimited_list(_requestedRunList);

        ---------------------------------------------------
        -- Convert Request IDs to integers
        ---------------------------------------------------

        UPDATE Tmp_RequestedRuns
        SET Request_ID = public.try_cast(RequestIDText, null::int);

        If Exists (Select * FROM Tmp_RequestedRuns WHERE Request_ID Is Null) Then

            SELECT RequestIDText
            INTO _firstInvalid
            FROM Tmp_RequestedRuns
            WHERE Request_ID Is Null
            LIMIT 1;

            _logErrors := false;
            _message := format('Requested runs must be integers, not names; first invalid item: %s', _firstInvalid);

            If _raiseExceptions Then
                RAISE EXCEPTION '%', _message;
            Else
                _returnCode := 'U5208';
                RETURN;
            End If;
        End If;

        ---------------------------------------------------
        -- Check status of prospective member requests
        ---------------------------------------------------

        -- Do all requests in list actually exist?
        --
        SELECT COUNT(*)
        INTO _countInvalid
        FROM Tmp_RequestedRuns
        WHERE NOT (request_id IN
        (
            SELECT request_id
            FROM t_requested_run)
        );

        If _countInvalid > 0 Then

            SELECT string_agg(RequestIDText, ', ' ORDER BY RequestIDText)
            INTO _invalidIDs
            FROM Tmp_RequestedRuns
            WHERE NOT request_id IN ( SELECT request_id FROM t_requested_run);

            _logErrors := false;
            _message := format('Requested run list contains requests that do not exist: %s', _invalidIDs);

            If _raiseExceptions Then
                RAISE EXCEPTION '%', _message;
            Else
                _returnCode := 'U5209';
                RETURN;
            End If;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Action for preview mode
        ---------------------------------------------------

        If _mode::citext = 'PreviewAdd' Then
            SELECT COUNT(*)
            INTO _count
            FROM Tmp_RequestedRuns;

            _message := format('Would create batch "%s" with %s requested runs', _name, _count);

            DROP TABLE Tmp_RequestedRuns;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            INSERT INTO t_requested_run_batches (
                batch,
                description,
                owner_user_id,
                locked,
                requested_batch_priority,
                actual_batch_priority,
                requested_completion_date,
                justification_for_high_priority,
                requested_instrument_group,
                comment,
                batch_group_id,
                batch_group_order
            ) VALUES (
                _name,
                _description,
                _userID,
                'No',
                _requestedBatchPriority,
                'Normal',
                _requestedCompletionTimestamp,
                _justificationHighPriority,
                _instrumentGroupToUse,
                _comment,
                _batchGroupID,
                _batchGroupOrder
            )
            RETURNING batch_id
            INTO _id;

            -- As a precaution, query t_requested_run_batches using Batch name to make sure we have the correct Exp_ID

            SELECT batch_id
            INTO _batchIDConfirm
            FROM t_requested_run_batches
            WHERE batch = _name;

            If _id <> Coalesce(_batchIDConfirm, _id) Then
                _debugMsg := format('Warning: Inconsistent identity values when adding batch %s: Found ID %s but the INSERT INTO query reported %s',
                                    _name, _batchIDConfirm, _id);

                CALL post_log_entry ('Error', _debugMsg, 'Add_Update_Requested_Run_Batch');

                _id := _batchIDConfirm;
            End If;

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            -- Check whether this batch is currently a member of a batch group
            SELECT Batch_Group_ID
            INTO _existingBatchGroupID
            FROM T_Requested_Run_Batches
            WHERE batch_id = _id;

            If Not FOUND Then
                _existingBatchGroupID := Null;
            End If;

            UPDATE t_requested_run_batches
            SET batch = _name,
                description = _description,
                owner_user_id = _userID,
                requested_batch_priority = _requestedBatchPriority,
                requested_completion_date = _requestedCompletionTimestamp,
                justification_for_high_priority = _justificationHighPriority,
                requested_instrument_group = _instrumentGroupToUse,
                comment = _comment,
                batch_group_id = _batchGroupID,
                batch_group_order = _batchGroupOrder
            WHERE batch_id = _id;

        End If;

        ---------------------------------------------------
        -- Update member requests
        ---------------------------------------------------

        If _mode In ('add', 'update') Then
            If _id > 0 Then
                -- Remove any existing references to the batch
                -- from requested runs
                --
                UPDATE t_requested_run
                SET batch_id = 0
                WHERE batch_id = _id AND
                      NOT request_id IN ( SELECT Request_ID
                                          FROM Tmp_RequestedRuns );

            End If;

            -- Add reference to this batch to the requests in the list
            --
            UPDATE t_requested_run
            SET batch_id = _id
            WHERE request_id IN (Select request_id from Tmp_RequestedRuns) AND
                  Coalesce(batch_id, 0) <> _id;
        End If;

        If _mode = 'update' Then
            _message := '';

            If Coalesce(_existingBatchGroupID, 0) > 0 And Coalesce(_batchGroupID, 0) <> _existingBatchGroupID Then
                If Coalesce(_batchGroupID, 0) = 0 Then
                    _message := format('Removed batch from batch group %s', _existingBatchGroupID);
                Else
                    _message := format('Moved batch from batch group %s to batch group %s', _existingBatchGroupID, _batchGroupID);
                End If;
            End If;

            If Coalesce(_batchGroupID, 0) > 0 Then

                -- Check for batch group order conflicts
                SELECT COUNT(batch_id)
                INTO _matchCount
                FROM T_Requested_Run_Batches
                WHERE Batch_Group_ID = _batchGroupID AND
                      Batch_Group_Order = _batchGroupOrder;

                If _matchCount > 1 Then

                    SELECT batch_id
                    INTO _duplicateBatchID
                    FROM T_Requested_Run_Batches
                    WHERE batch_group_id = _batchGroupID AND
                          batch_group_order = _batchGroupOrder And
                          batch_id <> _id
                    LIMIT 1;

                    _duplicateMessage := format('Warning, both this batch and batch %s have batch group order = %s', _duplicateBatchID, _batchGroupOrder);

                    _message := append_to_text(_message, _duplicateMessage);
                End If;
            End If;

        End If;

        ---------------------------------------------------
        -- Update stats in t_cached_requested_run_batch_stats
        ---------------------------------------------------

        If _id > 0 Then
            CALL update_cached_requested_run_batch_stats (
                _id,
                _fullrefresh => false,
                _message => _message,           -- Output
                _returncode => _returncode);    -- Output

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

    DROP TABLE IF EXISTS Tmp_RequestedRuns;
END
$$;


ALTER PROCEDURE public.add_update_requested_run_batch(INOUT _id integer, IN _name text, IN _description text, IN _requestedrunlist text, IN _ownerusername text, IN _requestedbatchpriority text, IN _requestedcompletiondate text, IN _justificationhighpriority text, IN _requestedinstrumentgroup text, IN _comment text, IN _batchgroupid integer, IN _batchgrouporder integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _raiseexceptions boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_requested_run_batch(INOUT _id integer, IN _name text, IN _description text, IN _requestedrunlist text, IN _ownerusername text, IN _requestedbatchpriority text, IN _requestedcompletiondate text, IN _justificationhighpriority text, IN _requestedinstrumentgroup text, IN _comment text, IN _batchgroupid integer, IN _batchgrouporder integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _raiseexceptions boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_requested_run_batch(INOUT _id integer, IN _name text, IN _description text, IN _requestedrunlist text, IN _ownerusername text, IN _requestedbatchpriority text, IN _requestedcompletiondate text, IN _justificationhighpriority text, IN _requestedinstrumentgroup text, IN _comment text, IN _batchgroupid integer, IN _batchgrouporder integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _raiseexceptions boolean) IS 'addUpdateRequestedRunBatch';

