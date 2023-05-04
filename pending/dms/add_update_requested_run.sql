--
CREATE OR REPLACE PROCEDURE public.add_update_requested_run
(
    _requestName text,
    _experimentName text,
    _requesterUsername text,
    _instrumentGroup text,
    _workPackage text,
    _msType text,
    _instrumentSettings text = 'na',
    _wellplateName text = 'na',
    _wellNumber text = 'na',
    _internalStandard text = 'na',
    _comment text = 'na',
    _batch int = 0,
    _block int = 0,
    _runOrder int = 0,
    _eusProposalID text = 'na',
    _eusUsageType text,
    _eusUsersList text = '',
    _mode text = 'add',
    INOUT _request int,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _secSep text = 'LC-Formic_100min',
    _mrmAttachment text,
    _status text = 'Active',
    _skipTransactionRollback boolean = false,
    _autoPopulateUserListIfBlank boolean = false,
    _callingUser text = '',
    _vialingConc text = null,
    _vialingVol text = null,
    _stagingLocation text = null,
    _requestIDForUpdate int = null,
    _logDebugMessages boolean = false,
    INOUT _resolvedInstrumentInfo text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds a new entry to the requested run table
**
**  Arguments:
**    _instrumentGroup               Instrument group; could also contain '(lookup)'
**    _workPackage                   Work package; could also contain '(lookup)'.  May contain 'none' for automatically created requested runs (and those will have _autoPopulateUserListIfBlank = true)
**    _batch                         When updating an existing requested run, if this is null or 0, the requested run will be removed from the batch
**    _block                         When updating an existing requested run, if this is null, Block will be set to 0
**    _runOrder                      When updating an existing requested run, if this is null, Run_Order will be set to 0
**    _eusUsersList                  EUS User ID (integer); also supports the form 'Baker, Erin (41136)'. Prior to February 2020, supported a comma separated list of EUS user IDs
**    _mode                          'add', 'check_add', 'update', 'check_update', or 'add-auto'
**    _secSep                        Separation group
**    _status                        'Active', 'Inactive', 'Completed'
**    _skipTransactionRollback       This is set to true when procedure add_update_dateset calls this procedure
**    _autoPopulateUserListIfBlank   When true, will auto-populate _eusUsersList if it is empty and _eusUsageType is 'USER', 'USER_ONSITE', or 'USER_REMOTE'
**    _requestIDForUpdate            Only used if _mode is 'update' or 'check_update' and only used if not 0 or null.  Can be used to rename an existing request
**    _resolvedInstrumentInfo        Output parameter that lists the the instrument group, run type, and separation group; used by AddRequestedRuns when previewing updates
**
**  Auth:   grk
**  Date:   01/11/2002
**          02/15/2003
**          12/05/2003 grk - added wellplate stuff
**          01/05/2004 grk - added internal standard stuff
**          03/01/2004 grk - added manual identity calculation (removed identity column)
**          03/10/2004 grk - repaired manual identity calculation to include history table
**          07/15/2004 grk - added verification of experiment location aux info
**          11/26/2004 grk - changed type of _comment from text to varchar
**          01/12/2004 grk - fixed null return on check existing when table is empty
**          10/12/2005 grk - Added stuff for new work package and proposal fields.
**          02/21/2006 grk - Added stuff for EUS proposal and user tracking.
**          11/09/2006 grk - Fixed error message handling (Ticket #318)
**          01/12/2007 grk - added verification mode
**          01/31/2007 grk - added verification for _requestorPRN (Ticket #371)
**          03/19/2007 grk - added _defaultPriority (Ticket #421) (set it back to 0 on 04/25/2007)
**          04/25/2007 grk - get new ID from UDF (Ticket #446)
**          04/30/2007 grk - added better name validation (Ticket #450)
**          07/11/2007 grk - factored out EUS proposal validation (Ticket #499)
**          07/11/2007 grk - modified to look up EUS fields from sample prep request (Ticket #499)
**          07/17/2007 grk - Increased size of comment field (Ticket #500)
**          07/30/2007 mem - Now checking dataset type (_msType) against Allowed_Dataset_Types in T_Instrument_Class (Ticket #502)
**          09/06/2007 grk - factored out instrument name and dataset type validation to ValidateInstrumentAndDatasetType (Ticket #512)
**          09/06/2007 grk - added call to LookupInstrumentRunInfoFromExperimentSamplePrep (Ticket #512)
**          09/06/2007 grk - Removed _specialInstructions (http://prismtrac.pnl.gov/trac/ticket/522)
**          02/13/2008 mem - Now checking for _badCh = 'space' (Ticket #602)
**          04/09/2008 grk - Added secondary separation field (Ticket #658)
**          03/26/2009 grk - Added MRM transition list attachment (Ticket #727)
**          06/03/2009 grk - look up work package (Ticket #739)
**          07/27/2009 grk - added lookup for wellplate and well fields (http://prismtrac.pnl.gov/trac/ticket/741)
**          02/28/2010 grk - added add-auto mode
**          03/02/2010 grk - added status field to requested run
**          03/10/2010 grk - fixed issue with status validation
**          03/27/2010 grk - fixed problem creating new requests with 'Completed' status.
**          04/20/2010 grk - fixed problem with experiment lookup validation
**          04/21/2010 grk - try-catch for error handling
**          05/05/2010 mem - Now calling auto_resolve_name_to_username to check if _requestorPRN contains a person's real name rather than their username
**          08/27/2010 mem - Now auto-switching _instrumentName to be instrument group instead of instrument name
**          09/01/2010 mem - Added parameter _skipTransactionRollback
**          09/09/2010 mem - Added parameter _autoPopulateUserListIfBlank
**          07/29/2011 mem - Now querying T_Requested_Run with both _requestName and _status when the mode is update or check_update
**          11/29/2011 mem - Tweaked warning messages when checking for existing request
**          12/05/2011 mem - Updated _transName to use a custom transaction name
**          12/12/2011 mem - Updated call to ValidateEUSUsage to treat _eusUsageType as an input/output parameter
**                         - Added parameter _callingUser, which is passed to alter_event_log_entry_user
**          12/19/2011 mem - Now auto-replacing &quot; with a double-quotation mark in _comment
**          01/09/2012 grk - Added _secSep to LookupInstrumentRunInfoFromExperimentSamplePrep
**          10/19/2012 mem - Now auto-updating secondary separation to separation group name when creating a new requested run
**          05/08/2013 mem - Added _vialingConc and _vialingVol
**          06/05/2013 mem - Now validating _workPackageNumber against T_Charge_Code
**          06/06/2013 mem - Now showing warning if the work package is deactivated
**          11/12/2013 mem - Added _requestIDForUpdate
**                         - Now auto-capitalizing _instrumentGroup
**          08/19/2014 mem - Now copying _instrumentName to _instrumentGroup during the initial validation
**          09/17/2014 mem - Now auto-updating _status to 'Active' if adding a request yet _status is null
**          06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**          02/23/2016 mem - Add set XACT_ABORT on
**          02/29/2016 mem - Now looking up setting for 'RequestedRunRequireWorkpackage' using T_MiscOptions
**          07/20/2016 mem - Tweak error message
**          11/16/2016 mem - Call update_cached_requested_run_eus_users to update T_Active_Requested_Run_Cached_EUS_Users
**          11/18/2016 mem - Log try/catch errors using PostLogEntry
**          12/05/2016 mem - Exclude logging some try/catch errors
**          12/16/2016 mem - Use _logErrors to toggle logging errors caught by the try/catch block
**          01/09/2017 mem - Add parameter _logDebugMessages
**          02/07/2017 mem - Change default for _logDebugMessages to false
**          06/13/2017 mem - Rename _operPRN to _requestorPRN
**                         - Make sure the Work Package is capitalized properly
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/12/2017 mem - Add _stagingLocation (points to T_Material_Locations)
**          06/12/2018 mem - Send _maxLength to AppendToText
**          08/06/2018 mem - Rename Operator PRN column to RDS_Requestor_PRN
**          09/03/2018 mem - Apply a maximum length restriction of 64 characters to _requestName when creating a new requested run
**          12/10/2018 mem - Report an error if the comment contains 'experiment_group/show/0000'
**          07/01/2019 mem - Allow _workPackage to be none if the Request is not active and either the Usage Type is Maintenance or the name starts with 'AutoReq_'
**          02/03/2020 mem - Raise an error if _eusUsersList contains multiple user IDs (since ERS only allows for a single user to be associated with a dataset)
**          10/19/2020 mem - Rename the instrument group column to instrument_group
**          12/08/2020 mem - Lookup Username from T_Users using the validated user ID
**          02/25/2021 mem - Use ReplaceCharacterCodes to replace character codes with punctuation marks
**                         - Use RemoveCrLf to replace linefeeds with semicolons
**          05/25/2021 mem - Append new messages to _message (including from LookupEUSFromExperimentSamplePrep)
**                         - Expand _message to varchar(1024)
**          05/26/2021 mem - Check for undefined EUS Usage Type (ID = 1)
**                     bcg - Bug fix: use _eusUsageTypeID to prevent use of EUS Usage Type 'Undefined'
**                     mem - When _mode is 'add', 'add-auto', or 'check_add', possibly override the EUSUsageType based on the campaign's EUS Usage Type
**          05/27/2021 mem - Refactor EUS Usage validation code into ValidateEUSUsage
**          05/31/2021 mem - Add output parameter _resolvedInstrumentInfo
**          06/01/2021 mem - Update the message stored in _resolvedInstrumentInfo
**          10/06/2021 mem - Add _batch, _block, and _runOrder
**          02/17/2022 mem - Update requestor username warning
**          05/23/2022 mem - Rename requester username argument and update username warning
**          11/25/2022 mem - Rename parameter to _wellplateName
**          12/08/2022 mem - Rename _instrumentName parameter to _instrumentGroup
**          02/10/2023 mem - Call update_cached_requested_run_batch_stats
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
    _msg text;
    _instrumentMatch text;
    _separationGroup text;
    _defaultPriority int;
    _currentBatch int := 0;
    _debugMsg text;
    _logErrors boolean := false;
    _raiseErrorOnMultipleEUSUsers boolean := true;
    _requestOrigin text := 'user';
    _badCh text;
    _nameLength int;
    _requestID int := 0;
    _oldRequestName text := '';
    _oldEusProposalID text := '';
    _oldStatus text := '';
    _matchFound boolean := false;
    _statusID int := 0;
    _experimentID int := 0;
    _userID int;
    _matchCount int;
    _newUsername text;
    _datasetTypeID int;
    _sepID int := 0;
    _matchedSeparationGroup text := '';
    _mrmAttachmentID int;
    _eusUsageTypeID Int;
    _addingItem boolean := false;
    _commaPosition int;
    _locationID int := null;
    _allowNoneWP boolean := _autoPopulateUserListIfBlank;
    _requireWP int := 1;
    _logMessage text;
    _msg text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode:= '';
    _resolvedInstrumentInfo := '';

    _separationGroup := _secSep;

    -- Default priority at which new requests will be created
    _defaultPriority := 0;

    _logDebugMessages := Coalesce(_logDebugMessages, false);

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        _mode := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Preliminary steps
        ---------------------------------------------------
        --
        If _mode = 'add-auto' Then
            _mode := 'add';
            _requestOrigin := 'auto';
        End If;

        ---------------------------------------------------
        -- Validate input fields
        ---------------------------------------------------

        If _logDebugMessages Then
            _debugMsg := 'Validate input fields';
            Call post_log_entry ('Debug', _debugMsg, 'AddUpdateRequestedRun');
        End If;

        If Coalesce(_requestName, '') = '' Then
            RAISE EXCEPTION 'Request name was blank';
        End If;
        --
        If Coalesce(_experimentName, '') = '' Then
            RAISE EXCEPTION 'Experiment number was blank';
        End If;
        --
        If Coalesce(_requesterUsername, '') = '' Then
            RAISE EXCEPTION 'Requester username was blank';
        End If;

        _instrumentGroup := _instrumentName;

        If Coalesce(_instrumentGroup, '') = '' Then
            RAISE EXCEPTION 'Instrument group was blank';
        End If;
        --
        If Coalesce(_msType, '') = '' Then
            RAISE EXCEPTION 'Dataset type was blank';
        End If;
        --
        If Coalesce(_workPackage, '') = '' Then
            RAISE EXCEPTION 'Work package was blank';
        End If;

        _requestIDForUpdate := Coalesce(_requestIDForUpdate, 0);

        -- Assure that _comment is not null and assure that it doesn't have &quot; or &#34; or &amp;
        _comment := dbo.ReplaceCharacterCodes(_comment);

        -- Replace instances of CRLF (or LF) with semicolons
        _comment := dbo.RemoveCrLf(_comment);

        If _comment like '%experiment_group/show/0000%' Then
            RAISE EXCEPTION 'Please reference a valid experiment group ID, not 0000';
        End If;

        If _comment like '%experiment_group/show/0%' Then
            RAISE EXCEPTION 'Please reference a valid experiment group ID';
        End If;

        _batch := Coalesce(_batch, 0);
        _block := Coalesce(_block, 0);
        _runOrder := Coalesce(_runOrder, 0);

        ---------------------------------------------------
        -- Validate name
        ---------------------------------------------------

        _badCh := public.validate_chars(_requestName, '');

        If _badCh <> '' Then
            If _badCh = 'space' Then
                RAISE EXCEPTION 'Requested run name may not contain spaces';
            Else
                RAISE EXCEPTION 'Requested run name may not contain the character(s) "%"', _badCh;
            End If;
        End If;

        _requestName := Trim(_requestName);

        _nameLength := char_length(_requestName);

        If _nameLength > 64 And _mode::citext In ('add', 'check_add') And _requestOrigin <> 'auto' Then
            RAISE EXCEPTION 'Requested run name is too long (% characters); max length is 64 characters', _nameLength;
        End If;

        ---------------------------------------------------
        -- Is entry already in database?
        --
        -- Note that if a request is recycled, the old and new requests
        -- will have the same name but different IDs
        --
        -- When _mode is 'update', we should first look for an existing request
        -- with name _requestName and status _status
        --
        -- If a match is not found, simply look for a request with the same name
        ---------------------------------------------------

        If _mode::citext In ('update', 'check_update') Then
            If _requestIDForUpdate > 0 Then
                SELECT request_name,
                       request_id,
                       eus_proposal_id,
                       state_name
                INTO _oldRequestName, _requestID, _oldEusProposalID, _oldStatus
                FROM t_requested_run
                WHERE request_id = _requestIDForUpdate;

                If FOUND Then
                    _matchFound := true;
                End If;

                If _oldRequestName <> _requestName Then
                    If _status <> 'Active' Then
                        RAISE EXCEPTION 'Requested run is not active; cannot rename: "%"', _oldRequestName;
                    End If;

                    If Exists (Select * from t_requested_run Where request_name = _requestName) Then
                        RAISE EXCEPTION 'Cannot rename "%" since new name already exists: "%"', _oldRequestName, _requestName;
                    End If;
                End If;

            Else
                SELECT request_name,
                       request_id,
                       eus_proposal_id,
                       state_name
                INTO _oldRequestName, _requestID, _oldEusProposalID, _oldStatus
                FROM t_requested_run
                WHERE request_name = _requestName AND
                      state_name = _status;

                If FOUND Then
                    _matchFound := true;
                End If;
            End If;
        End If;

        If Not _matchFound Then
            -- Match not found when filtering on Status
            -- Query again, but this time ignore state_name
            --
            SELECT request_name,
                   request_id,
                   eus_proposal_id,
                   state_name
            INTO _oldRequestName, _requestID, _oldEusProposalID, _oldStatus
            WHERE request_name = _requestName;

        End If;

        -- Need non-null request even if we are just checking
        --
        _request := _requestID;

        -- Cannot create an entry that already exists
        --
        If _requestID <> 0 and (_mode::citext In ('add', 'check_add')) Then
            RAISE EXCEPTION 'Cannot add: Requested Run "%" already in the database; cannot add', _requestName;
        End If;

        -- Cannot update a non-existent entry
        --
        If _requestID = 0 and (_mode::citext In ('update', 'check_update')) Then
            If _requestIDForUpdate > 0 Then
                RAISE EXCEPTION 'Cannot update: Requested Run ID "%" is not in the database; cannot update', _requestIDForUpdate;
            Else
                RAISE EXCEPTION 'Cannot update: Requested Run "%" is not in the database; cannot update', _requestName;
            End If;
        End If;

        ---------------------------------------------------
        -- Confirm that the new status value is valid
        ---------------------------------------------------
        --
        _status := Coalesce(_status, '');

        If _mode::citext In ('add', 'check_add') AND (_status::citext = 'Completed' OR _status = '') Then
            _status := 'Active';
        End If;
        --
        If _mode::citext In ('add', 'check_add') AND (NOT (_status::citext IN ('Active', 'Inactive', 'Completed'))) Then
            RAISE EXCEPTION 'Status "%" is not valid; must be Active, Inactive, or Completed', _status;
        End If;
        --
        If _mode::citext In ('update', 'check_update') AND (NOT (_status::citext IN ('Active', 'Inactive', 'Completed'))) Then
            RAISE EXCEPTION 'Status "%" is not valid; must be Active, Inactive, or Completed', _status;
        End If;
        --
        If _mode::citext In ('update', 'check_update') AND (_status::citext = 'Completed' AND _oldStatus::citext <> 'Completed' ) Then
            _msg := 'Cannot set status of request to "Completed" when existing status is "' || _oldStatus || '"';
            RAISE EXCEPTION '%', _msg;
        End If;
        --
        If _mode::citext In ('update', 'check_update') AND (_oldStatus::citext = 'Completed' AND _status::citext <> 'Completed') Then
            RAISE EXCEPTION 'Cannot change status of a request that has been consumed by a dataset';
        End If;

        If Coalesce(_wellplateName, '')::citext IN ('', 'na') Then
            _wellplateName := null;
        End If;

        If Coalesce(_wellNumber, '')::citext IN ('', 'na') Then
            _wellNumber := null;
        End If;

        SELECT state_id
        INTO _statusID
        FROM t_requested_run_state_name
        WHERE (state_name = _status)

        ---------------------------------------------------
        -- Get experiment ID from experiment number
        -- (and validate that it exists in database)
        -- Also set wellplate and well from experiment
        -- if called for
        ---------------------------------------------------

        SELECT exp_id,
               CASE WHEN _wellplateName = '(lookup)' THEN wellplate ELSE _wellplateName END,
               CASE WHEN _wellNumber = '(lookup)' THEN well ELSE _wellNumber END
        INTO _experimentID, _wellplateName, _wellNumber
        FROM t_experiments
        WHERE experiment = _experimentName
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;
        --
        If _experimentID = 0 Then
            RAISE EXCEPTION 'Could not find entry in database for experiment "%"', _experimentName;
        End If;

        ---------------------------------------------------
        -- Verify user ID for operator username
        ---------------------------------------------------

        If _logDebugMessages Then
            _debugMsg := 'Query get_user_id for ' || _requesterUsername;
            Call post_log_entry ('Debug', _debugMsg, 'AddUpdateRequestedRun');
        End If;

        _userID := public.get_user_id (_requesterUsername);

        If _userID > 0 Then
            -- Function get_user_id recognizes both a username and the form 'LastName, FirstName (Username)'
            -- Assure that _requesterUsername contains simply the username
            --
            SELECT username
            INTO _requesterUsername
            FROM t_users
            WHERE user_id = _userID;
        Else
            -- Could not find entry in database for username _requesterUsername
            -- Try to auto-resolve the name

            Call auto_resolve_name_to_username (_requesterUsername, _matchCount => _matchCount, _matchingUsername => _newUsername, _matchingUserID => _userID);

            If _matchCount = 1 Then
                -- Single match found; update _requesterUsername
                _requesterUsername := _newUsername;
            Else
                RAISE EXCEPTION 'Could not find entry in database for requester username "%"', _requesterUsername;
            End If;
        End If;

        ---------------------------------------------------
        -- Lookup instrument run info fields
        -- (only effective for experiments that have associated sample prep requests)
        ---------------------------------------------------

        If _logDebugMessages Then
            _debugMsg := 'LookupInstrumentRunInfoFromExperimentSamplePrep for ' || _experimentName;
            Call post_log_entry ('Debug', _debugMsg, 'AddUpdateRequestedRun');
        End If;

        Call lookup_instrument_run_info_from_experiment_sample_prep
                            _experimentName,
                            _instrumentGroup output,
                            _msType output,
                            _instrumentSettings output,
                            _separationGroup output,
                            _msg output
        If _returnCode <> '' Then
            RAISE EXCEPTION 'LookupInstrumentRunInfoFromExperimentSamplePrep: %', _msg;
        End If;

        ---------------------------------------------------
        -- Determine the Instrument Group
        ---------------------------------------------------

        If NOT EXISTS (SELECT * FROM t_instrument_group WHERE instrument_group = _instrumentGroup) Then
            -- Try to update instrument group using t_instrument_name
            SELECT instrument_group
            INTO _instrumentGroup
            FROM t_instrument_name
            WHERE instrument = _instrumentGroup
        End If;

        ---------------------------------------------------
        -- Validate instrument group and dataset type
        ---------------------------------------------------

        If _logDebugMessages Then
            _debugMsg := 'ValidateInstrumentGroupAndDatasetType for ' || _msType;
            Call post_log_entry ('Debug', _debugMsg, 'AddUpdateRequestedRun');
        End If;


        Call validate_instrument_group_and_dataset_type (
                        _datasetType => _msType,
                        _instrumentGroup => _instrumentGroup,           -- Output
                        _datasetTypeID => _datasetTypeID output,        -- Output
                        _message => _msg,                               -- Output
                        _returnCode => _returnCode);                    -- Output

        If _returnCode <> '' Then
            RAISE EXCEPTION 'ValidateInstrumentGroupAndDatasetType: %', _msg;
        End If;

        ---------------------------------------------------
        -- Resolve ID for _separationGroup
        -- First look in t_separation_group
        ---------------------------------------------------
        --
        If _logDebugMessages Then
            _debugMsg := 'Resolve separation group: ' || _separationGroup;
            Call post_log_entry ('Debug', _debugMsg, 'AddUpdateRequestedRun');
        End If;

        SELECT separation_group
        INTO _matchedSeparationGroup
        FROM t_separation_group
        WHERE separation_group = _separationGroup

        If Coalesce(_matchedSeparationGroup, '') <> '' Then
            _separationGroup := _matchedSeparationGroup;
        Else
            -- Match not found; try t_secondary_sep
            --
            SELECT separation_group
            INTO _matchedSeparationGroup
            FROM t_secondary_sep
            WHERE separation_type = _separationGroup
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;
            --
            If _sepID = 0 Then
                RAISE EXCEPTION 'Separation group not recognized';
            End If;

            If Coalesce(_matchedSeparationGroup, '') <> '' Then
                -- Auto-update _separationGroup to be _matchedSeparationGroup
                _separationGroup := _matchedSeparationGroup;
            End If;
        End If;

        ---------------------------------------------------
        -- Resolve ID for MRM attachment
        ---------------------------------------------------
        --
        --
        _mrmAttachment := Coalesce(_mrmAttachment, '');
        If _mrmAttachment <> '' Then
            SELECT attachment_id
            INTO _mrmAttachmentID
            FROM t_attachments
            WHERE attachment_name = _mrmAttachment
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        ---------------------------------------------------
        -- Lookup EUS field (only effective for experiments that have associated sample prep requests)
        -- This will update the data in _eusUsageType, _eusProposalID, or _eusUsersList if it is '(lookup)'
        ---------------------------------------------------

        If _logDebugMessages Then
            _debugMsg := 'Lookup EUS info for: ' || _experimentName;
            Call post_log_entry ('Debug', _debugMsg, 'AddUpdateRequestedRun');
        End If;
        --
        Call lookup_eus_from_experiment_sample_prep
                            _experimentName,
                            _eusUsageType output,
                            _eusProposalID output,
                            _eusUsersList output,
                            _msg output

        If _returnCode <> '' Then
            RAISE EXCEPTION 'LookupEUSFromExperimentSamplePrep: %', _msg;
        End If;

        If Coalesce(_msg, '') <> '' Then
            _message := public.append_to_text(_message, _msg, 0, '; ', 1024);
        End If;

        ---------------------------------------------------
        -- Validate EUS type, proposal, and user list
        ---------------------------------------------------

        If _logDebugMessages Then
            _debugMsg := 'Call ValidateEUSUsage with ' ||;
                'type ' || Coalesce(_eusUsageType, '?Null?') || ', ' ||
                'proposal ' || Coalesce(_eusProposalID, '?Null?') || ', and ' ||
                'user list ' || Coalesce(_eusUsersList, '?Null?')

            Call post_log_entry ('Debug', _debugMsg, 'AddUpdateRequestedRun');
        End If;

        -- Note that if _eusUsersList contains a list of names in the form 'Baker, Erin (41136)',
        -- ValidateEUSUsage will change this into a list of EUS user IDs (integers)

        If char_length(_eusUsersList) = 0 And _autoPopulateUserListIfBlank Then
            _raiseErrorOnMultipleEUSUsers := false;
        End If;

        If _mode::citext In ('add', 'check_add') Then
            _addingItem := true;
        End If;

        Call validate_eus_usage (
                        _eusUsageType   => _eusUsageType,       -- Input/Output
                        _eusProposalID  => _eusProposalID,      -- Input/Output
                        _eusUsersList   => _eusUsersList,       -- Input/Output
                        _eusUsageTypeID => _eusUsageTypeID,     -- Output
                        _message => _msg,                       -- Output
                        _returnCode => _returnCode,             -- Output
                        _autoPopulateUserListIfBlank,
                        _samplePrepRequest => false,
                        _experimentID => _experimentID,
                        _campaignID => 0,
                        _addingItem => _addingItem);

        If _returnCode <> '' Then
            _logErrors := false;
            RAISE EXCEPTION 'ValidateEUSUsage: %', _msg;
        End If;

        If _eusUsageTypeID = 1 Then
            RAISE EXCEPTION 'EUS Usage Type cannot be "undefined" for requested runs';
        End If;

        If Coalesce(_msg, '') <> '' Then
            _message := public.append_to_text(_message, _msg, 0, '; ', 1024);
        End If;

        _commaPosition := Position(',' In _eusUsersList);

        If _commaPosition > 1 Then
            _message := public.append_to_text('Requested runs can only have a single EUS user associated with them', _message, 0, '; ', 1024);

            If _raiseErrorOnMultipleEUSUsers Then
                RAISE EXCEPTION 'ValidateEUSUsage: %', _message;
            End If;

            -- Only keep the first user
            _eusUsersList := Left(_eusUsersList, _commaPosition - 1);
        End If;

        ---------------------------------------------------
        -- Lookup misc fields (only applies to experiments with sample prep requests)
        ---------------------------------------------------

        If _logDebugMessages Then
            _debugMsg := 'Lookup misc fields for the experiment';
            Call post_log_entry ('Debug', _debugMsg, 'AddUpdateRequestedRun');
        End If;

        Call lookup_other_from_experiment_sample_prep
                            _experimentName,
                            _workPackage output,
                            _msg output

        If _returnCode <> '' Then
            RAISE EXCEPTION 'LookupOtherFromExperimentSamplePrep: %', _msg;
        End If;

        ---------------------------------------------------
        -- Resolve staging location name to location ID
        ---------------------------------------------------

        If Coalesce(_stagingLocation, '') <> '' Then
            SELECT location_id
            INTO _locationID
            FROM t_material_locations
            WHERE location = _stagingLocation;
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;
            --
            If Coalesce(_locationID, 0) = 0 Then
                RAISE EXCEPTION 'Staging location not recognized';
            End If;
        End If;

        ---------------------------------------------------
        -- Validate the batch ID
        ---------------------------------------------------

        If Not Exists (Select * FROM t_requested_run_batches Where batch_id = _batch) Then
            If _mode Like '%update%' Then
                _mode := 'update';
            Else
                _mode := 'add';
            End If;

            RAISE EXCEPTION 'Cannot %: Batch ID "%" is not in the database', _mode, _batch;
        End If;

        ---------------------------------------------------
        -- Validate the work package
        ---------------------------------------------------

        If _logDebugMessages Then
            _debugMsg := 'Validate the WP';
            Call post_log_entry ('Debug', _debugMsg, 'AddUpdateRequestedRun');
        End If;

        SELECT public.try_cast(Value::text, false)
        INTO _requireWP
        FROM t_misc_options
        WHERE name = 'RequestedRunRequireWorkpackage'

        If Not _requireWP Then
            _allowNoneWP := true;
        End If;

        If _status <> 'Active' And (_eusUsageType = 'Maintenance' Or _requestName SIMILAR TO 'AutoReq[_]%') Then
            _allowNoneWP := true;
        End If;

        Call validate_wp ( _workPackageNumber,
                           _allowNoneWP,
                           _message => _msg,
                           _returnCode => _returnCode);

        If _returnCode <> '' Then
            RAISE EXCEPTION 'ValidateWP: %', _message;
        End If;

        -- Make sure the Work Package is capitalized properly
        --
        SELECT charge_code
        INTO _workPackage
        FROM t_charge_code
        WHERE charge_code = _workPackage

        If Not _autoPopulateUserListIfBlank Then
            If Exists (SELECT * FROM t_charge_code WHERE charge_code = _workPackage And deactivated = 'Y') Then
                _message := public.append_to_text(_message, 'Warning: Work Package ' || _workPackage || ' is deactivated', 0, '; ', 1024);
            ElsIf Exists (SELECT * FROM t_charge_code WHERE charge_code = _workPackage And charge_code_state = 0) Then
                _message := public.append_to_text(_message, 'Warning: Work Package ' || _workPackage || ' is likely deactivated', 0, '; ', 1024);
            End If;
        End If;

        _resolvedInstrumentInfo := 'instrument group ' || _instrumentGroup || ', run type ' || _msType || ', and separation group ' || _separationGroup;

        -- Validation checks are complete; now enable _logErrors
        _logErrors := true;

        If _logDebugMessages Then
            _debugMsg := 'Start a new transaction';
            Call post_log_entry ('Debug', _debugMsg, 'AddUpdateRequestedRun');
        End If;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------
        If _mode = 'add' Then

            -- Start transaction
            --
            INSERT INTO t_requested_run
            (
                request_name,
                requester_username,
                comment,
                created,
                instrument_group,
                request_type_id,
                instrument_setting,
                priority,
                exp_id,
                work_package,
                wellplate,
                well,
                request_internal_standard,
                batch_id,
                block,
                run_order,
                eus_proposal_id,
                eus_usage_type_id,
                separation_group,
                mrm_attachment,
                origin,
                state_name,
                vialing_conc,
                vialing_vol,
                location_id
            ) VALUES (
                _requestName,
                _requesterUsername,
                _comment,
                CURRENT_TIMESTAMP,
                _instrumentGroup,
                _datasetTypeID,
                _instrumentSettings,
                _defaultPriority, -- priority
                _experimentID,
                _workPackage,
                _wellplateName,
                _wellNumber,
                _internalStandard,
                _batch,
                _block,
                _runOrder,
                _eusProposalID,
                _eusUsageTypeID,
                _separationGroup,
                _mrmAttachmentID,
                _requestOrigin,
                _status,
                _vialingConc,
                _vialingVol,
                _locationId
            )
            RETURNING request_id
            INTO _request;

            -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
            If char_length(_callingUser) > 0 Then
                Call alter_event_log_entry_user (11, _request, _statusID, _callingUser);
            End If;

            If _logDebugMessages Then
                _debugMsg := 'Call assign_eus_users_to_requested_run';
                Call post_log_entry ('Debug', _debugMsg, 'AddUpdateRequestedRun');
            End If;

            -- Assign users to the request
            --
            Call assign_eus_users_to_requested_run
                                    _request,
                                    _eusProposalID,
                                    _eusUsersList,
                                    _msg output
            --
            If _returnCode <> '' Then
                RAISE EXCEPTION 'Assign_EUS_Users_To_Requested_Run: %', _msg;
            End If;

            If _logDebugMessages Then
                _debugMsg := 'Called assign_eus_users_to_requested_run';
                Call post_log_entry ('Debug', _debugMsg, 'AddUpdateRequestedRun');
            End If;

            If _status = 'Active' Then
                -- Add a new row to t_active_requested_run_cached_eus_users
                Call update_cached_requested_run_eus_users (
                        _request,
                        _message => _message,           -- Output
                        _returnCode => _returnCode);    -- Output
            End If;

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------
        --
        If _mode = 'update' Then

            SELECT batch_id
            INTO _currentBatch
            FROM t_requested_run
            WHERE request_id = _requestID;

            BEGIN

                UPDATE t_requested_run
                SET
                    request_name = CASE WHEN _requestIDForUpdate > 0 THEN _requestName ELSE request_name END,
                    requester_username = _requesterUsername,
                    comment = _comment,
                    instrument_group = _instrumentGroup,
                    request_type_id = _datasetTypeID,
                    instrument_setting = _instrumentSettings,
                    exp_id = _experimentID,
                    work_package = _workPackage,
                    wellplate = _wellplateName,
                    well = _wellNumber,
                    request_internal_standard = _internalStandard,
                    batch_id = _batch,
                    block = _block,
                    run_order = _runOrder,
                    eus_proposal_id = _eusProposalID,
                    eus_usage_type_id = _eusUsageTypeID,
                    separation_group = _separationGroup,
                    mrm_attachment = _mrmAttachmentID,
                    state_name = _status,
                    created = CASE WHEN _oldStatus = 'Inactive' AND _status = 'Active' THEN CURRENT_TIMESTAMP ELSE created END,
                    vialing_conc = _vialingConc,
                    vialing_vol = _vialingVol,
                    location_id = _locationId
                WHERE request_id = _requestID
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;

                -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
                If char_length(_callingUser) > 0 Then
                    Call alter_event_log_entry_user (11, _requestID, _statusID, _callingUser);
                End If;

                -- Assign users to the request
                --
                Call assign_eus_users_to_requested_run
                                        _requestID,
                                        _eusProposalID,
                                        _eusUsersList,
                                        _msg output
                --
                If _returnCode <> '' Then
                    RAISE EXCEPTION 'AssignEUSUsersToRequestedRun: %', _msg;
                End If;

            END;

            -- Make sure that t_active_requested_run_cached_eus_users is up-to-date
            Call update_cached_requested_run_eus_users (
                    _request,
                    _message => _message,           -- Output
                    _returnCode => _returnCode);    -- Output

            If _batch = 0 And _currentBatch <> 0 Then
                _msg := 'Removed request ' || Cast(_request As text) || ' from batch ' || Cast(_currentBatch As text);
                _message := public.append_to_text(_message, _msg, 0, '; ', 1024);
            End If;
        End If;

        ---------------------------------------------------
        -- Update stats in t_cached_requested_run_batch_stats
        ---------------------------------------------------

        If _batch > 0 Then
            Call update_cached_requested_run_batch_stats (
                    _batch,
                    _message => _msg,               -- Output
                    _returnCode => _returnCode);    -- Output

            If _returnCode <> '' Then
                _message := public.append_to_text(_message, _msg, 0, '; ', 1024);
            End If;
        End If;

        If _currentBatch > 0 Then
            Call update_cached_requested_run_batch_stats (
                    _currentBatch,
                    _message => _msg,               -- Output
                    _returnCode => _returnCode);    -- Output

            If _returnCode <> '' Then
                _message := public.append_to_text(_message, _msg, 0, '; ', 1024);
            End If;
        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _logMessage := format('%s; Request %s', _exceptionMessage, _requestName);

            _message := local_error_handler (
                            _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;

END
$$;

COMMENT ON PROCEDURE public.add_update_requested_run IS 'AddUpdateRequestedRun';

