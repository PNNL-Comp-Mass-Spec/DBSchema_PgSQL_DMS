--
-- Name: add_requested_run_fractions(integer, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, boolean, text, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_requested_run_fractions(IN _sourcerequestid integer, IN _separationgroup text DEFAULT 'LC-Formic_2hr'::text, IN _requesterusername text DEFAULT ''::text, IN _instrumentsettings text DEFAULT 'na'::text, IN _staginglocation text DEFAULT NULL::text, IN _wellplatename text DEFAULT ''::text, IN _wellnumber text DEFAULT ''::text, IN _vialingconc text DEFAULT NULL::text, IN _vialingvol text DEFAULT NULL::text, IN _comment text DEFAULT 'na'::text, IN _workpackage text DEFAULT ''::text, IN _eususagetype text DEFAULT ''::text, IN _eusproposalid text DEFAULT 'na'::text, IN _eususerid text DEFAULT ''::text, IN _mrmattachment text DEFAULT ''::text, IN _mode text DEFAULT 'add'::text, IN _autopopulateuserlistifblank boolean DEFAULT false, IN _callinguser text DEFAULT ''::text, IN _logdebugmessages boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add requested runs based on a parent requested run that has separation group LC-NanoHpH-6, LC-NanoSCX-6, or similar
**
**  Arguments:
**    _sourceRequestID              Source requested run ID
**    _separationGroup              Separation group of the fractionated requested runs that will be created
**    _requesterUsername            Requester username
**    _instrumentSettings           Instrument settings
**    _stagingLocation              Staging location
**    _wellplateName                Wellplate name; if '(lookup)', will look for a wellplate defined in T_Experiments
**    _wellNumber                   Well number;    if '(lookup)', will look for a well number defined in T_Experiments
**    _vialingConc                  Vialing concentration
**    _vialingVol                   Vialing volume
**    _comment                      Comment
**    _workPackage                  Work package; could also contain '(lookup)'. May contain 'none' for automatically created requested runs (and those will have _autoPopulateUserListIfBlank = true)
**    _eusUsageType                 EUS usage type;  if '(lookup)', override with the EUS info from the sample prep request (if found)
**    _eusProposalID                EUS proposal ID; if '(lookup)', override with the EUS info from the sample prep request (if found)
**    _eusUserID                    EUS User ID (integer); also supports the form "Baker, Erin (41136)"; can also be '(lookup)'; does not support 'Baker, Erin'
**    _mrmAttachment                MRM transition list file attachment
**    _mode                         Mode: 'add' or 'preview'
**    _autoPopulateUserListIfBlank  When true, auto-populate _eusUserID if it is empty and _eusUsageType is 'USER', 'USER_ONSITE', or 'USER_REMOTE'
**    _callingUser                  Calling user
**    _logDebugMessages             When true, log debug messages
**    _message                      Status message
**    _returnCode                   Return code
**
**  Auth:   mem
**  Date:   10/22/2020 mem - Initial Version
**          10/23/2020 mem - Set the Origin of the new requested runs to 'Fraction'
**          12/08/2020 mem - Lookup Username from T_Users using the validated user ID
**          02/25/2021 mem - Use Replace_Character_Codes to replace character codes with punctuation marks
**                         - Use Remove_Cr_Lf to replace linefeeds with semicolons
**          05/25/2021 mem - Append new messages to _message (including from Lookup_EUS_From_Experiment_Sample_Prep)
**                         - Expand _message to varchar(1024)
**          05/27/2021 mem - Specify _samplePrepRequest, _experimentID, _campaignID, and _addingItem when calling Validate_EUS_Usage
**          06/01/2021 mem - Add newly created requested run fractions to the parent request's batch (which will be 0 if not in a batch)
**                         - Raise an error if _mode is invalid
**          10/13/2021 mem - Append EUS User ID list to warning message
**                         - Do not call post_log_entry where _mode is 'preview'
**          10/22/2021 mem - Use a new instrument group for the new requested runs
**          11/15/2021 mem - If the the instrument group for the source request is the target instrument group instead of a fraction based group, auto update the source instrument group
**          01/15/2022 mem - Copy date created from the parent requested run to new requested runs, allowing Days in Queue on the list report to be based on the parent requested run's creation date
**          02/17/2022 mem - Update requestor username warning
**          05/23/2022 mem - Rename requester username argument and update username warning
**          10/13/2022 mem - Fix bug calling Lookup_EUS_From_Experiment_Sample_Prep
**          02/10/2023 mem - Call update_cached_requested_run_batch_stats
**          10/09/2023 mem - Ported to PostgreSQL
**          11/01/2023 mem - Add missing brackets when checking for '[space]' in the return value from validate_chars()
**          12/28/2023 mem - Use a variable for target type when calling alter_event_log_entry_user()
**          01/03/2024 mem - Update warning messages
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**          01/08/2024 mem - Remove procedure name from error message
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          05/17/2024 mem - Update column cached_wp_activation_state
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _msg text;
    _instrumentMatch text;
    _defaultPriority int;
    _debugMsg text;
    _logErrors boolean := false;
    _raiseErrorOnMultipleEUSUsers boolean := true;
    _sourceRequestName text := '';
    _sourceRequestBatchID int := 0;
    _instrumentGroup text;
    _targetInstrumentGroup text;
    _fractionBasedInstrumentGroup text := '';
    _msType text;
    _experimentID int;
    _sourceSeparationGroup text;
    _sourceStatus text;
    _sourceCreated timestamp;
    _status text;
    _experimentName text;
    _fractionCount int := 0;
    _targetGroupFractionCount int := 0;
    _mrmAttachmentID int;
    _fractionNumber int;
    _requestName citext;
    _requestID int;
    _requestIdList text := '';
    _firstRequest text;
    _lastRequest text;
    _badCh text;
    _nameLength int;
    _statusID int := 0;
    _userID int;
    _matchCount int;
    _newUsername text;
    _datasetTypeID int;
    _eusUsageTypeID int;
    _addingItem boolean := false;
    _commaPosition int;
    _locationID int := null;
    _allowNoneWP boolean := _autoPopulateUserListIfBlank;
    _requireWP boolean := true;
    _matchedWorkPackage citext := '';
    _workPackageActivationState smallint := 0;
    _targetType int;
    _alterEnteredByMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _logMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    -- Default priority at which new requests will be created
    _defaultPriority := 0;

    _logDebugMessages := Coalesce(_logDebugMessages, false);

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

        If _logDebugMessages Then
            _debugMsg := 'Validate input fields';
            CALL post_log_entry ('Debug', _debugMsg, 'Add_Requested_Run_Fractions');
        End If;

        If Coalesce(_sourceRequestID, 0) = 0 Then
            RAISE EXCEPTION 'Source request ID not specified';
        End If;

        If Coalesce(_requesterUsername, '') = '' Then
            RAISE EXCEPTION 'Requester username must be specified';
        End If;

        If Coalesce(_separationGroup, '') = '' Then
            RAISE EXCEPTION 'Separation group must be specified';
        End If;

        If Coalesce(_workPackage, '') = '' Then
            RAISE EXCEPTION 'Work package must be specified';
        End If;

        _mode := Trim(Lower(Coalesce(_mode, '')));

        If Not _mode::citext In ('add', 'preview') Then
            RAISE EXCEPTION 'Invalid mode: should be "add" or "preview", not "%"', _mode;
        End If;

        -- Assure that _comment is not null and assure that it doesn't have &quot; or &#34; or &amp;
        _comment := public.replace_character_codes(_comment);

        -- Replace instances of CRLF (or LF) with semicolons
        _comment := public.remove_cr_lf(_comment);

        If Coalesce(_wellplateName, '')::citext In ('', 'na') Then
            _wellplateName := null;
        End If;

        If Coalesce(_wellNumber, '')::citext In ('', 'na') Then
            _wellNumber := null;
        End If;

        _mrmAttachment := Trim(Coalesce(_mrmAttachment, ''));

        ---------------------------------------------------
        -- Create a temporary table to track the IDs of new requested runs
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_NewRequests (
            Fraction_Number int NOT NULL,
            Request_Name text NOT NULL,
            Request_ID int NULL
        );

        ---------------------------------------------------
        -- Lookup information from the source requested run
        ---------------------------------------------------

        SELECT RR.request_name,
               RR.instrument_group,
               DTN.Dataset_Type,
               RR.exp_id,
               RR.separation_group,
               RR.state_name,
               Coalesce(RR.batch_id, 0),
               RR.created
        INTO _sourceRequestName,
             _instrumentGroup,
             _msType,
             _experimentID,
             _sourceSeparationGroup,
             _sourceStatus,
             _sourceRequestBatchID,
             _sourceCreated
        FROM t_requested_run RR
             INNER JOIN t_dataset_type_name DTN
               ON RR.request_type_id = DTN.dataset_type_id
        WHERE RR.request_id = _sourceRequestID;

        If Not FOUND Then
            RAISE EXCEPTION 'Source request ID not found: %', _sourceRequestID;
        End If;

        _badCh := public.validate_chars(_sourceRequestName, '');

        If _badCh <> '' Then
            If _badCh = '[space]' Then
                RAISE EXCEPTION 'Source requested run name may not contain spaces';
            Else
                RAISE EXCEPTION 'Source requested run name may not contain the character(s) "%"', _badCh;
            End If;
        End If;

        If _sourceStatus <> 'Active' Then
            _requestName := format('%s_f01%%', _sourceRequestName);

            If Exists (SELECT request_id FROM t_requested_run WHERE request_name ILIKE _requestName) Then
                RAISE EXCEPTION 'Fraction-based requested runs have already been created for this requested run; nothing to do';
            Else
                RAISE EXCEPTION 'Source requested run is not active; cannot continue';
            End If;
        End If;

        _sourceRequestName := Trim(_sourceRequestName);
        _nameLength := char_length(_sourceRequestName);

        If _nameLength > 64 Then
            RAISE EXCEPTION 'Requested run name is too long (% characters); max length is 64 characters', _nameLength;
        End If;

        If Coalesce(_instrumentGroup, '') = '' Then
            RAISE EXCEPTION 'Source request does not have an instrument group defined';
        End If;

        If Coalesce(_msType, '') = '' Then
            RAISE EXCEPTION 'Source request does not have an dataset type defined';
        End If;

        ---------------------------------------------------
        -- Lookup StatusID
        ---------------------------------------------------

        _status := 'Active';

        SELECT state_id
        INTO _statusID
        FROM t_requested_run_state_name
        WHERE state_name = _status::citext;

        ---------------------------------------------------
        -- Validate that the experiment exists
        -- Lookup wellplate and well number if either is (lookup)
        ---------------------------------------------------

        SELECT Experiment,
               CASE WHEN _wellplateName = '(lookup)' THEN wellplate
                    ELSE _wellplateName
               END,
               CASE WHEN _wellNumber = '(lookup)' THEN well
                    ELSE _wellNumber
               END
        INTO _experimentName, _wellplateName, _wellNumber
        FROM t_experiments
        WHERE exp_id = _experimentID;

        If Not FOUND Then
            RAISE EXCEPTION 'Invalid experiment: ID % does not exist', _experimentID;
        End If;

        ---------------------------------------------------
        -- Verify user ID for operator username
        ---------------------------------------------------

        If _logDebugMessages Then
            _debugMsg := format('CALL get_user_id for %s', _requesterUsername);
            CALL post_log_entry ('Debug', _debugMsg, 'Add_Requested_Run_Fractions');
        End If;

        _userID := public.get_user_id(_requesterUsername);

        If _userID > 0 Then
            -- Function get_user_id() recognizes both a username and the form 'LastName, FirstName (Username)'
            -- Assure that _requesterUsername contains simply the username

            SELECT username
            INTO _requesterUsername
            FROM t_users
            WHERE user_id = _userID;
        Else
            -- Could not find entry in database for _requesterUsername
            -- Try to auto-resolve the name

            CALL public.auto_resolve_name_to_username (
                            _requesterUsername,
                            _matchCount       => _matchCount,   -- Output
                            _matchingUsername => _newUsername,  -- Output
                            _matchingUserID   => _userID);      -- Output

            If _matchCount = 1 Then
                -- Single match found; update _requesterUsername
                _requesterUsername := _newUsername;
            Else
                If _matchCount = 0 Then
                    RAISE EXCEPTION 'Invalid requester username: "%" does not exist', _requesterUsername;
                Else
                    RAISE EXCEPTION 'Invalid requester username: "%" matches more than one user', _requesterUsername;
                End If;
            End If;
        End If;

        ---------------------------------------------------
        -- Determine the instrument group to use for the new requested runs
        ---------------------------------------------------

        SELECT target_instrument_group
        INTO _targetInstrumentGroup
        FROM t_instrument_group
        WHERE instrument_group = _instrumentGroup::citext;

        If Not FOUND Then
            RAISE EXCEPTION 'Invalid instrument group: "%" does not exist', _instrumentGroup;
        End If;

        If Coalesce(_targetInstrumentGroup, '') = '' Then
            -- If the user specified the target group instead of the instrument group that ends with _Frac, auto change things
            SELECT instrument_group
            INTO _fractionBasedInstrumentGroup
            FROM t_instrument_group
            WHERE target_instrument_group = _instrumentGroup::citext;

            If FOUND Then
                _instrumentGroup := _fractionBasedInstrumentGroup;

                SELECT target_instrument_group
                INTO _targetInstrumentGroup
                FROM t_instrument_group
                WHERE instrument_group = _instrumentGroup::citext;
            End If;
        End If;

        If Coalesce(_targetInstrumentGroup, '') = '' Then
            RAISE EXCEPTION 'Instrument group "%" does not have a valid target instrument group defined; contact a DMS admin', _instrumentGroup;
        End If;

        ---------------------------------------------------
        -- Validate instrument group and dataset type
        ---------------------------------------------------

        If _logDebugMessages Then
            _debugMsg := format('Call validate_instrument_group_and_dataset_type for %s', _msType);
            CALL post_log_entry ('Debug', _debugMsg, 'Add_Requested_Run_Fractions');
        End If;

        CALL public.validate_instrument_group_and_dataset_type (
                        _datasetType     => _msType,
                        _instrumentGroup => _targetInstrumentGroup,     -- Output
                        _datasetTypeID   => _datasetTypeID,             -- Output
                        _message         => _msg,                       -- Output
                        _returnCode      => _returnCode);               -- Output

        If _returnCode <> '' Then
            RAISE EXCEPTION '%', _msg;
        End If;

        ---------------------------------------------------
        -- Examine the fraction count of the source separation group
        ---------------------------------------------------

        If _logDebugMessages Then
            _debugMsg := format('Examine fraction counts of source and target separation groups: %s and %s', _sourceSeparationGroup, _separationGroup);
            CALL post_log_entry ('Debug', _debugMsg, 'Add_Requested_Run_Fractions');
        End If;

        SELECT fraction_count
        INTO _fractionCount
        FROM t_separation_group
        WHERE separation_group = _sourceSeparationGroup::citext;

        If Not FOUND Then
            RAISE EXCEPTION 'Separation group of the source request not found: %', _sourceSeparationGroup;
        End If;

        If _fractionCount = 0 Then
            RAISE EXCEPTION 'Source request separation group should be fraction-based (LC-NanoHpH, LC-NanoSCX, etc.); % is invalid', _sourceSeparationGroup;
        End If;

        ---------------------------------------------------
        -- Examine the fraction count of the separation group for the new requested runs
        -- The target group should not be fraction based
        ---------------------------------------------------

        SELECT fraction_count
        INTO _targetGroupFractionCount
        FROM t_separation_group
        WHERE separation_group = _separationGroup::citext;

        If Not FOUND Then
            RAISE EXCEPTION 'Separation group not found: %', _separationGroup;
        End If;

        If _targetGroupFractionCount > 0 Then
            RAISE EXCEPTION 'Separation group for the new requested runs (%) has a non-zero fraction count value (%); this is not allowed', _separationGroup, _targetGroupFractionCount;
        End If;

        ---------------------------------------------------
        -- Resolve ID for MRM attachment
        ---------------------------------------------------

        If _mrmAttachment <> '' Then
            SELECT attachment_id
            INTO _mrmAttachmentID
            FROM t_attachments
            WHERE attachment_name = _mrmAttachment::citext;
        End If;

        ---------------------------------------------------
        -- Lookup EUS field (only effective for experiments that have associated sample prep requests)
        -- This will update the data in _eusUsageType, _eusProposalID, or _eusUserID if it is '(lookup)'
        ---------------------------------------------------

        If _logDebugMessages Then
            _debugMsg := format('Lookup EUS info for experiment %s', _experimentName);
            CALL post_log_entry ('Debug', _debugMsg, 'Add_Requested_Run_Fractions');
        End If;

        CALL public.lookup_eus_from_experiment_sample_prep (
                            _experimentName,
                            _eusUsageType  => _eusUsageType,    -- Input/output
                            _eusProposalID => _eusProposalID,   -- Input/output
                            _eusUsersList  => _eusUserID,       -- Input/output
                            _message       => _msg,             -- Output
                            _returnCode    => _returnCode);     -- Output

        If _returnCode <> '' Then
            RAISE EXCEPTION '%', _msg;
        End If;

        If Coalesce(_msg, '') <> '' Then
            _message := public.append_to_text(_message, _msg);
        End If;

        ---------------------------------------------------
        -- Validate EUS type, proposal, and user list
        ---------------------------------------------------

        If _logDebugMessages Then
            _debugMsg := format('Call validate_eus_usage with type %s, proposal %s, and user list %s',
                                Coalesce(_eusUsageType, '?Null?'),
                                Coalesce(_eusProposalID, '?Null?'),
                                Coalesce(_eusUserID, '?Null?'));

            CALL post_log_entry ('Debug', _debugMsg, 'Add_Requested_Run_Fractions');
        End If;

        -- Note that if _eusUserID contains a list of names in the form "Baker, Erin (41136)",
        -- Validate_EUS_Usage will change this into a list of EUS user IDs (integers)

        If Trim(Coalesce(_eusUserID, '')) = '' And _autoPopulateUserListIfBlank Then
            _raiseErrorOnMultipleEUSUsers := false;
        End If;

        If _mode = 'add' Then
            _addingItem := true;
        End If;

        CALL public.validate_eus_usage (
                        _eusUsageType      => _eusUsageType,        -- Input/Output
                        _eusProposalID     => _eusProposalID,       -- Input/Output
                        _eusUsersList      => _eusUserID,           -- Input/Output
                        _eusUsageTypeID    => _eusUsageTypeID,      -- Output
                        _autoPopulateUserListIfBlank => _autoPopulateUserListIfBlank,
                        _samplePrepRequest => false,
                        _experimentID      => _experimentID,
                        _campaignID        => 0,
                        _addingItem        => _addingItem,
                        _infoOnly          => false,
                        _message           => _msg,                  -- Output
                        _returnCode        => _returnCode            -- Output
                    );

        If _returnCode <> '' Then
            RAISE EXCEPTION '%', _msg;
        End If;

        If Coalesce(_msg, '') <> '' Then
            _message := public.append_to_text(_message, _msg);
        End If;

        _commaPosition := Position(',' In _eusUserID);

        If _commaPosition > 1 Then
            _msg := format('Requested runs can only have a single EUS user associated with them; current list: %s', _eusUserID);
            _message := public.append_to_text(_msg, _message);

            If _raiseErrorOnMultipleEUSUsers Then
                RAISE EXCEPTION '%', _message;
            End If;

            -- Only keep the first user
            _eusUserID := Trim(Left(_eusUserID, _commaPosition - 1));
        End If;

        ---------------------------------------------------
        -- Lookup misc fields (only applies to experiments with sample prep requests)
        ---------------------------------------------------

        If _logDebugMessages Then
            _debugMsg := 'Lookup misc fields for the experiment';
            CALL post_log_entry ('Debug', _debugMsg, 'Add_Requested_Run_Fractions');
        End If;

        CALL public.lookup_wp_from_experiment_sample_prep(
                            _experimentName,
                            _workPackage => _workPackage,   -- Input/Output
                            _message     => _msg,           -- Output
                            _returnCode  => _returnCode);   -- Output

        If _returnCode <> '' Then
            RAISE EXCEPTION '%', _msg;
        End If;

        ---------------------------------------------------
        -- Resolve staging location name to location ID
        ---------------------------------------------------

        If Coalesce(_stagingLocation, '') <> '' Then
            SELECT location_id
            INTO _locationID
            FROM t_material_locations
            WHERE location = _stagingLocation::citext;

            If Not FOUND Then
                RAISE EXCEPTION 'Staging location not recognized';
            End If;

        End If;

        ---------------------------------------------------
        -- Validate the work package
        ---------------------------------------------------

        If _logDebugMessages Then
            _debugMsg := 'Validate the WP';
            CALL post_log_entry ('Debug', _debugMsg, 'Add_Requested_Run_Fractions');
        End If;

        -- Value should be a 0 or a 1
        -- Cast to text, then cast to boolean

        SELECT public.try_cast(Value::text, false)
        INTO _requireWP
        FROM t_misc_options
        WHERE name = 'RequestedRunRequireWorkpackage';

        If Not _requireWP Then
            _allowNoneWP := true;
        End If;

        CALL public.validate_wp (
                        _workPackage,
                        _allowNoneWP,
                        _message    => _msg,            -- Output
                        _returnCode => _returnCode);    -- Output

        If _returnCode <> '' Then
            RAISE EXCEPTION '%', _msg;
        End If;

        -- Make sure the Work Package is capitalized properly

        SELECT charge_code, activation_state
        INTO _matchedWorkPackage, _workPackageActivationState
        FROM t_charge_code
        WHERE charge_code = _workPackage::citext;

        If FOUND Then
            _workPackage := _matchedWorkPackage;
        Else
            _workPackageActivationState := 0;
        End If;

        If Not _autoPopulateUserListIfBlank Then
            If Exists (SELECT charge_code FROM t_charge_code WHERE charge_code = _workPackage::citext AND deactivated = 'Y') Then
                _message := public.append_to_text(_message, format('Warning: Work Package %s is deactivated', _workPackage));
            ElsIf Exists (SELECT charge_code FROM t_charge_code WHERE charge_code = _workPackage::citext AND charge_code_state = 0) Then
                _message := public.append_to_text(_message, format('Warning: Work Package %s is likely deactivated', _workPackage));
            End If;
        End If;

        If _mode <> 'preview' Then
            -- Validation checks are complete; now enable _logErrors
            _logErrors := true;
        End If;

        If _logDebugMessages Then
            _debugMsg := 'Check for name conflicts';
            CALL post_log_entry ('Debug', _debugMsg, 'Add_Requested_Run_Fractions');
        End If;

        ---------------------------------------------------
        -- Make sure none of the new requested runs will conflict with an existing requested run
        ---------------------------------------------------

        _fractionNumber := 1;
        WHILE _fractionNumber <= _fractionCount
        LOOP
            If _fractionNumber < 10 Then
                _requestName := format('%s_f0%s', _sourceRequestName, _fractionNumber);
            Else
                _requestName := format('%s_f%s',  _sourceRequestName, _fractionNumber);
            End If;

            SELECT request_id
            INTO _requestID
            FROM t_requested_run
            WHERE request_name = _requestName::citext;

            If FOUND Then
                RAISE EXCEPTION 'Name conflict: a requested run named % already exists, ID %', _requestName, _requestID;
            End If;

            INSERT INTO Tmp_NewRequests (Fraction_Number, Request_Name)
            VALUES (_fractionNumber, _requestName);

            _fractionNumber := _fractionNumber + 1;
        END LOOP;

        ---------------------------------------------------
        -- Action for preview mode
        ---------------------------------------------------

        If _mode = 'preview' Then
            If _logDebugMessages Then
                _debugMsg := 'Create preview message';
                CALL post_log_entry ('Debug', _debugMsg, 'Add_Requested_Run_Fractions');
            End If;

            SELECT Request_Name
            INTO _firstRequest
            FROM Tmp_NewRequests
            ORDER BY Fraction_Number
            LIMIT 1;

            SELECT Request_Name
            INTO _lastRequest
            FROM Tmp_NewRequests
            ORDER BY Fraction_Number DESC
            LIMIT 1;

            _msg := format('Would create %s requested runs named %s ... %s with instrument group %s and separation group %s',
                           _fractionCount, _firstRequest, _lastRequest, _targetInstrumentGroup, _separationGroup);

            _message := public.append_to_text(_msg, _message);
        End If;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            If _logDebugMessages Then
                _debugMsg := 'Start a new transaction';
                CALL post_log_entry ('Debug', _debugMsg, 'Add_Requested_Run_Fractions');
            End If;

            If char_length(Coalesce(_fractionBasedInstrumentGroup, '')) > 0 Then
                -- Fix the instrument group name in the source requested run
                UPDATE t_requested_run
                SET instrument_group = _fractionBasedInstrumentGroup
                WHERE request_id = _sourceRequestID;
            End If;

            _fractionNumber := 1;

            WHILE _fractionNumber <= _fractionCount
            LOOP
                SELECT Request_Name
                INTO _requestName
                FROM Tmp_NewRequests
                WHERE Fraction_Number = _fractionNumber;

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
                    cached_wp_activation_state,
                    batch_id,
                    wellplate,
                    well,
                    request_internal_standard,
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
                    _sourceCreated,
                    _targetInstrumentGroup,
                    _datasetTypeID,
                    _instrumentSettings,
                    _defaultPriority,
                    _experimentID,
                    _workPackage,
                    _workPackageActivationState,
                    _sourceRequestBatchID,
                    _wellplateName,
                    _wellNumber,
                    'none',             -- Requested run internal standard
                    _eusProposalID,
                    _eusUsageTypeID,
                    _separationGroup,
                    _mrmAttachmentID,
                    'fraction',
                    _status,
                    _vialingConc,
                    _vialingVol,
                    _locationId
                )
                RETURNING request_id
                INTO _requestID;

                UPDATE Tmp_NewRequests
                SET Request_ID = _requestID
                WHERE Request_Name = _requestName::citext;

                -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
                If Trim(Coalesce(_callingUser, '')) <> '' Then
                    _targetType := 11;
                    CALL public.alter_event_log_entry_user ('public', _targetType, _requestID, _statusID, _callingUser, _message => _alterEnteredByMessage);
                End If;

                If _logDebugMessages Then
                    _debugMsg := 'CALL assign_eus_users_to_requested_run';
                    CALL post_log_entry ('Debug', _debugMsg, 'Add_Requested_Run_Fractions');
                End If;

                -- Assign users to the request

                CALL public.assign_eus_users_to_requested_run (
                                        _requestID,
                                        _eusUserID,                     -- Integer, stored as text
                                        _message    => _msg,            -- Output
                                        _returnCode => _returnCode);    -- Output

                If _returnCode <> '' Then
                    RAISE EXCEPTION '%', _msg;
                End If;

                -- Append the new request ID to _requestIdList

                If _requestIdList = '' Then
                    _requestIdList := _requestID;
                Else
                    _requestIdList := format('%s, %s', _requestIdList, _requestID);
                End If;

                -- Increment the fraction

                _fractionNumber := _fractionNumber + 1;

            END LOOP;

            UPDATE t_requested_run
            SET state_name = 'Completed'
            WHERE request_id = _sourceRequestID;

            If _logDebugMessages Then
                _debugMsg := 'Fractions created';
                CALL post_log_entry ('Debug', _debugMsg, 'Add_Requested_Run_Fractions');
            End If;

            ---------------------------------------------------
            -- Add new rows to t_active_requested_run_cached_eus_users
            -- We are doing this outside of the above transaction
            ---------------------------------------------------

            FOR _requestID IN
                SELECT Request_ID
                FROM Tmp_NewRequests
                ORDER BY Request_ID
            LOOP
                CALL public.update_cached_requested_run_eus_users (
                                _requestID,
                                _message    => _message,        -- Output
                                _returnCode => _returnCode);    -- Output

            END LOOP;

            ---------------------------------------------------
            -- Update stats in t_cached_requested_run_batch_stats
            ---------------------------------------------------

            If _sourceRequestBatchID > 0 Then
                CALL public.update_cached_requested_run_batch_stats (
                                _sourceRequestBatchID,
                                _fullRefresh => false,
                                _message     => _msg,            -- Output
                                _returnCode  => _returnCode);    -- Output

                If _returnCode <> '' Then
                    _message := public.append_to_text(_message, _msg);
                End If;
            End If;

            _msg := format('Created new requested runs based on source request %s creating: %s', _sourceRequestID, _requestIdList);
            _message := public.append_to_text(_msg, _message);

            CALL post_log_entry ('Normal', _message, 'Add_Requested_Run_Fractions');

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _logMessage := format('%s; Source Request ID %s', _exceptionMessage, _sourceRequestID);

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

    DROP TABLE IF EXISTS Tmp_NewRequests;
END
$$;


ALTER PROCEDURE public.add_requested_run_fractions(IN _sourcerequestid integer, IN _separationgroup text, IN _requesterusername text, IN _instrumentsettings text, IN _staginglocation text, IN _wellplatename text, IN _wellnumber text, IN _vialingconc text, IN _vialingvol text, IN _comment text, IN _workpackage text, IN _eususagetype text, IN _eusproposalid text, IN _eususerid text, IN _mrmattachment text, IN _mode text, IN _autopopulateuserlistifblank boolean, IN _callinguser text, IN _logdebugmessages boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_requested_run_fractions(IN _sourcerequestid integer, IN _separationgroup text, IN _requesterusername text, IN _instrumentsettings text, IN _staginglocation text, IN _wellplatename text, IN _wellnumber text, IN _vialingconc text, IN _vialingvol text, IN _comment text, IN _workpackage text, IN _eususagetype text, IN _eusproposalid text, IN _eususerid text, IN _mrmattachment text, IN _mode text, IN _autopopulateuserlistifblank boolean, IN _callinguser text, IN _logdebugmessages boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_requested_run_fractions(IN _sourcerequestid integer, IN _separationgroup text, IN _requesterusername text, IN _instrumentsettings text, IN _staginglocation text, IN _wellplatename text, IN _wellnumber text, IN _vialingconc text, IN _vialingvol text, IN _comment text, IN _workpackage text, IN _eususagetype text, IN _eusproposalid text, IN _eususerid text, IN _mrmattachment text, IN _mode text, IN _autopopulateuserlistifblank boolean, IN _callinguser text, IN _logdebugmessages boolean, INOUT _message text, INOUT _returncode text) IS 'AddRequestedRunFractions';

