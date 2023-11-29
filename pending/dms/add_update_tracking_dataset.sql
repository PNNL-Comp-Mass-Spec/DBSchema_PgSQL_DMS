
CREATE OR REPLACE PROCEDURE public.add_update_tracking_dataset
(
    _datasetName text = 'TrackingDataset1',
    _experimentName text = 'Placeholder',
    _operatorUsername text = 'D3J410',
    _instrumentName text,
    _runStart text = '2012-06-01'::timestamp,
    _runDuration text = '10',
    _comment text = 'na',
    _eusProposalID text = 'na',
    _eusUsageType text = 'CAP_DEV',
    _eusUsersList text = '',
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new or edits an existing tracking dataset
**
**  Arguments:
**    _datasetName          Dataset name
**    _experimentName       Experiment name
**    _operatorUsername     Operator username
**    _instrumentName       Instrument name
**    _runStart             Acquisition start time
**    _runDuration          Acquisition length (in minutes, as text)
**    _comment              Dataset comment
**    _eusProposalID        EUS proposal ID
**    _eusUsageType         EUS usage type
**    _eusUsersList         EUS User ID (only a single person is allowed, though originally multiple people could be listed)
**    _mode                 Can be 'add', 'update', 'bad', 'check_update', 'check_add'
**    _message              Output message
**    _returnCode           Return code
**    _callingUser          Calling user username
**
**  Auth:   grk
**  Date:   07/03/2012
**          07/19/2012 grk - Extended interval update range around dataset date
**          05/08/2013 mem - Now setting _wellplateName and _wellNumber to Null instead of 'na'
**          02/23/2016 mem - Add Set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/13/2017 mem - Rename _operPRN to _requestorPRN when calling Add_Update_Requested_Run
**                         - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/08/2020 mem - Lookup Username from T_Users using the validated user ID
**          02/25/2021 mem - Use Replace_Character_Codes to replace character codes with punctuation marks
**                         - Use Remove_Cr_Lf to replace linefeeds with semicolons
**          02/17/2022 mem - Rename variables, adjust formatting, convert tabs to spaces
**          02/18/2022 mem - Call Add_Update_Requested_Run if the EUS usage info is updated
**          05/23/2022 mem - Rename _requestorPRN to _requesterPRN when calling Add_Update_Requested_Run
**          11/25/2022 mem - Update call to Add_Update_Requested_Run to use new parameter name
**          11/27/2022 mem - Remove query artifact that was used for debugging
**          12/24/2022 mem - Fix logic error evaluating _runDuration
**          02/27/2023 mem - Use new argument name, _requestName
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _folderName text;
    _addingDataset boolean := false;
    _warning text;
    _experimentCheck text;
    _requestID int := 0;
    _requestName text;
    _wellplateName text := NULL;
    _wellNumber text := NULL;
    _secSep text := 'none';
    _rating text := 'Unknown';
    _existingEusProposal text;
    _existingEusUsageType text;
    _existingEusUser text;
    _columnID int := 0;
    _intStdID int := 0;
    _ratingID int := 1 -- 'No Interest';
    _msType text;
    _refDate timestamp;
    _acqStart timestamp;
    _acqEnd timestamp;
    _datasetTypeID int;
    _badCh text;
    _datasetID int;
    _curDSTypeID int;
    _curDSInstID int;
    _curDSStateID int;
    _curDSRatingID int;
    _newDSStateID int;
    _experimentID int;
    _instrumentID int;
    _instrumentGroup text := '';
    _defaultDatasetTypeID int;
    _userID int;
    _matchCount int;
    _newUsername text;
    _storagePathID int := 0;
    _warningWithPrefix text := '';
    _endDate timestamp;
    _startDate timestamp;
    _alterEnteredByMessage text;

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

        _refDate  := CURRENT_TIMESTAMP;
        _acqStart := _runStart;
        _acqEnd   := _acqStart + INTERVAL '10 minutes'; -- default;

        If Coalesce(_runDuration, '') <> '' Then
            _acqEnd := _acqStart + make_interval(mins => public.try_cast(_runDuration, 10))
        End If;

        _msType        := 'Tracking';
        _datasetTypeID := public.get_dataset_type_id(_msType);

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _mode := Trim(Lower(Coalesce(_mode, '')));

        If _mode = '' Then
            RAISE EXCEPTION '_mode must be specified';
        End If;

        If Coalesce(_datasetName, '') = '' Then
            RAISE EXCEPTION 'Dataset name must be specified';
        End If;

        _folderName := _datasetName;

        If Coalesce(_experimentName, '') = '' Then
            RAISE EXCEPTION 'Experiment name must be specified';
        End If;

        If Coalesce(_folderName, '') = '' Then
            RAISE EXCEPTION 'Folder name must be specified';
        End If;

        If Coalesce(_operatorUsername, '') = '' Then
            RAISE EXCEPTION 'Operator username must be specified';
        End If;

        If Coalesce(_instrumentName, '') = '' Then
            RAISE EXCEPTION 'Instrument name must be specified';
        End If;

        -- Assure that _comment is not null and assure that it doesn't have &quot; or &#34; or &amp;
        _comment := public.replace_character_codes(_comment);

        -- Replace instances of CRLF (or LF) with semicolons
        _comment := public.remove_cr_lf(_comment);

        _eusProposalID := Trim(Coalesce(_eusProposalID, ''));
        _eusUsageType  := Trim(Coalesce(_eusUsageType, ''));
        _eusUsersList  := Trim(Coalesce(_eusUsersList, ''));

        ---------------------------------------------------
        -- Determine if we are adding or check_adding a dataset
        ---------------------------------------------------

        If _mode In ('add', 'check_add') Then
            _addingDataset := true;
        Else
            _addingDataset := false;
        End If;

        ---------------------------------------------------
        -- Validate dataset name
        ---------------------------------------------------

        _badCh := public.validate_chars(_datasetName, '');

        If _badCh <> '' Then
            If _badCh = '[space]' Then
                RAISE EXCEPTION 'Dataset name may not contain spaces';
            ElsIf char_length(_badCh) = 1 Then
                RAISE EXCEPTION 'Dataset name may not contain the character %', _badCh;
            Else
                RAISE EXCEPTION 'Dataset name may not contain the characters %', _badCh;
            End If;

        End If;

        If _datasetName SIMILAR TO '%[.]raw' Or _datasetName SIMILAR TO '%[.]wiff' Or _datasetName SIMILAR TO '%[.]d' Then
            RAISE EXCEPTION 'Dataset name may not end in .raw, .wiff, or .d';
        End If;

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        SELECT dataset_id,
               instrument_id,
               dataset_state_id,
               dataset_rating_id
        INTO _datasetID, _curDSInstID, _curDSStateID, _curDSRatingID
        FROM t_dataset
        WHERE dataset = _datasetName;

        If Not FOUND Then
            -- Cannot update a non-existent entry
            --
            If _mode In ('update', 'check_update') Then
                RAISE EXCEPTION 'Cannot update: Dataset % is not in database', _datasetName;
            End If;
        Else
            -- Cannot create an entry that already exists
            --
            If _addingDataset Then
                RAISE EXCEPTION 'Cannot add dataset % since already in database', _datasetName;
            End If;
        End If;

        ---------------------------------------------------
        -- Resolve experiment ID
        ---------------------------------------------------

        _experimentID := public.get_experiment_id(_experimentName);

        If _experimentID = 0 Then
            RAISE EXCEPTION 'Could not find entry in database for experiment %', _experimentName;
        End If;

        ---------------------------------------------------
        -- Resolve instrument ID
        ---------------------------------------------------

        _instrumentID := public.get_instrument_id(_instrumentName);

        If _instrumentID = 0 Then
            RAISE EXCEPTION 'Could not find entry in database for instrument %', _instrumentName;
        End If;

        ---------------------------------------------------
        -- Resolve user ID for operator username
        ---------------------------------------------------

        _userID := public.get_user_id(_operatorUsername);

        If _userID > 0 Then
            -- Function get_user_id() recognizes both a username and the form 'LastName, FirstName (Username)'
            -- Assure that _operatorUsername contains simply the username
            --
            SELECT username
            INTO _operatorUsername
            FROM t_users
            WHERE user_id = _userID;
        Else
            -- Could not find entry in database for username _operatorUsername
            -- Try to auto-resolve the name

            CALL public.auto_resolve_name_to_username (
                            _operatorUsername,
                            _matchCount => _matchCount,         -- Output
                            _matchingUsername => _newUsername,  -- Output
                            _matchingUserID => _userID);        -- Output

            If _matchCount = 1 Then
                -- Single match found; update _operatorUsername
                _operatorUsername := _newUsername;
            ElsIf _matchCount > 1 Then
                RAISE EXCEPTION 'Operator username % matched more than one user', _operatorUsername;
            Else
                RAISE EXCEPTION 'Could not find entry in database for operator username %', _operatorUsername;
            End If;
        End If;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            ---------------------------------------------------
            -- Lookup storage path ID
            ---------------------------------------------------

            _storagePathID := public.get_instrument_storage_path_for_new_datasets(_instrumentID, _refDate, _autoSwitchActiveStorage => true, _infoOnly => false);

            If _storagePathID = 0 Then
                _storagePathID := 2; -- index of 'none' in table
                RAISE EXCEPTION 'Valid storage path could not be found';
            End If;

            _newDSStateID := 3;

            -- Insert values into a new row
            --
            INSERT INTO t_dataset(
                dataset,
                operator_username,
                comment,
                created,
                instrument_id,
                dataset_type_ID,
                well,
                separation_type,
                dataset_state_id,
                folder_name,
                storage_path_ID,
                exp_id,
                dataset_rating_id,
                lc_column_ID,
                wellplate,
                internal_standard_ID,
                acq_time_start,
                acq_time_end
            ) VALUES (
                _datasetName,
                _operatorUsername,
                _comment,
                _refDate,
                _instrumentID,
                _datasetTypeID,
                _wellNumber,
                _secSep,
                _newDSStateID,
                _folderName,
                _storagePathID,
                _experimentID,
                _ratingID,
                _columnID,
                _wellplateName,
                _intStdID,
                _acqStart,
                _acqEnd
            )
            RETURNING dataset_id
            INTO _datasetID;

            -- If _callingUser is defined, call alter_event_log_entry_user to alter the entered_by field in t_event_log

            If char_length(_callingUser) > 0 Then
                CALL public.alter_event_log_entry_user ('public', 4, _datasetID, _newDSStateID, _callingUser, _message => _alterEnteredByMessage);
                CALL public.alter_event_log_entry_user ('public', 8, _datasetID, _ratingID, _callingUser, _message => _alterEnteredByMessage);
            End If;

            ---------------------------------------------------
            -- Adding a tracking dataset, so need to create a scheduled run
            ---------------------------------------------------

            If _requestID = 0 Then

                If Coalesce(_message, '') <> '' and Coalesce(_warning, '') = '' Then
                    _warning := _message;
                End If;

                _requestName := format('AutoReq_%s', _datasetName);

                CALL public.add_update_requested_run (
                                        _requestName => _requestName,
                                        _experimentName => _experimentName,
                                        _requesterUsername => _operatorUsername,
                                        _instrumentName => _instrumentName,
                                        _workPackage => 'none',
                                        _msType => _msType,
                                        _instrumentSettings => 'na',
                                        _wellplateName => NULL,
                                        _wellNumber => NULL,
                                        _internalStandard => 'na',
                                        _comment => 'Automatically created by Dataset entry',
                                        _eusProposalID => _eusProposalID,
                                        _eusUsageType => _eusUsageType,
                                        _eusUsersList => _eusUsersList,
                                        _mode => 'add-auto',
                                        _request => _requestID,         -- Output
                                        _message => _message,           -- Output
                                        _returnCode => _returnCode,     -- Output
                                        _secSep => _secSep,
                                        _mrmAttachment => '',
                                        _status => 'Completed',
                                        _skipTransactionRollback => true,
                                        _autoPopulateUserListIfBlank => true,        -- Auto populate _eusUsersList if blank since this is an Auto-Request
                                        _callingUser => _callingUser)

                If _returnCode <> '' Then
                    RAISE EXCEPTION 'Create AutoReq run request failed: dataset % with EUS Proposal ID %, Usage Type %, and Users List % -> %',
                                    _datasetName, _eusProposalID, _eusUsageType, _eusUsersList, _message);
                End If;
            End If;

            ---------------------------------------------------
            -- Consume the scheduled run
            ---------------------------------------------------

            _datasetID := 0;

            SELECT dataset_id
            INTO _datasetID
            FROM t_dataset
            WHERE dataset = _datasetName

            If Coalesce(_message, '') <> '' and Coalesce(_warning, '') = '' Then
                _warning := _message;
            End If;

            CALL public.consume_scheduled_run (
                            _datasetID,
                            _requestID,
                            _message => _message,           -- Output
                            _returnCode => _returnCode,     -- Output
                            _callingUser => _callingUser,
                            _logDebugMessages => false);

            If _returnCode <> '' Then
                RAISE EXCEPTION 'Consume operation failed: dataset % -> %', _datasetName, _message;
            End If;

            -- Update t_cached_dataset_instruments
            CALL public.update_cached_dataset_instruments (
                            _processingMode => 0,
                            _datasetId      => _datasetID,
                            _infoOnly       => false,
                            _message        => _message,        -- Output
                            _returnCode     => _returnCode);    -- Output

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE t_dataset
            SET     operator_username = _operatorUsername,
                    comment = _comment,
                    instrument_id = _instrumentID,
                    dataset_type_ID = _datasetTypeID,
                    folder_name = _folderName,
                    exp_id = _experimentID,
                    acq_time_start = _acqStart,
                    acq_time_end = _acqEnd
            WHERE dataset = _datasetName

            -- If _callingUser is defined, call alter_event_log_entry_user to alter the entered_by field in t_event_log

            If char_length(_callingUser) > 0 And _ratingID <> Coalesce(_curDSRatingID, -1000) Then
                CALL public.alter_event_log_entry_user ('public', 8, _datasetID, _ratingID, _callingUser, _message => _alterEnteredByMessage);
            End If;

            -- Call Add_Update_Requested_Run if the EUS info has changed

            SELECT RR.request_name,
                   RR.eus_proposal_id,
                   RR.eus_usage_type_id,
                   RRD.eus_user
            INTO _requestName, _existingEusProposal, _existingEusUsageType, _existingEusUser
            FROM t_dataset AS DS
                 INNER JOIN t_requested_run AS RR
                   ON DS.dataset_id = RR.dataset_id
                 INNER JOIN V_Requested_Run_Detail_Report AS RRD
                   ON RR.request_id = RRD.Request
            WHERE DS.dataset = _datasetName;

            If FOUND And (
              Coalesce(_existingEusProposal, '') <> _eusProposalID OR
              Coalesce(_existingEusUsageType, '') <> _eusUsageType OR
              Coalesce(_existingEusUser, '') <> _eusUsersList) Then

                CALL public.add_update_requested_run (
                                        _requestName => _requestName,
                                        _experimentName => _experimentName,
                                        _requesterUsername => _operatorUsername,
                                        _instrumentName => _instrumentName,
                                        _workPackage => 'none',
                                        _msType => _msType,
                                        _instrumentSettings => 'na',
                                        _wellplateName => NULL,
                                        _wellNumber => NULL,
                                        _internalStandard => 'na',
                                        _comment => 'Automatically created by Dataset entry',
                                        _eusProposalID => _eusProposalID,
                                        _eusUsageType => _eusUsageType,
                                        _eusUsersList => _eusUsersList,
                                        _mode => 'update',
                                        _request => _requestID,         -- Output
                                        _message => _message,           -- Output
                                        _returnCode => _returnCode,     -- Output
                                        _secSep => _secSep,
                                        _mrmAttachment => '',
                                        _status => 'Completed',
                                        _skipTransactionRollback => true,
                                        _autoPopulateUserListIfBlank => true,   -- Auto populate _eusUsersList if blank since this is an Auto-Request
                                        _callingUser => _callingUser,
                                        _vialingConc => null,
                                        _vialingVol => null,
                                        _stagingLocation => null,
                                        _requestIDForUpdate => null,
                                        _logDebugMessages => false,
                                        _resolvedInstrumentInfo => _resolvedInstrumentInfo);    -- Output

                If _returnCode <> '' Then
                    RAISE EXCEPTION 'Call to add_update_requested_run failed: dataset % with EUS Proposal ID %, Usage Type %, and Users List % -> %',
                                    _datasetName, _eusProposalID, _eusUsageType, , _eusUsersList_message;
                End If;
            End If;

        End If;

        -- Update _message if _warning is not empty
        If Coalesce(_warning, '') <> '' Then

            If _warning like 'Warning:' Then
                _warningWithPrefix := _warning;
            Else
                _warningWithPrefix := format('Warning: %s', _warning);
            End If;

            If Coalesce(_message, '') = '' Then
                _message := _warningWithPrefix;
            ElsIf _message = _warning Then
                _message := _warningWithPrefix;
            Else
                _message := format('%s; %s', _warningWithPrefix, _message);
            End If;
        End If;

        ---------------------------------------------------
        -- Update interval table
        ---------------------------------------------------

        _startDate := _refDate - INTERVAL '1 month';
        _endDate   := _refDate + INTERVAL '1 month';

        CALL public.update_dataset_interval (
                        _instrumentName,
                        _startDate,
                        _endDate,
                        _message => _message,           -- Output
                        _returnCode => _returnCode,     -- Output
                        _infoOnly => false)

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

COMMENT ON PROCEDURE public.add_update_tracking_dataset IS 'AddUpdateTrackingDataset';
