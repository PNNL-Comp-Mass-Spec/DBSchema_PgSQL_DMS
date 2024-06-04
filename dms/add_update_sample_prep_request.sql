--
-- Name: add_update_sample_prep_request(text, text, text, text, text, text, text, integer, text, text, text, text, text, text, integer, text, text, text, text, integer, text, text, text, text, text, text, text, integer, text, text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_update_sample_prep_request(IN _requestname text, IN _requesterusername text, IN _reason text, IN _materialcontainerlist text, IN _organism text, IN _biohazardlevel text, IN _campaign text, IN _numberofsamples integer, IN _samplenamelist text, IN _sampletype text, IN _prepmethod text, IN _samplenamingconvention text, IN _assignedpersonnel text, IN _requestedpersonnel text, IN _estimatedpreptimedays integer, IN _estimatedmsruns text, IN _workpackagenumber text, IN _eusproposalid text, IN _eususagetype text, IN _eususerid integer, IN _instrumentgroup text, IN _datasettype text, IN _instrumentanalysisspecifications text, IN _comment text, IN _priority text, IN _state text, IN _statecomment text, INOUT _id integer, IN _separationgroup text, IN _blockandrandomizesamples text, IN _blockandrandomizeruns text, IN _reasonforhighpriority text, IN _tissue text DEFAULT ''::text, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add new or edit an existing sample prep request
**
**  Arguments:
**    _requestName                      Sample prep request name
**    _requesterUsername                Requester username
**    _reason                           Description of the prep request
**    _materialContainerList            Comma-separated list of material container names
**    _organism                         Organism name
**    _biohazardLevel                   Biohazard level
**    _campaign                         Campaign
**    _numberOfSamples                  Number of samples to be created
**    _sampleNameList                   Sample name description or sample name prefix/prefixes
**    _sampleType                       Sample type, e.g. 'Cell pellet', 'Peptides', 'Tissue', 'Soil', 'Plasma'
**    _prepMethod                       Sample prep method, e.g. 'Global Digest', 'MPLEx', 'Solvent Extraction'
**    _sampleNamingConvention           Sample name prefix
**    _assignedPersonnel                Assigned personnel, e.g. 'Zink, Erika M (D3P704)' (also supports matching a person's last name using procedure auto_resolve_name_to_username)
**    _requestedPersonnel               Requested personnel
**    _estimatedPrepTimeDays            Estimated prep time, in days
**    _estimatedMSRuns                  Estimated number of mass spec datasets to be generated
**    _workPackageNumber                Work package
**    _eusProposalID                    EUS proposal ID
**    _eusUsageType                     EUS usage type
**    _eusUserID                        EUS user ID; use Null or 0 if no EUS user
**    _instrumentGroup                  Will typically contain an instrument group name; could also contain 'None' or any other text
**    _datasetType                      Dataset type, e.g. 'GC-MS', 'HMS-HCD-HMSn', or 'MRM'
**    _instrumentAnalysisSpecifications Instrument analysis notes
**    _comment                          Prep request comment
**    _priority                         Priority: 'Normal' or 'High'
**    _state                            State: 'New', 'On Hold', 'Prep in Progress', 'Prep Complete', or 'Closed'; see table t_sample_prep_request_state_name
**    _stateComment                     State comment
**    _id                               Input/output: sample prep request ID
**    _separationGroup                  Separation group name
**    _blockAndRandomizeSamples         Block and randomize samples: 'Yes', 'No', or 'na'
**    _blockAndRandomizeRuns            Block and randomize requested runs: 'Yes' or 'No'
**    _reasonForHighPriority            Reason for requesting high priority
**    _tissue                           Tissue name, e.g. 'blood plasma', 'cell culture', 'plant, 'soil', etc.
**    _mode                             Mode: 'add' or 'update'
**    _message                          Status message
**    _returnCode                       Return code
**    _callingUser                      Username of the calling user
**
**  Auth:   grk
**  Date:   06/09/2005
**          06/10/2005 grk - Added Reason argument
**          06/16/2005 grk - Added state restriction for update
**          07/26/2005 grk - Added stuff for requested personnel
**          08/09/2005 grk - Widened _sampleNameList
**          10/12/2005 grk - Added _useSingleLCColumn
**          10/26/2005 grk - Disallowed change if not in 'New' state
**          10/28/2005 grk - Added handling for internal standard
**          11/01/2005 grk - Rescinded disallowed change in 'New' state
**          11/11/2005 grk - Added handling for postdigest internal standard
**          01/03/2006 grk - Added check for existing request name
**          03/14/2006 grk - Added stuff for multiple assigned users
**          08/10/2006 grk - Modified state handling
**          08/10/2006 grk - Allowed multiple requested personnel users
**          12/15/2006 grk - Added EstimatedMSRuns argument (Ticket #336)
**          04/20/2007 grk - Added validation for organism, campaign, cell culture (Ticket #440)
**          07/11/2007 grk - Added 'standard' EUS fields and removed old proposal field(Ticket #499)
**          07/30/2007 grk - Corrected error in update of EUS fields (Ticket #499)
**          09/01/2007 grk - Added instrument name and datasets type fields (Ticket #512)
**          09/04/2007 grk - Added _technicalReplicates fields (Ticket #512)
**          05/02/2008 grk - Repaired leaking query and arranged for default add state to be 'Pending Approval'
**          05/16/2008 mem - Added optional parameter _callingUser; if provided, will populate field System_Account in T_Sample_Prep_Request_Updates with this name (Ticket #674)
**          12/02/2009 grk - Don't allow change to 'Prep in Progress' unless someone has been assigned
**          04/14/2010 grk - Widened _biomaterialList field
**          04/22/2010 grk - Use try-catch for error handling
**          08/09/2010 grk - Added handling for 'Closed (containers and material)'
**          08/15/2010 grk - Widened _biomaterialList field
**          08/27/2010 mem - Now auto-switching _instrumentName to be instrument group instead of instrument name
**          08/15/2011 grk - Added Separation_Type
**          12/12/2011 mem - Updated call to Validate_EUS_Usage to treat _eusUsageType as an input/output parameter
**          10/19/2012 mem - Now auto-changing _separationType to Separation_Group if _separationType specifies a separation type
**          04/05/2013 mem - Now requiring that _estimatedMSRuns be defined.  If it is non-zero, instrument group, dataset type, and separation group must also be defined
**          04/08/2013 grk - Added _blockAndRandomizeSamples, _blockAndRandomizeRuns, and _iOPSPermitsCurrent
**          04/09/2013 grk - Disregarding internal standards
**          04/09/2013 grk - Changed priority to text "Normal/High", added _numberOfBiomaterialRepsReceived, removed Facility field
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
**          11/18/2016 mem - Log try/catch errors using post_log_entry
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
**          08/29/2018 mem - Remove call to Do_Sample_Prep_Material_Operation since we stopped associating biomaterial (cell cultures) with Sample Prep Requests in June 2017
**          11/30/2018 mem - Make _reason an input/output parameter
**          01/23/2019 mem - Switch _reason back to a normal input parameter since view V_Sample_Prep_Request_Entry now appends the __NoCopy__ flag to several fields
**          01/13/2020 mem - Require _requestedPersonnel to include a sample prep staff member (no longer allow 'na' or 'any')
**          08/12/2020 mem - Check for Validate_EUS_Usage returning a message, even if it returns 0
**          09/15/2020 mem - Use 'https://dms2.pnl.gov/' instead of http://
**          05/25/2021 mem - Set _samplePrepRequest to 1 when calling Validate_EUS_Usage
**          05/26/2021 mem - Override _eusUsageType if _mode is 'add' and the campaign has EUSUsageType = 'USER_REMOTE
**          05/27/2021 mem - Refactor EUS Usage validation code into Validate_EUS_Usage
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
**          01/07/2024 mem - Ported to PostgreSQL
**          01/08/2024 mem - Remove procedure name from error message
**          01/17/2024 mem - Only update _instrumentGroup if the value matches an instrument name
**                         - Verify that _requestName is not an empty string
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _instrumentGroupMatch text;
    _msg text;
    _currentStateID int;
    _requestType text := 'Default';
    _logErrors boolean := false;
    _allowUpdateEstimatedPrepTime boolean := false;
    _datasetTypeID int;
    _campaignID int := 0;
    _missingCount int;
    _invalidNames text;
    _organismID int;
    _tissueIdentifier text;
    _tissueName text;
    _stateID int := 0;
    _eusUsageTypeID int;
    _eusUserIdText text := '';
    _addingItem boolean;
    _separationGroupAlt text := '';
    _currentAssignedPersonnel text;
    _requestTypeExisting text;
    _activationState int := 10;
    _activationStateName text;
    _currentEstimatedPrepTimeDays int;
    _alterEnteredByMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _logMessage text;
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
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _requestName              := Trim(Coalesce(_requestName, ''));
        _requesterUsername        := Trim(Coalesce(_requesterUsername, ''));
        _reason                   := Trim(Coalesce(_reason, ''));
        _materialContainerList    := Trim(Coalesce(_materialContainerList, ''));
        _organism                 := Trim(Coalesce(_organism, ''));
        _biohazardLevel           := Trim(Coalesce(_biohazardLevel, ''));
        _campaign                 := Trim(Coalesce(_campaign, ''));
        _numberOfSamples          := Coalesce(_numberOfSamples, 0);
        _sampleNameList           := Trim(Coalesce(_sampleNameList, ''));
        _sampleType               := Trim(Coalesce(_sampleType, ''));
        _prepMethod               := Trim(Coalesce(_prepMethod, ''));
        _sampleNamingConvention   := Trim(Coalesce(_sampleNamingConvention, ''));
        _assignedPersonnel        := Trim(Coalesce(_assignedPersonnel, 'na'));
        _requestedPersonnel       := Trim(Coalesce(_requestedPersonnel, ''));
        _estimatedPrepTimeDays    := Coalesce(_estimatedPrepTimeDays, 1);
        _estimatedMSRuns          := Trim(Coalesce(_estimatedMSRuns, ''));
        _workPackageNumber        := Trim(Coalesce(_workPackageNumber, ''));
        _eusProposalID            := Trim(Coalesce(_eusProposalID, ''));
        _eusUsageType             := Trim(Coalesce(_eusUsageType, ''));
        _instrumentGroup          := Trim(Coalesce(_instrumentGroup, ''));
        _datasetType              := Trim(Coalesce(_datasetType, ''));
        _instrumentAnalysisSpecifications := Trim(Coalesce(_instrumentAnalysisSpecifications, ''));
        _comment                  := Trim(Coalesce(_comment, ''));
        _priority                 := Trim(Coalesce(_priority, ''));
        _state                    := Trim(Coalesce(_state, ''));
        _stateComment             := Trim(Coalesce(_stateComment, ''));
        _separationGroup          := Trim(Coalesce(_separationGroup, ''));
        _blockAndRandomizeSamples := Trim(Coalesce(_blockAndRandomizeSamples, ''));
        _blockAndRandomizeRuns    := Trim(Coalesce(_blockAndRandomizeRuns, ''));
        _reasonForHighPriority    := Trim(Coalesce(_reasonForHighPriority, ''));
        _tissue                   := Trim(Coalesce(_tissue, ''));
        _callingUser              := Trim(Coalesce(_callingUser, ''));

        _mode                     := Trim(Lower(Coalesce(_mode, '')));

        If Coalesce(_eusUserID, 0) <= 0 Then
            _eusUserID := Null;
        End If;

        If _mode = 'update' And _id Is Null Then
            RAISE EXCEPTION 'Sample prep request ID must be specified when updating a sample prep request';
        End If;

        If _mode = 'update' And Coalesce(_id, 0) <= 0 Then
            RAISE EXCEPTION 'Sample prep request ID must a non-zero integer when updating a sample prep request';
        End If;

        If _assignedPersonnel = '' Then
            _assignedPersonnel := 'na';
        End If;

        If _state::citext = 'Closed (containers and material)' Then
            -- Prior to September 2018, we would also look for biomaterial (cell cultures)
            -- and would close them if _state was 'Closed (containers and material)'
            -- by calling Do_Sample_Prep_Material_Operation

            -- We stopped associating biomaterial (cell cultures) with Sample Prep Requests in June 2017
            -- so simply change the state to Closed
            _state := 'Closed';
        End If;

        If _estimatedMSRuns = '' Then
            RAISE EXCEPTION 'Estimated number of MS runs not specified; it should be 0 or a positive number';
        End If;

        If Not _blockAndRandomizeSamples::citext In ('Yes', 'No', 'NA') Then
            RAISE EXCEPTION 'Block And Randomize Samples must be Yes, No, or NA';
        End If;

        If Not _blockAndRandomizeRuns::citext In ('Yes', 'No') Then
            RAISE EXCEPTION 'Block And Randomize Runs must be Yes or No';
        End If;

        If _reason = '' Then
            RAISE EXCEPTION 'The reason field is required';
        End If;

        If _requestName = '' Then
            RAISE EXCEPTION 'The prep request must have a name';
        End If;

        If public.has_whitespace_chars(_requestName, _allowSpace => true) Then
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
            -- Always clear state comment when the state is new or closed
            _stateComment := '';
        End If;

        If Exists (SELECT U.username
                   FROM t_users U
                        INNER JOIN t_user_operations_permissions UOP
                          ON U.user_id = UOP.user_id
                        INNER JOIN t_user_operations UO
                          ON UOP.operation_id = UO.operation_id
                   WHERE U.Status = 'Active' AND
                         UO.operation = 'DMS_Sample_Preparation' AND
                         Username = _callingUser::citext)
        Then
              _allowUpdateEstimatedPrepTime := true;
        End If;

        ---------------------------------------------------
        -- Validate priority
        ---------------------------------------------------

        If Not _priority::citext In ('Normal', 'High') Then
            RAISE EXCEPTION 'Priority must be Normal or High';
        End If;

        If _priority::citext <> 'Normal' And _reasonForHighPriority = '' Then
            RAISE EXCEPTION 'Priority "%" requires justification reason to be specified', _priority;
        End If;

        ---------------------------------------------------
        -- Validate instrument group and dataset type
        ---------------------------------------------------

        If Not (_estimatedMSRuns::citext In ('0', 'None')) Then
            If _instrumentGroup::citext In ('none', 'na') Then
                RAISE EXCEPTION 'Estimated runs must be 0 or "none" when instrument group is: %', _instrumentGroup;
            End If;

            If public.try_cast(_estimatedMSRuns, null::int) Is Null Then
                RAISE EXCEPTION 'Estimated runs must be an integer or "none"';
            End If;

            If _instrumentGroup = '' Then
                RAISE EXCEPTION 'Instrument group cannot be empty since the estimated MS run count is non-zero';
            End If;

            If _datasetType = '' Then
                RAISE EXCEPTION 'Dataset type cannot be empty since the estimated MS run count is non-zero';
            End If;

            If _separationGroup = '' Then
                RAISE EXCEPTION 'Separation group cannot be empty since the estimated MS run count is non-zero';
            End If;

            ---------------------------------------------------
            -- Determine the Instrument Group
            ---------------------------------------------------

            If Not Exists (SELECT instrument_group FROM t_instrument_group WHERE instrument_group = _instrumentGroup::citext) Then
                -- Try to update instrument group using t_instrument_name
                SELECT instrument_group
                INTO _instrumentGroupMatch
                FROM t_instrument_name
                WHERE instrument = _instrumentGroup::citext AND
                      status <> 'inactive';

                If FOUND Then
                    _instrumentGroup := _instrumentGroupMatch;
                End If;
            End If;

            ---------------------------------------------------
            -- Validate instrument group and dataset type
            ---------------------------------------------------

            CALL public.validate_instrument_group_and_dataset_type (
                            _datasetType     => _datasetType,
                            _instrumentGroup => _instrumentGroup,   -- Output
                            _datasetTypeID   => _datasetTypeID,     -- Output
                            _message         => _msg,               -- Output
                            _returnCode      => _returnCode);       -- Output

            If _returnCode <> '' Then
                RAISE EXCEPTION '%', _msg;
            End If;
        End If;

        ---------------------------------------------------
        -- Resolve campaign ID
        ---------------------------------------------------

        If _campaign = '' Then
            RAISE EXCEPTION 'Campaign must be specified';
        End If;

        _campaignID := public.get_campaign_id(_campaign);

        If _campaignID = 0 Then
            RAISE EXCEPTION 'Invalid campaign: "%" does not exist', _campaign;
        End If;

        ---------------------------------------------------
        -- Resolve material containers
        ---------------------------------------------------

        -- Create temporary table to hold names of material containers as input

        CREATE TEMP TABLE Tmp_MaterialContainers (
            name citext NOT NULL
        );

        -- Get names of material containers from list argument into table

        INSERT INTO Tmp_MaterialContainers (name)
        SELECT Value
        FROM public.parse_delimited_list(_materialContainerList);

        -- Verify that material containers exist

        SELECT COUNT(*)
        INTO _missingCount
        FROM Tmp_MaterialContainers
        WHERE NOT name IN (SELECT container FROM t_material_containers);

        If _missingCount > 0 Then
            SELECT string_agg(name, ', ' ORDER BY name)
            INTO _invalidNames
            FROM Tmp_MaterialContainers
            WHERE NOT name IN (SELECT container FROM t_material_containers);

            If Position(',' In _invalidNames) > 0 Then
                RAISE EXCEPTION 'Invalid material containers: "%" do not exist', _invalidNames;
            Else
                RAISE EXCEPTION 'Invalid material container: "%" does not exist', _invalidNames;
            End If;

        End If;

        ---------------------------------------------------
        -- Resolve organism ID
        ---------------------------------------------------

        If _organism = '' Then
            RAISE EXCEPTION 'Organism must be specified';
        End If;

        _organismID := public.get_organism_id(_organism);

        If _organismID = 0 Then
            RAISE EXCEPTION 'Invalid organism name: "%" does not exist', _organism;
        End If;

        ---------------------------------------------------
        -- Resolve _tissue to BTO identifier
        ---------------------------------------------------

        CALL public.get_tissue_id (
                _tissueNameOrID   => _tissue,
                _tissueIdentifier => _tissueIdentifier,     -- Output
                _tissueName       => _tissueName,           -- Output
                _message          => _message,              -- Output
                _returnCode       => _returnCode);          -- Output

        If _returnCode <> '' Then
            RAISE EXCEPTION 'Could not resolve tissue name or id: "%"', _tissue;
        End If;

        ---------------------------------------------------
        -- Force values of some properties for add mode
        ---------------------------------------------------

        If _mode = 'add' Then
            _state := 'New';
            _assignedPersonnel := 'na';
        End If;

        ---------------------------------------------------
        -- Validate requested and assigned personnel
        -- Names should be in the form 'Last Name, First Name (Username)', but usernames are also supported
        ---------------------------------------------------

        CALL public.validate_request_users (
                        _requestedPersonnel             => _requestedPersonnel,     -- Input/Output
                        _assignedPersonnel              => _assignedPersonnel,      -- Input/Output
                        _requireValidRequestedPersonnel => true,
                        _message                        => _message,                -- Output
                        _returnCode                     => _returnCode);            -- Output

        If _returnCode <> '' Then
            If Coalesce(_message, '') = '' Then
                _message := 'Error validating the requested and assigned personnel';
            End If;

            RAISE EXCEPTION '%', _message;
        End If;

        ---------------------------------------------------
        -- Convert state name to ID
        ---------------------------------------------------

        SELECT state_id
        INTO _stateID
        FROM t_sample_prep_request_state_name
        WHERE state_name = _state::citext;

        If Not FOUND Then
            RAISE EXCEPTION 'Invalid sample prep request state name: %', _state;
        End If;

        ---------------------------------------------------
        -- Validate EUS type, proposal, and user list
        --
        -- Procedure validate_eus_usage accepts a list of EUS User IDs,
        -- so we convert to a string before calling it, then convert back to an integer afterward
        ---------------------------------------------------

        If _mode = 'add' Then
            _addingItem := true;
        Else
            _addingItem := false;
        End If;

        If Coalesce(_eusUserID, 0) > 0 Then
            _eusUserIdText := _eusUserID;
            _eusUserID := Null;
        End If;

        CALL public.validate_eus_usage (
                        _eusUsageType                => _eusUsageType,      -- Input/Output
                        _eusProposalID               => _eusProposalID,     -- Input/Output
                        _eusUsersList                => _eusUserIdText,     -- Input/Output
                        _eusUsageTypeID              => _eusUsageTypeID,    -- Output
                        _autoPopulateUserListIfBlank => false,
                        _samplePrepRequest           => true,
                        _experimentID                => 0,
                        _campaignID                  => 0,
                        _addingItem                  => _addingItem,
                        _infoOnly                    => false,
                        _message                     => _msg,               -- Output
                        _returnCode                  => _returnCode         -- Output
                    );

        If _returnCode <> '' Then
            RAISE EXCEPTION '%', _msg;
        End If;

        If Coalesce(_msg, '') <> '' Then
            _message := public.append_to_text(_message, _msg);
        End If;

        If Coalesce(_eusUserIdText, '') <> '' Then
            _eusUserID := public.try_cast(_eusUserIdText, null::int);

            If Coalesce(_eusUserID, 0) <= 0 Then
                _eusUserID := Null;
            End If;
        End If;

        ---------------------------------------------------
        -- Validate the work package
        ---------------------------------------------------

        CALL public.validate_wp (
                        _workPackageNumber,
                        _allowNoneWP => false,
                        _message     => _msg,           -- Output
                        _returnCode  => _returnCode);   -- Output

        If _returnCode <> '' Then
            RAISE EXCEPTION '%', _msg;
        End If;

        If Exists (SELECT charge_code FROM t_charge_code WHERE charge_code = _workPackageNumber::citext AND deactivated = 'Y') Then
            _message := public.append_to_text(_message, format('Warning: Work Package %s is deactivated', _workPackageNumber));
        ElsIf Exists (SELECT charge_code FROM t_charge_code WHERE charge_code = _workPackageNumber::citext AND charge_code_state = 0) Then
            _message := public.append_to_text(_message, format('Warning: Work Package %s is likely deactivated', _workPackageNumber));
        End If;

        -- Make sure the work package is capitalized properly

        SELECT charge_code
        INTO _workPackageNumber
        FROM t_charge_code
        WHERE charge_code = _workPackageNumber::citext;

        ---------------------------------------------------
        -- Auto-change separation type to separation group, if applicable
        ---------------------------------------------------

        If Not Exists (SELECT separation_group FROM t_separation_group WHERE separation_group = _separationGroup::citext) Then

            SELECT separation_group
            INTO _separationGroupAlt
            FROM t_secondary_sep
            WHERE separation_type = _separationGroup::citext AND
                  active = 1;

            If FOUND Then
                _separationGroup := _separationGroupAlt;
            End If;
        End If;

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        If _mode = 'update' Then
            -- Cannot update a non-existent entry

            SELECT state_id,
                   assigned_personnel,
                   request_type
            INTO _currentStateID, _currentAssignedPersonnel, _requestTypeExisting
            FROM t_sample_prep_request
            WHERE prep_request_id = _id;

            If Not FOUND Then
                RAISE EXCEPTION 'Cannot update: sample prep request ID % does not exist', _id;
            End If;

            -- Limit who can make changes if in 'closed' state
            -- Users with permission 'DMS_Sample_Preparation' or 'DMS_Sample_Prep_Request_State' can update closed sample prep requests

            If _currentStateID = 5 And Not Exists (SELECT username FROM V_Operations_Task_Staff WHERE username = _callingUser::citext) Then
                RAISE EXCEPTION 'Changes to entry are not allowed if it is in the "Closed" state';
            End If;

            -- Don't allow change to 'Prep in Progress' unless someone has been assigned
            If _state::citext = 'Prep in Progress' And (_assignedPersonnel = '' Or _assignedPersonnel::citext = 'na') Then
                RAISE EXCEPTION 'State cannot be changed to "Prep in Progress" unless someone has been assigned';
            End If;

            If _requestTypeExisting::citext <> _requestType::citext Then
                RAISE EXCEPTION 'Cannot edit requests of type % with the sample_prep_request page; use https://dms2.pnl.gov/rna_prep_request/report', _requestTypeExisting;
            End If;
        End If;

        If _mode = 'add' Then
            -- Make sure the work package is not inactive

            SELECT CCAS.activation_state,
                   CCAS.activation_state_name
            INTO _activationState, _activationStateName
            FROM t_charge_code CC
                 INNER JOIN t_charge_code_activation_state CCAS
                   ON CC.activation_state = CCAS.activation_state
            WHERE CC.charge_code = _workPackageNumber::citext;

            If _activationState >= 3 Then
                RAISE EXCEPTION 'Cannot use inactive work package "%" for a new sample prep request', _workPackageNumber;
            End If;
        End If;

        ---------------------------------------------------
        -- Check for name collisions
        ---------------------------------------------------

        If _mode = 'add' Then
            If Exists (SELECT prep_request_id FROM t_sample_prep_request WHERE request_name = _requestName::citext) Then
                RAISE EXCEPTION 'Cannot add: prep request "%" already exists', _requestName;
            End If;

        ElsIf Exists (SELECT prep_request_id FROM t_sample_prep_request WHERE request_name = _requestName::citext AND prep_request_id <> _id) Then
            RAISE EXCEPTION 'Cannot rename: prep request "%" already exists', _requestName;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

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
                separation_group,
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
                _numberOfSamples,
                _sampleNameList,
                _sampleType,
                _prepMethod,
                _sampleNamingConvention,
                _requestedPersonnel,
                _assignedPersonnel,
                CASE WHEN _allowUpdateEstimatedPrepTime THEN _estimatedPrepTimeDays ELSE 0 END,
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
            If _callingUser <> '' Then
                CALL public.alter_entered_by_user ('public', 't_sample_prep_request_updates', 'request_id', _id, _callingUser,
                                                   _entryDateColumnName => 'date_of_change', _enteredByColumnName => 'system_account', _message => _alterEnteredByMessage);
            End If;

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            SELECT estimated_prep_time_days
            INTO _currentEstimatedPrepTimeDays
            FROM t_sample_prep_request
            WHERE prep_request_id = _id;

            UPDATE t_sample_prep_request
            SET request_name                       = _requestName,
                requester_username                 = _requesterUsername,
                reason                             = _reason,
                material_container_list            = _materialContainerList,
                organism                           = _organism,
                tissue_id                          = _tissueIdentifier,
                biohazard_level                    = _biohazardLevel,
                campaign                           = _campaign,
                number_of_samples                  = _numberOfSamples,
                sample_name_list                   = _sampleNameList,
                sample_type                        = _sampleType,
                prep_method                        = _prepMethod,
                sample_naming_convention           = _sampleNamingConvention,
                requested_personnel                = _requestedPersonnel,
                assigned_personnel                 = _assignedPersonnel,
                estimated_prep_time_days           = CASE WHEN _allowUpdateEstimatedPrepTime THEN _estimatedPrepTimeDays ELSE estimated_prep_time_days END,
                estimated_ms_runs                  = _estimatedMSRuns,
                work_package                       = _workPackageNumber,
                eus_proposal_id                    = _eusProposalID,
                eus_usage_type                     = _eusUsageType,
                eus_user_id                        = _eusUserID,
                instrument_analysis_specifications = _instrumentAnalysisSpecifications,
                comment                            = _comment,
                priority                           = _priority,
                state_id                           = _stateID,
                state_changed                      = CASE WHEN _currentStateID = _stateID THEN state_changed ELSE CURRENT_TIMESTAMP END,
                state_comment                      = _stateComment,
                instrument_group                   = _instrumentGroup,
                instrument_name                    = Null,
                dataset_type                       = _datasetType,
                separation_group                   = _separationGroup,
                block_and_randomize_samples        = _blockAndRandomizeSamples,
                block_and_randomize_runs           = _blockAndRandomizeRuns,
                reason_for_high_priority           = _reasonForHighPriority
            WHERE prep_request_id = _id;

            -- If _callingUser is defined, update system_account in t_sample_prep_request_updates
            If _callingUser <> '' Then
                CALL public.alter_entered_by_user ('public', 't_sample_prep_request_updates', 'request_id', _id, _callingUser,
                                                   _entryDateColumnName => 'date_of_change', _enteredByColumnName => 'system_account', _message => _alterEnteredByMessage);
            End If;

            If _currentEstimatedPrepTimeDays <> _estimatedPrepTimeDays And Not _allowUpdateEstimatedPrepTime Then
                _msg := 'Not updating estimated prep time since user is not a sample prep request staff member';
                _message := public.append_to_text(_message, _msg);
            End If;

        End If;

        DROP TABLE Tmp_MaterialContainers;
        RETURN;

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


ALTER PROCEDURE public.add_update_sample_prep_request(IN _requestname text, IN _requesterusername text, IN _reason text, IN _materialcontainerlist text, IN _organism text, IN _biohazardlevel text, IN _campaign text, IN _numberofsamples integer, IN _samplenamelist text, IN _sampletype text, IN _prepmethod text, IN _samplenamingconvention text, IN _assignedpersonnel text, IN _requestedpersonnel text, IN _estimatedpreptimedays integer, IN _estimatedmsruns text, IN _workpackagenumber text, IN _eusproposalid text, IN _eususagetype text, IN _eususerid integer, IN _instrumentgroup text, IN _datasettype text, IN _instrumentanalysisspecifications text, IN _comment text, IN _priority text, IN _state text, IN _statecomment text, INOUT _id integer, IN _separationgroup text, IN _blockandrandomizesamples text, IN _blockandrandomizeruns text, IN _reasonforhighpriority text, IN _tissue text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_update_sample_prep_request(IN _requestname text, IN _requesterusername text, IN _reason text, IN _materialcontainerlist text, IN _organism text, IN _biohazardlevel text, IN _campaign text, IN _numberofsamples integer, IN _samplenamelist text, IN _sampletype text, IN _prepmethod text, IN _samplenamingconvention text, IN _assignedpersonnel text, IN _requestedpersonnel text, IN _estimatedpreptimedays integer, IN _estimatedmsruns text, IN _workpackagenumber text, IN _eusproposalid text, IN _eususagetype text, IN _eususerid integer, IN _instrumentgroup text, IN _datasettype text, IN _instrumentanalysisspecifications text, IN _comment text, IN _priority text, IN _state text, IN _statecomment text, INOUT _id integer, IN _separationgroup text, IN _blockandrandomizesamples text, IN _blockandrandomizeruns text, IN _reasonforhighpriority text, IN _tissue text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_update_sample_prep_request(IN _requestname text, IN _requesterusername text, IN _reason text, IN _materialcontainerlist text, IN _organism text, IN _biohazardlevel text, IN _campaign text, IN _numberofsamples integer, IN _samplenamelist text, IN _sampletype text, IN _prepmethod text, IN _samplenamingconvention text, IN _assignedpersonnel text, IN _requestedpersonnel text, IN _estimatedpreptimedays integer, IN _estimatedmsruns text, IN _workpackagenumber text, IN _eusproposalid text, IN _eususagetype text, IN _eususerid integer, IN _instrumentgroup text, IN _datasettype text, IN _instrumentanalysisspecifications text, IN _comment text, IN _priority text, IN _state text, IN _statecomment text, INOUT _id integer, IN _separationgroup text, IN _blockandrandomizesamples text, IN _blockandrandomizeruns text, IN _reasonforhighpriority text, IN _tissue text, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddUpdateSamplePrepRequest';

