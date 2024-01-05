--
-- Name: validate_requested_run_batch_params(integer, text, text, text, text, text, text, text, text, integer, integer, text, text, integer, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.validate_requested_run_batch_params(IN _batchid integer, IN _name text, IN _description text, IN _ownerusername text, IN _requestedbatchpriority text, IN _requestedcompletiondate text, IN _justificationhighpriority text, IN _requestedinstrumentgroup text, IN _comment text, INOUT _batchgroupid integer DEFAULT NULL::integer, INOUT _batchgrouporder integer DEFAULT NULL::integer, IN _mode text DEFAULT 'add'::text, INOUT _instrumentgrouptouse text DEFAULT ''::text, INOUT _userid integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Validate values for creating/updating a requested run batch
**
**  Arguments:
**    _batchID                      Only used when _mode is 'update'
**    _name                         Batch name
**    _description                  Description (unused)
**    _ownerUsername                Owner username
**    _requestedBatchPriority       Requested batch priority
**    _requestedCompletionDate      Requested completion date
**    _justificationHighPriority    Justification for high priority
**    _requestedInstrumentGroup     Will typically contain an instrument group, not an instrument name
**    _comment                      Batch comment (unused)
**    _batchGroupID                 Input/Output: batch group ID
**    _batchGroupOrder              Input/Output: batch group order
**    _mode                         Mode: 'add' or 'update' or 'PreviewAdd'
**    _instrumentGroupToUse         Output: instrument group to use
**    _userID                       Output: user ID corresponding to the owner username
**    _message                      Status message
**    _returnCode                   Return code
**
**  Auth:   mem
**  Date:   05/29/2021 mem - Refactored code from AddUpdateRequestedRunBatch
**          05/31/2021 mem - Add support for _mode = 'PreviewAdd'
**          02/14/2023 mem - Rename username and instrument group parameters
**                         - Update error message
**          02/16/2023 mem - Add _batchGroupID and _batchGroupOrder
**          02/16/2023 mem - Ported to PostgreSQL
**          05/12/2023 mem - Rename variables
**          05/19/2023 mem - Move INTO to new line
**          05/22/2023 mem - Use format() for string concatenation
**          06/16/2023 mem - Report an error if _mode is 'update' and _batchID is 0
**                         - Validate instrument group name
**                         - Use citext for _locked
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          12/15/2023 mem - Coalesce nulls to empty strings and update warning messages
**          01/03/2024 mem - Update warning messages
**
*****************************************************/
DECLARE
    _locked citext;
    _matchCount int;
    _newUsername text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN
        _name                      := Trim(Coalesce(_name, ''));
        _description               := Trim(Coalesce(_description, ''));
        _ownerUsername             := Trim(Coalesce(_ownerUsername, ''));
        _requestedBatchPriority    := Trim(Coalesce(_requestedBatchPriority, ''));
        _requestedCompletionDate   := Trim(Coalesce(_requestedCompletionDate, ''));
        _justificationHighPriority := Trim(Coalesce(_justificationHighPriority, ''));
        _requestedInstrumentGroup  := Trim(Coalesce(_requestedInstrumentGroup, ''));
        _comment                   := Trim(Coalesce(_comment, ''));
        _mode                      := Trim(Lower(Coalesce(_mode, '')));

        If _name = '' Then
            _message := 'Must define a batch name';
            _returnCode := 'U5201';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        If _requestedCompletionDate <> '' Then
            -- IsDate() equivalent
            If public.try_cast(_requestedCompletionDate, null::timestamp) Is Null Then
                _message := format('Requested completion date is not a valid date: %s', _requestedCompletionDate);
                _returnCode := 'U5202';
                RETURN;
            End If;
        End If;

        ---------------------------------------------------
        -- Determine the Instrument Group
        ---------------------------------------------------

        -- Set the instrument group to _requestedInstrumentGroup for now
        _instrumentGroupToUse := _requestedInstrumentGroup;

        If Not Exists (SELECT instrument_group FROM t_instrument_group WHERE instrument_group = _instrumentGroupToUse::citext) Then
            -- Try to update instrument group using t_instrument_name
            SELECT instrument_group
            INTO _instrumentGroupToUse
            FROM t_instrument_name
            WHERE instrument = _requestedInstrumentGroup::citext;

            If Not FOUND Then
                If _requestedInstrumentGroup = '' Then
                    _message := 'Invalid Instrument Group: empty string';
                Else
                    _message := format('Invalid Instrument Group: %s', _requestedInstrumentGroup);
                End If;

                _returnCode := 'U5203';
                RETURN;
            End If;
        End If;

        ---------------------------------------------------
        -- High priority requires justification
        ---------------------------------------------------

        If _requestedBatchPriority::citext = 'High' And _justificationHighPriority = '' Then
            _message := 'Justification must be entered if high priority is being requested';
            _returnCode := 'U5204';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        If _mode In ('add', Lower('PreviewAdd')) Then
            If Exists (SELECT batch FROM t_requested_run_batches WHERE batch = _name::citext) Then
                _message := format('Cannot add: batch "%s" already exists', _name);
                _returnCode := 'U5205';
                RETURN;
            End If;
        End If;

        -- Cannot update a non-existent entry

        If _mode = 'update' Then

            If Coalesce(_batchID, 0) = 0 Then
                _message := 'Cannot update batch; ID must non-zero';
                _returnCode := 'U5206';
                RETURN;
            End If;

            SELECT locked
            INTO _locked
            FROM t_requested_run_batches
            WHERE batch_id = _batchID;

            If Not FOUND Then
                _message := format('Cannot update: batch ID %s does not exist', _batchID);
                _returnCode := 'U5207';
                RETURN;
            End If;

            If _locked = 'Yes' Then
                _message := format('Cannot update: batch ID %s is locked', _batchID);
                _returnCode := 'U5208';
                RETURN;
            End If;
        End If;

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
                If _matchCount = 0 Then
                    _message := format('Invalid owner username: "%s" does not exist', _ownerUsername);
                Else
                    _message := format('Invalid owner username: "%s" matches more than one user', _ownerUsername);
                End If;

                _returnCode := 'U5209';
                RETURN;
            End If;
        End If;

        ---------------------------------------------------
        -- Verify _batchGroupID
        ---------------------------------------------------

        If Coalesce(_batchGroupID, 0) = 0 Then
            _batchGroupID := null;
            _batchGroupOrder := null;
        End If;

        If _batchGroupID > 0 And Not Exists (SELECT Batch_Group_ID FROM T_Requested_Run_Batch_Group WHERE Batch_Group_ID = _batchGroupID) Then
            _message := format('Requested run batch group %s does not exist', _batchGroupID);
            _returnCode := 'U5210';
            RETURN;
        End If;

        If _batchGroupID > 0 And Coalesce(_batchGroupOrder, 0) < 1 Then
            _batchGroupOrder := 1;
        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

END
$$;


ALTER PROCEDURE public.validate_requested_run_batch_params(IN _batchid integer, IN _name text, IN _description text, IN _ownerusername text, IN _requestedbatchpriority text, IN _requestedcompletiondate text, IN _justificationhighpriority text, IN _requestedinstrumentgroup text, IN _comment text, INOUT _batchgroupid integer, INOUT _batchgrouporder integer, IN _mode text, INOUT _instrumentgrouptouse text, INOUT _userid integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE validate_requested_run_batch_params(IN _batchid integer, IN _name text, IN _description text, IN _ownerusername text, IN _requestedbatchpriority text, IN _requestedcompletiondate text, IN _justificationhighpriority text, IN _requestedinstrumentgroup text, IN _comment text, INOUT _batchgroupid integer, INOUT _batchgrouporder integer, IN _mode text, INOUT _instrumentgrouptouse text, INOUT _userid integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.validate_requested_run_batch_params(IN _batchid integer, IN _name text, IN _description text, IN _ownerusername text, IN _requestedbatchpriority text, IN _requestedcompletiondate text, IN _justificationhighpriority text, IN _requestedinstrumentgroup text, IN _comment text, INOUT _batchgroupid integer, INOUT _batchgrouporder integer, IN _mode text, INOUT _instrumentgrouptouse text, INOUT _userid integer, INOUT _message text, INOUT _returncode text) IS 'ValidateRequestedRunBatchParams';

