--
CREATE OR REPLACE PROCEDURE public.add_update_sample_prep_request
(
    _requestName text,
    _requesterUsername text,
    _reason text,
    _materialContainerList text,
    _organism text,
    _biohazardLevel text,
    _campaign text,
    _numberofSamples int,
    _sampleNameList text,
    _sampleType text,
    _prepMethod text,
    _sampleNamingConvention text,
    _assignedPersonnel text,
    _requestedPersonnel text,
    _estimatedPrepTimeDays int,
    _estimatedMSRuns text,
    _workPackageNumber text,
    _eusProposalID text,
    _eusUsageType text,
    _eusUserID int,
    _instrumentGroup text,
    _datasetType text,
    _instrumentAnalysisSpecifications text,
    _comment text,
    _priority text,
    _state text,
    _stateComment text,
    INOUT _id int,
    _separationGroup text,
    _blockAndRandomizeSamples text,
    _blockAndRandomizeRuns text,
    _reasonForHighPriority text,
    _tissue text = '',
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
**      Adds new or edits existing Sample Prep Request
**
**  Arguments:
**    _eusUserID                  Use Null or 0 if no EUS User ID
**    _instrumentGroup            Will typically contain an instrument group name; could also contain 'None' or any other text
**    _state                      New, On Hold, Prep in Progress, Prep Complete, or Closed
**    _id                         Input/output: Sample prep request ID
**    _separationGroup            Separation group
**    _blockAndRandomizeSamples   'Yes', 'No', or 'na'
**    _blockAndRandomizeRuns      'Yes' or 'No'
**    _mode                       'add' or 'update'
**
**  Auth:   grk
**  Date:   06/09/2005
**          06/10/2005 grk - added Reason argument
**          06/16/2005 grk - added state restriction for update
**          07/26/2005 grk - added stuff for requested personnel
**          08/09/2005 grk - widened _sampleNameList
**          10/12/2005 grk - added _useSingleLCColumn
**          10/26/2005 grk - disallowed change if not in 'New" state
**          10/28/2005 grk - added handling for internal standard
**          11/01/2005 grk - rescinded disallowed change in 'New' state
**          11/11/2005 grk - added handling for postdigest internal standard
**          01/03/2006 grk - added check for existing request name
**          03/14/2006 grk - added stuff for multiple assigned users
**          08/10/2006 grk - modified state handling
**          08/10/2006 grk - allowed multiple requested personnel users
**          12/15/2006 grk - added EstimatedMSRuns argument (Ticket #336)
**          04/20/2007 grk - added validation for organism, campaign, cell culture (Ticket #440)
**          07/11/2007 grk - added 'standard' EUS fields and removed old proposal field(Ticket #499)
**          07/30/2007 grk - corrected error in update of EUS fields (Ticket #499)
**          09/01/2007 grk - added instrument name and datasets type fields (Ticket #512)
**          09/04/2007 grk - added _technicalReplicates fields (Ticket #512)
**          05/02/2008 grk - repaired leaking query and arranged for default add state to be 'Pending Approval'
**          05/16/2008 mem - Added optional parameter _callingUser; if provided, will populate field System_Account in T_Sample_Prep_Request_Updates with this name (Ticket #674)
**          12/02/2009 grk - don't allow change to 'Prep in Progress' unless someone has been assigned
**          04/14/2010 grk - widened _biomaterialList field
**          04/22/2010 grk - try-catch for error handling
**          08/09/2010 grk - added handling for 'Closed (containers and material)'
**          08/15/2010 grk - widened _biomaterialList field
**          08/27/2010 mem - Now auto-switching _instrumentName to be instrument group instead of instrument name
**          08/15/2011 grk - added Separation_Type
**          12/12/2011 mem - Updated call to ValidateEUSUsage to treat _eusUsageType as an input/output parameter
**          10/19/2012 mem - Now auto-changing _separationType to Separation_Group if _separationType specifies a separation type
**          04/05/2013 mem - Now requiring that _estimatedMSRuns be defined.  If it is non-zero, instrument group, dataset type, and separation group must also be defined
**          04/08/2013 grk - Added _blockAndRandomizeSamples, _blockAndRandomizeRuns, and _iOPSPermitsCurrent
**          04/09/2013 grk - disregarding internal standards
**          04/09/2013 grk - changed priority to text "Normal/High", added _numberOfBiomaterialRepsReceived, removed Facility field
**          04/09/2013 mem - Renamed parameter _instrumentName to _instrumentGroup
**                         - Renamed parameter _separationType to _separationGroup
**          05/02/2013 mem - Now validating that fields _blockAndRandomizeSamples, _blockAndRandomizeRuns, and _iOPSPermitsCurrent are 'Yes', 'No', '', or Null
**          06/05/2013 mem - Now validating _workPackageNumber against T_Charge_Code
**          06/06/2013 mem - Now showing warning if the work package is deactivated
**          01/23/2014 mem - Now requiring that the work package be active when creating a new sample prep requeset
**          03/13/2014 grk - Added ability to edit closed SPR for staff with permissions (OMCDA-1071)
**          05/19/2014 mem - Now populating Request_Type
**          05/20/2014 mem - Now storing InstrumentGroup in column Instrument_Group instead of Instrument_Name
**          03/13/2014 grk - Added material container field (OMCDA-1076)
**          05/29/2015 mem - Now validating that _estimatedCompletionDate is today or later
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          11/18/2016 mem - Log try/catch errors using PostLogEntry
**          12/05/2016 mem - Exclude logging some try/catch errors
**          12/16/2016 mem - Use _logErrors to toggle logging errors caught by the try/catch block
**          06/12/2017 mem - Remove 9 deprecated parameters:
**                             _biomaterialList, _numberOfBiomaterialRepsReceived, _replicatesofSamples, _prepByRobot,
**                             _technicalReplicates, _specialInstructions, _useSingleLCColumn, _projectNumber, and _iOPSPermitsCurrent
**                         - Change the default state from 'Pending Approval' to 'New'
**                         - Validate list of Requested Personnel and Assigned Personnel
**                         - Expand _comment to varchar(2048)
**          06/13/2017 mem - Validate _priority
**                         - Check for name collisions when _mode is update
**                         - Use SCOPE_IDENTITY
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/25/2017 mem - Add parameter _tissue (tissue name, e.g. hypodermis)
**          09/01/2017 mem - Allow _tissue to be a BTO ID (e.g. BTO:0000131)
**          06/12/2018 mem - Send _maxLength to append_to_text
**          08/22/2018 mem - Change the EUS User parameter from a varchar(1024) to an integer
**          08/29/2018 mem - Remove call to DoSamplePrepMaterialOperation since we stopped associating biomaterial (cell cultures) with Sample Prep Requests in June 2017
**          11/30/2018 mem - Make _reason an input/output parameter
**          01/23/2019 mem - Switch _reason back to a normal input parameter since view V_Sample_Prep_Request_Entry now appends the __NoCopy__ flag to several fields
**          01/13/2020 mem - Require _requestedPersonnel to include a sample prep staff member (no longer allow 'na' or 'any')
**          08/12/2020 mem - Check for ValidateEUSUsage returning a message, even if it returns 0
**          09/15/2020 mem - Use 'https://dms2.pnl.gov/' instead of http://
**          05/25/2021 mem - Set _samplePrepRequest to 1 when calling ValidateEUSUsage
**          05/26/2021 mem - Override _eusUsageType if _mode is 'add' and the campaign has EUSUsageType = 'USER_REMOTE
**          05/27/2021 mem - Refactor EUS Usage validation code into ValidateEUSUsage
**          06/10/2021 mem - Add parameters _estimatedPrepTimeDays and _stateComment
**          06/11/2021 mem - Auto-remove 'na' from _assignedPersonnel
**          10/11/2021 mem - Clear _stateComment when _state is 'Closed'
**                         - Only allow sample prep staff to update estimated prep time
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          12/03/2021 mem - Clear _stateComment when creating a new prep request
**          03/21/2022 mem - Refactor personnel validation code into ValidateRequestUsers
**          04/11/2022 mem - Check for whitespace in _requestName
**          04/18/2022 mem - Replace tabs in prep request names with spaces
**          08/08/2022 mem - Update StateChanged when the state changes
**          08/25/2022 mem - Use view V_Operations_Task_Staff when checking if the user can update a closed prep request item
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _msg text;
    _currentStateID int;
    _requestType text := 'Default';
    _logErrors boolean := false;
    _allowUpdateEstimatedPrepTime boolean := false;
    _datasetTypeID int;
    _campaignID int := 0;
    _missingCount int;
    _organismID int;
    _tissueIdentifier text;
    _tissueName text;
    _stateID int := 0;
    _eusUsageTypeID int;
    _eusUsersList text := '';
    _addingItem boolean := false;
    _allowNoneWP boolean := false;
    _separationGroupAlt text := '';
    _currentAssignedPersonnel text;
    _requestTypeExisting text;
    _activationState int := 10;
    _activationStateName text;
    _currentEstimatedPrepTimeDays Int;
    _logMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    If Coalesce(_state, '') = 'Closed (containers and material)' Then
        -- Prior to September 2018, we would also look for biomaterial (cell cultures)
        -- and would close them if _state was 'Closed (containers and material)'
        -- by calling DoSamplePrepMaterialOperation
        --
        -- We stopped associating biomaterial (cell cultures) with Sample Prep Requests in June 2017
        -- so simply change the state to Closed
        _state := 'Closed';
    End If;

    If Coalesce(_eusUserID, 0) <= 0 Then
        _eusUserID := Null;
    End If;

    _estimatedPrepTimeDays := Coalesce(_estimatedPrepTimeDays, 1);

    _requestedPersonnel := Trim(Coalesce(_requestedPersonnel, ''));
    _assignedPersonnel := Trim(Coalesce(_assignedPersonnel, 'na'));

    If _assignedPersonnel = '' Then
        _assignedPersonnel := 'na';
    End If;

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

        ---------------------------------------------------
        -- Validate input fields
        ---------------------------------------------------
        --
        _instrumentGroup := Coalesce(_instrumentGroup, '');

        _datasetType := Coalesce(_datasetType, '');

        If char_length(Coalesce(_estimatedMSRuns, '')) < 1 Then
            RAISE EXCEPTION 'Estimated number of MS runs was blank; it should be 0 or a positive number';
        End If;

        If Not Coalesce(_blockAndRandomizeSamples, '')::citext IN ('Yes', 'No', 'NA') Then
            RAISE EXCEPTION 'Block And Randomize Samples must be Yes, No, or NA';
        End If;

        If Not Coalesce(_blockAndRandomizeRuns, '')::citext IN ('Yes', 'No') Then
            RAISE EXCEPTION 'Block And Randomize Runs must be Yes or No';
        End If;

        If char_length(Coalesce(_reason, '')) < 1 Then
            RAISE EXCEPTION 'The reason field is required';
        End If;

        If public.has_whitespace_chars(_requestName, 1) Then
            -- Auto-replace CR, LF, or tabs with spaces
            If Position(chr(10) In _requestName) > 0 Then
                _requestName := Replace(_requestName, chr(10), ' ');
            End If;

            If Position(chr(13) In _requestName) > 0 Then
            _requestName := Replace(_requestName, chr(13), ' ');
            End If;

            If Position(chr(9) In _requestName) > 0 Then
                _requestName := Replace(_requestName, chr(9), ' ');
            End If;
        End If;

        If _state::citext In ('New', 'Closed') Then
            -- Always clear State Comment when the state is new or closed
            _stateComment := '';
        End If;

        If Exists ( SELECT U.Username
                    FROM t_users U
                         INNER JOIN t_user_operations_permissions UOP
                           ON U.user_id = UOP.user_id
                         INNER JOIN t_user_operations UO
                           ON UOP.operation_id = UO.operation_id
                    WHERE U.Status = 'Active' AND
                          UO.operation = 'DMS_Sample_Preparation' AND
                          Username = _callingUser) Then

              _allowUpdateEstimatedPrepTime := true;
        End If;

        ---------------------------------------------------
        -- Validate priority
        ---------------------------------------------------

        If _priority <> 'Normal' AND Coalesce(_reasonForHighPriority, '') = '' Then
            RAISE EXCEPTION 'Priority "%" requires justification reason to be provided', _priority;
        End If;

        If Not _priority::citext IN ('Normal', 'High') Then
            RAISE EXCEPTION 'Priority should be Normal or High';
        End If;

        ---------------------------------------------------
        -- Validate instrument group and dataset type
        ---------------------------------------------------
        --
        If NOT (_estimatedMSRuns::citext IN ('0', 'None')) Then
            If _instrumentGroup::citext IN ('none', 'na') Then
                RAISE EXCEPTION 'Estimated runs must be 0 or "none" when instrument group is: %', _instrumentGroup;
            End If;

            If public.try_cast(_estimatedMSRuns, null::int) Is Null Then
                RAISE EXCEPTION 'Estimated runs must be an integer or "none"';
            End If;

            If Coalesce(_instrumentGroup, '') = '' Then
                RAISE EXCEPTION 'Instrument group cannot be empty since the estimated MS run count is non-zero';
            End If;

            If Coalesce(_datasetType, '') = '' Then
                RAISE EXCEPTION 'Dataset type cannot be empty since the estimated MS run count is non-zero';
            End If;

            If Coalesce(_separationGroup, '') = '' Then
                RAISE EXCEPTION 'Separation group cannot be empty since the estimated MS run count is non-zero';
            End If;

            ---------------------------------------------------
            -- Determine the Instrument Group
            ---------------------------------------------------

            If NOT EXISTS (SELECT * FROM t_instrument_group WHERE instrument_group = _instrumentGroup) Then
                -- Try to update instrument group using t_instrument_name
                SELECT instrument_group
                INTO _instrumentGroup
                FROM t_instrument_name
                WHERE instrument = _instrumentGroup AND
                      status <> 'inactive'

            End If;

            ---------------------------------------------------
            -- Validate instrument group and dataset type
            ---------------------------------------------------

            CALL validate_instrument_group_and_dataset_type (
                            _datasetType => _datasetType,
                            _instrumentGroup => _instrumentGroup,           -- Output
                            _datasetTypeID => _datasetTypeID output,        -- Output
                            _message => _msg,                               -- Output
                            _returnCode => _returnCode);                    -- Output

            If _returnCode <> '' Then
                RAISE EXCEPTION 'ValidateInstrumentGroupAndDatasetType: %', _msg;
            End If;
        End If;

        ---------------------------------------------------
        -- Resolve campaign ID
        ---------------------------------------------------

        _campaignID := get_campaign_id (_campaign);

        If _campaignID = 0 Then
            RAISE EXCEPTION 'Could not find entry in database for campaign "%"', _campaign;
        End If;

        ---------------------------------------------------
        -- Resolve material containers
        ---------------------------------------------------

        -- Create temporary table to hold names of material containers as input
        --
        CREATE TEMP TABLE Tmp_MaterialContainers (
            name text not null
        )

        -- Get names of material containers from list argument into table
        --
        INSERT INTO Tmp_MaterialContainers (name)
        SELECT item FROM public.parse_delimited_list(_materialContainerList)

        -- Verify that material containers exist
        --

        SELECT COUNT(*)
        INTO _missingCount
        FROM Tmp_MaterialContainers
        WHERE name Not In (
            SELECT container
            FROM t_material_containers
        );

        If _missingCount > 0 Then
            RAISE EXCEPTION 'One or more material containers was not in database';
        End If;

        ---------------------------------------------------
        -- Resolve organism ID
        ---------------------------------------------------

        _organismID := get_organism_id(_organism);

        If _organismID = 0 Then
            RAISE EXCEPTION 'Could not find entry in database for organism "%"', _organism;
        End If;

        ---------------------------------------------------
        -- Resolve _tissue to BTO identifier
        ---------------------------------------------------

        CALL get_tissue_id (
                _tissueNameOrID => _tissue,
                _tissueIdentifier => _tissueIdentifier output,
                _tissueName => _tissueName output,
                _returnCode => _returnCode);

        If _returnCode <> '' Then
            RAISE EXCEPTION 'Could not resolve tissue name or id: "%"', _tissue;
        End If;

        ---------------------------------------------------
        -- Force values of some properties for add mode
        ---------------------------------------------------

        _mode := Trim(Lower(Coalesce(_mode, '')));

        If _mode = 'add' Then
            _state := 'New';
            _assignedPersonnel := 'na';
        End If;

        ---------------------------------------------------
        -- Validate requested and assigned personnel
        -- Names should be in the form 'Last Name, First Name (Username)'
        ---------------------------------------------------

        CALL validate_request_users (
                _requestName,
                'add_update_sample_prep_request',
                _requestedPersonnel => _requestedPersonnel,     -- Output
                _assignedPersonnel => _assignedPersonnel,       -- Output
                _requireValidRequestedPersonnel => true,
                _message => _message,                           -- Output
                _returnCode => _returnCode);

        If _returnCode <> '' Then
            If Coalesce(_message, '') = '' Then
                _message := 'Error validating the requested and assigned personnel';
            End If;

            RAISE EXCEPTION '%', _message;
        End If;

        ---------------------------------------------------
        -- Convert state name to ID
        ---------------------------------------------------

        --
        SELECT state_id
        INTO _stateID
        FROM  t_sample_prep_request_state_name
        WHERE state_name = _state;

        If Not FOUND Then
            RAISE EXCEPTION 'No entry could be found in database for state "%"', _state;
        End If;

        ---------------------------------------------------
        -- Validate EUS type, proposal, and user list
        --
        -- This procedure accepts a list of EUS User IDs,
        -- so we convert to a string before calling it,
        -- then convert back to an integer afterward
        ---------------------------------------------------

        If _mode = 'add' Then
            _addingItem := true;
        End If;

        If Coalesce(_eusUserID, 0) > 0 Then
            _eusUsersList := Cast(_eusUserID As text);
            _eusUserID := Null;
        End If;

        CALL validate_eus_usage (
                        _eusUsageType   => _eusUsageType,       -- Input/Output
                        _eusProposalID  => _eusProposalID,      -- Input/Output
                        _eusUsersList   => _eusUsersList,       -- Input/Output
                        _eusUsageTypeID => _eusUsageTypeID,     -- Output
                        _message => _msg,                       -- Output
                        _returnCode => _returnCode,             -- Output
                        _autoPopulateUserListIfBlank => false,
                        _samplePrepRequest => 1,
                        _experimentID => 0,
                        _campaignID => _campaignID,
                        _addingItem => _addingItem);

        If _returnCode <> '' Then
            RAISE EXCEPTION 'ValidateEUSUsage: %', _msg;
        End If;

        If Coalesce(_msg, '') <> '' Then
            _message := public.append_to_text(_message, _msg, 0, '; ', 1024);
        End If;

        If char_length(Coalesce(_eusUsersList, '')) > 0 Then
            _eusUserID := public.try_cast(_eusUsersList, null::int);

            If Coalesce(_eusUserID, 0) <= 0 Then
                _eusUserID := Null;
            End If;
        End If;

        ---------------------------------------------------
        -- Validate the work package
        ---------------------------------------------------

        CALL validate_wp ( _workPackageNumber,
                           _allowNoneWP,
                           _message => _msg,
                           _returnCode => _returnCode);

        If _returnCode <> '' Then
            RAISE EXCEPTION 'ValidateWP: %', _message;
        End If;

        If Exists (SELECT * FROM t_charge_code WHERE charge_code = _workPackageNumber And deactivated = 'Y') Then
            _message := public.append_to_text(_message, 'Warning: Work Package ' || _workPackageNumber || ' is deactivated', 0, '; ', 1024);
        ElsIf Exists (SELECT * FROM t_charge_code WHERE charge_code = _workPackageNumber And charge_code_state = 0) Then
            _message := public.append_to_text(_message, 'Warning: Work Package ' || _workPackageNumber || ' is likely deactivated', 0, '; ', 1024);
        End If;

        -- Make sure the Work Package is capitalized properly
        --
        SELECT charge_code
        INTO _workPackageNumber
        FROM t_charge_code
        WHERE charge_code = _workPackageNumber

        ---------------------------------------------------
        -- Auto-change separation type to separation group, if applicable
        ---------------------------------------------------
        --
        If Not Exists (SELECT * FROM t_separation_group WHERE separation_group = _separationGroup) Then

            SELECT separation_group
            INTO _separationGroupAlt
            FROM t_secondary_sep
            WHERE separation_type = _separationGroup AND
                  active = 1

            If Coalesce(_separationGroupAlt, '') <> '' Then
                _separationGroup := _separationGroupAlt;
            End If;
        End If;

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        If _mode = 'update' Then
            -- Cannot update a non-existent entry
            --
            _currentStateID := 0;

            SELECT state_id,
                   assigned_personnel,
                   request_type
            INTO _currentStateID, _currentAssignedPersonnel, _requestTypeExisting
            FROM  t_sample_prep_request
            WHERE prep_request_id = _id;

            If Not FOUND Then
                RAISE EXCEPTION 'No entry could be found in database for update';
            End If;

            -- Changes not allowed if in 'closed' state
            --
            If _currentStateID = 5 AND NOT EXISTS (SELECT * FROM V_Operations_Task_Staff WHERE username = _callingUser) Then
                RAISE EXCEPTION 'Changes to entry are not allowed if it is in the "Closed" state';
            End If;

            -- Don't allow change to 'Prep in Progress' unless someone has been assigned
            If _state = 'Prep in Progress' AND ((_assignedPersonnel = '') OR (_assignedPersonnel = 'na')) Then
                RAISE EXCEPTION 'State cannot be changed to "Prep in Progress" unless someone has been assigned';
            End If;

            If _requestTypeExisting <> _requestType Then
                RAISE EXCEPTION 'Cannot edit requests of type % with the sample_prep_request page; use https://dms2.pnl.gov/rna_prep_request/report', _requestTypeExisting;
            End If;
        End If;

        If _mode = 'add' Then
            -- Make sure the work package number is not inactive
            --

            SELECT CCAS.activation_state,
                   CCAS.activation_state_name
            INTO _activationState, _activationStateName
            FROM t_charge_code CC
                 INNER JOIN t_charge_code_activation_state CCAS
                   ON CC.activation_state = CCAS.activation_state
            WHERE CC.charge_code = _workPackageNumber;

            If _activationState >= 3 Then
                RAISE EXCEPTION 'Cannot use inactive Work Package "%" for a new sample prep request', _workPackageNumber;
            End If;
        End If;

        ---------------------------------------------------
        -- Check for name collisions
        ---------------------------------------------------
        --
        If _mode = 'add' Then
            If EXISTS (SELECT * FROM t_sample_prep_request WHERE request_name = _requestName) Then
                RAISE EXCEPTION 'Cannot add: Request "%" already in database', _requestName;
            End If;

        ElsIf EXISTS (SELECT * FROM t_sample_prep_request WHERE request_name = _requestName AND prep_request_id <> _id) Then
            RAISE EXCEPTION 'Cannot rename: Request "%" already in database', _requestName;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------
        --
        If _mode = 'add' Then

            INSERT INTO t_sample_prep_request (
                request_name,
                requester_username,
                reason,
                organism,
                tissue_id,
                biohazard_level,
                campaign,
                number_of_samples,
                sample_name_list,
                sample_type,
                prep_method,
                sample_naming_convention,
                requested_personnel,
                assigned_personnel,
                estimated_prep_time_days,
                estimated_ms_runs,
                work_package,
                eus_usage_type,
                eus_proposal_id,
                eus_user_id,
                instrument_analysis_specifications,
                comment,
                priority,
                state_id,
                state_comment,
                instrument_group,
                dataset_type,
                separation_type,
                block_and_randomize_samples,
                block_and_randomize_runs,
                reason_for_high_priority,
                request_type,
                material_container_list
            ) VALUES (
                _requestName,
                _requesterUsername,
                _reason,
                _organism,
                _tissueIdentifier,
                _biohazardLevel,
                _campaign,
                _numberofSamples,
                _sampleNameList,
                _sampleType,
                _prepMethod,
                _sampleNamingConvention,
                _requestedPersonnel,
                _assignedPersonnel,
                Case When _allowUpdateEstimatedPrepTime Then _estimatedPrepTimeDays Else 0 End,
                _estimatedMSRuns,
                _workPackageNumber,
                _eusUsageType,
                _eusProposalID,
                _eusUserID,
                _instrumentAnalysisSpecifications,
                _comment,
                _priority,
                _stateID,
                _stateComment,
                _instrumentGroup,
                _datasetType,
                _separationGroup,
                _blockAndRandomizeSamples,
                _blockAndRandomizeRuns,
                _reasonForHighPriority,
                _requestType,
                _materialContainerList
            )
            RETURNING prep_request_id
            INTO _id;

            -- If _callingUser is defined, update system_account in t_sample_prep_request_updates
            If char_length(_callingUser) > 0 Then
                CALL alter_entered_by_user ('t_sample_prep_request_updates', 'request_id', _id, _callingUser,
                                            _entryDateColumnName => 'Date_of_Change', _enteredByColumnName => 'System_Account');
            End If;

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------
        --
        If _mode = 'update' Then

            SELECT estimated_prep_time_days
            INTO _currentEstimatedPrepTimeDays
            FROM t_sample_prep_request
            WHERE prep_request_id = _id;

            UPDATE t_sample_prep_request
            SET
                request_name = _requestName,
                requester_username = _requesterUsername,
                reason = _reason,
                material_container_list = _materialContainerList,
                organism = _organism,
                tissue_id = _tissueIdentifier,
                biohazard_level = _biohazardLevel,
                campaign = _campaign,
                number_of_samples = _numberofSamples,
                sample_name_list = _sampleNameList,
                sample_type = _sampleType,
                prep_method = _prepMethod,
                sample_naming_convention = _sampleNamingConvention,
                requested_personnel = _requestedPersonnel,
                assigned_personnel = _assignedPersonnel,
                estimated_prep_time_days = Case When _allowUpdateEstimatedPrepTime Then _estimatedPrepTimeDays Else estimated_prep_time_days End,
                estimated_ms_runs = _estimatedMSRuns,
                work_package = _workPackageNumber,
                eus_proposal_id = _eusProposalID,
                eus_usage_type = _eusUsageType,
                eus_user_id = _eusUserID,
                instrument_analysis_specifications = _instrumentAnalysisSpecifications,
                comment = _comment,
                priority = _priority,
                state_id = _stateID,
                state_changed = Case When _currentStateID = _stateID Then state_changed Else CURRENT_TIMESTAMP End,
                state_comment = _stateComment,
                instrument_group = _instrumentGroup,
                instrument_name = Null,
                dataset_type = _datasetType,
                separation_type = _separationGroup,
                block_and_randomize_samples = _blockAndRandomizeSamples,
                block_and_randomize_runs = _blockAndRandomizeRuns,
                reason_for_high_priority = _reasonForHighPriority
            WHERE prep_request_id = _id

            -- If _callingUser is defined, update system_account in t_sample_prep_request_updates
            If char_length(_callingUser) > 0 Then
                CALL alter_entered_by_user ('t_sample_prep_request_updates', 'request_id', _id, _callingUser,
                                            _entryDateColumnName => 'Date_of_Change', _enteredByColumnName => 'System_Account');
            End If;

            If _currentEstimatedPrepTimeDays <> _estimatedPrepTimeDays And Not _allowUpdateEstimatedPrepTime Then
                _msg := 'Not updating estimated prep time since user is not a sample prep request staff member';
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

    DROP TABLE IF EXISTS Tmp_MaterialContainers;
END
$$;

COMMENT ON PROCEDURE public.add_update_sample_prep_request IS 'AddUpdateSamplePrepRequest';
