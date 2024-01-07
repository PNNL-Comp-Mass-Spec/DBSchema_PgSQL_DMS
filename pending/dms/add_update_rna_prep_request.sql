--
CREATE OR REPLACE PROCEDURE public.add_update_rna_prep_request
(
    _requestName text,
    _requesterUsername text,
    _reason text,
    _organism text,
    _biohazardLevel text,
    _campaign text,
    _numberofSamples int,
    _sampleNameList text,
    _sampleType text,
    _prepMethod text,
    _sampleNamingConvention text,
    _estimatedCompletion text,
    _workPackageNumber text,
    _eusProposalID text,
    _eusUsageType text,
    _eusUserID int,
    _instrumentName text,
    _datasetType text,
    _instrumentAnalysisSpecifications text,
    _state text,
    INOUT _id int,
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
**      Add new or edit an existing RNA prep request
**
**      This procedure is obsolete; RNA prep requests were last used in 2014
**
**  Arguments:
**    _requesterUsername                Requester username
**    _reason                           Reason
**    _organism                         Organism
**    _biohazardLevel                   Biohazard level
**    _campaign                         Campaign
**    _numberofSamples                  Number of samples to be created
**    _sampleNameList                   Sample name list
**    _sampleType                       Sample type
**    _prepMethod                       Prep method
**    _sampleNamingConvention           Sample naming convention
**    _estimatedCompletion              Estimated completion date (as text)
**    _workPackageNumber                Work package number
**    _eusProposalID                    EUS proposal ID
**    _eusUsageType                     EUS usage type
**    _eusUserID                        EUS user ID; use Null or 0 if no EUS user
**    _instrumentName                   Instrument name
**    _datasetType                      Dataset type
**    _instrumentAnalysisSpecifications Instrument analysis specifications
**    _state                            State: 'New', 'Open', 'Prep in Progress', 'Prep Complete', or 'Closed'
**    _id                               Input/output: RNA prep request ID in t_sample_prep_request
**    _mode                             Mode: 'add' or 'update'
**    _message                          Status message
**    _returnCode                       Return code
**    _callingUser                      Username of the calling user
**
**  Auth:   mem
**  Date:   05/19/2014 mem - Initial version
**          05/20/2014 mem - Switched from InstrumentGroup to InstrumentName
**          02/23/2016 mem - Add Set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          06/12/2018 mem - Send _maxLength to append_to_text
**          08/22/2018 mem - Change the EUS User parameter from a varchar(1024) to an integer
**          08/29/2018 mem - Remove parameters _biomaterialList,  _projectNumber, and _numberOfBiomaterialRepsReceived
**                         - Remove call to Do_Sample_Prep_Material_Operation
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _msg text;
    _currentStateID int;
    _requestType text := 'RNA';
    _instrumentGroup text := '';
    _datasetTypeID int;
    _campaignID int := 0;
    _organismID int;
    _estimatedCompletionDate timestamp;
    _stateID int := 0;
    _eusUsageTypeID int;
    _eusUsersList text := '';
    _allowNoneWP boolean := false;
    _requestTypeExisting text;
    _activationState int := 10;
    _activationStateName text;
    _alterEnteredByMessage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    If Coalesce(_eusUserID, 0) <= 0 Then
        _eusUserID := Null;
    End If;

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

        _instrumentName := Trim(Coalesce(_instrumentName, ''));
        _datasetType    := Trim(Coalesce(_datasetType, ''));
        _mode           := Trim(Lower(Coalesce(_mode, '')));

        ---------------------------------------------------
        -- Validate dataset type
        ---------------------------------------------------

        If Not _instrumentName::citext In ('', 'none', 'na') Then
            If Coalesce(_datasetType, '') = '' Then
                RAISE EXCEPTION 'Dataset type cannot be empty since the Instrument Name is defined';
            End If;

            ---------------------------------------------------
            -- Validate the instrument name
            ---------------------------------------------------

            If Not Exists (SELECT instrument FROM t_instrument_name WHERE instrument = _instrumentName) Then
                -- Check whether _instrumentName actually has an instrument group

                SELECT instrument
                INTO _instrumentName
                FROM t_instrument_name
                WHERE instrument_group = _instrumentName AND
                      status <> 'inactive'
                LIMIT 1;
            End If;

            ---------------------------------------------------
            -- Determine the Instrument Group
            ---------------------------------------------------

            SELECT instrument_group
            INTO _instrumentGroup
            FROM t_instrument_name
            WHERE instrument = _instrumentName
            LIMIT 1;

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
                RAISE EXCEPTION 'validate_instrument_group_and_dataset_type: %', _msg;
            End If;
        End If;

        ---------------------------------------------------
        -- Resolve campaign ID
        ---------------------------------------------------

        _campaignID := public.get_campaign_id(_campaign);

        If _campaignID = 0 Then
            RAISE EXCEPTION 'Invalid campaign: "%" does not exist', _campaign;
        End If;

        ---------------------------------------------------
        -- Resolve organism ID
        ---------------------------------------------------

        _organismID := public.get_organism_id(_organism);

        If _organismID = 0 Then
            RAISE EXCEPTION 'Invalid organism name: "%" does not exist', _organism;
        End If;

        ---------------------------------------------------
        -- Convert estimated completion date
        ---------------------------------------------------

        If _estimatedCompletion <> '' Then
            _estimatedCompletionDate := _estimatedCompletion::timestamp;
        End If;

        ---------------------------------------------------
        -- Force values of some properties for add mode
        ---------------------------------------------------

        If _mode = 'add' Then
            _state := 'Pending Approval';
        End If;

        ---------------------------------------------------
        -- Convert state name to ID
        ---------------------------------------------------

        SELECT state_id
        INTO _stateID
        FROM  t_sample_prep_request_state_name
        WHERE state_name = _state;

        If Not FOUND Then
            RAISE EXCEPTION 'Invalid sample prep request state: "%"', _state;
        End If;

        ---------------------------------------------------
        -- Validate EUS type, proposal, and user list
        --
        -- This procedure accepts a list of EUS User IDs,
        -- so we convert to a string before calling it,
        -- then convert back to an integer afterward
        ---------------------------------------------------

        If Coalesce(_eusUserID, 0) > 0 Then
            _eusUsersList := _eusUserID;
            _eusUserID := Null;
        End If;

        CALL public.validate_eus_usage (
                        _eusUsageType                => _eusUsageType,      -- Input/Output
                        _eusProposalID               => _eusProposalID,     -- Input/Output
                        _eusUsersList                => _eusUsersList,      -- Input/Output
                        _eusUsageTypeID              => _eusUsageTypeID,    -- Output
                        _autoPopulateUserListIfBlank => false,
                        _samplePrepRequest           => false,
                        _experimentID                => 0,
                        _campaignID                  => 0,
                        _addingItem                  => false,
                        _infoOnly                    => false,
                        _message                     => _msg,               -- Output
                        _returnCode                  => _returnCode         -- Output
                    );

        If _returnCode <> '' Then
            _logErrors := false;
            RAISE EXCEPTION 'validate_eus_usage: %', _msg;
        End If;

        If char_length(Coalesce(_eusUsersList, '')) > 0 Then
            _eusUserID := public.try_cast(_eusUsersList, 0);

            If Coalesce(_eusUserID, 0) <= 0 Then
                _eusUserID := Null;
            End If;
        End If;

        ---------------------------------------------------
        -- Validate the work package
        ---------------------------------------------------

        CALL public.validate_wp (
                        _workPackageNumber,
                        _allowNoneWP,
                        _message    => _msg,            -- Output
                        _returnCode => _returnCode);    -- Output

        If _returnCode <> '' Then
            RAISE EXCEPTION '%', _msg;
        End If;

        If Exists (SELECT charge_code FROM t_charge_code WHERE charge_code = _workPackageNumber And deactivated = 'Y') Then
            _message := public.append_to_text(_message, format('Warning: Work Package %s is deactivated', _workPackageNumber));
        ElsIf Exists (SELECT charge_code FROM t_charge_code WHERE charge_code = _workPackageNumber And charge_code_state = 0) Then
            _message := public.append_to_text(_message, format('Warning: Work Package %s is likely deactivated', _workPackageNumber));
        End If;

        -- Make sure the Work Package is capitalized properly

        SELECT charge_code
        INTO _workPackageNumber
        FROM t_charge_code
        WHERE charge_code = _workPackageNumber

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        If _mode = 'update' Then
            -- Cannot update a non-existent entry

            SELECT request_type,
                   state_id
            INTO _requestTypeExisting, _currentStateID
            FROM  t_sample_prep_request
            WHERE prep_request_id = _id;

            If Not FOUND Then
                RAISE EXCEPTION 'Cannot update: RNA prep request ID % does not exist', _id;
            End If;

            -- Changes not allowed if in 'closed' state

            If _currentStateID = 5 And Not Exists (SELECT username FROM V_Operations_Task_Staff_Picklist WHERE username = _callingUser) Then
                RAISE EXCEPTION 'Changes to entry are not allowed if it is in the "Closed" state';
            End If;

            If _requestTypeExisting <> _requestType Then
                RAISE EXCEPTION 'Cannot edit requests of type % with the rna_prep_request page; use https://dms2.pnl.gov/sample_prep_request/report', _requestTypeExisting;
            End If;
        End If;

        If _mode = 'add' Then

            -- Name must be unique

            If Exists (SELECT request_name FROM t_sample_prep_request WHERE request_name = _requestName::citext) Then
                RAISE EXCEPTION 'Cannot add: RNA prep request "%" already exists', _requestName;
            End If;

            -- Make sure the work package number is not inactive

            SELECT CCAS.activation_state,
                   CCAS.activation_state_name
            INTO _activationState, _activationStateName
            FROM t_charge_code CC
                 INNER JOIN t_charge_code_activation_state CCAS
                   ON CC.activation_state = CCAS.activation_state
            WHERE CC.charge_code = _workPackageNumber;

            If _activationState >= 3 Then
                RAISE EXCEPTION 'Cannot use inactive Work Package "%" for a new RNA prep request', _workPackageNumber;
            End If;
        End If;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            INSERT INTO t_sample_prep_request (
                request_name,
                requester_username,
                reason,
                organism,
                biohazard_level,
                campaign,
                number_of_samples,
                sample_name_list,
                sample_type,
                prep_method,
                sample_naming_convention,
                estimated_completion,
                work_package,
                eus_usage_type,
                eus_proposal_id,
                eus_user_id,
                instrument_analysis_specifications,
                state_id,
                instrument_group,
                instrument_name,
                dataset_type,
                request_type
            ) VALUES (
                _requestName,
                _requesterUsername,
                _reason,
                _organism,
                _biohazardLevel,
                _campaign,
                _numberofSamples,
                _sampleNameList,
                _sampleType,
                _prepMethod,
                _sampleNamingConvention,
                _estimatedCompletionDate,
                _workPackageNumber,
                _eusUsageType,
                _eusProposalID,
                _eusUserID,
                _instrumentAnalysisSpecifications,
                _stateID,
                _instrumentGroup,
                _instrumentName,
                _datasetType,
                _requestType
            )
            RETURNING prep_request_id
            INTO _id;

            -- If _callingUser is defined, update system_account in t_sample_prep_request_updates
            If Trim(Coalesce(_callingUser, '')) <> '' Then
                CALL public.alter_entered_by_user ('public', 't_sample_prep_request_updates', 'request_id', _id, _callingUser,
                                                   _entryDateColumnName => 'date_of_change', _enteredByColumnName => 'system_account', _message => _alterEnteredByMessage);
            End If;

        End If;

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            UPDATE t_sample_prep_request
            SET
                request_name = _requestName,
                requester_username = _requesterUsername,
                reason = _reason,
                organism = _organism,
                biohazard_level = _biohazardLevel,
                campaign = _campaign,
                number_of_samples = _numberofSamples,
                sample_name_list = _sampleNameList,
                sample_type = _sampleType,
                prep_method = _prepMethod,
                sample_naming_convention = _sampleNamingConvention,
                estimated_completion = _estimatedCompletionDate,
                work_package = _workPackageNumber,
                eus_proposal_id = _eusProposalID,
                eus_usage_type = _eusUsageType,
                eus_user_id = _eusUserID,
                instrument_analysis_specifications = _instrumentAnalysisSpecifications,
                state_id = _stateID,
                instrument_group = _instrumentGroup,
                instrument_name = _instrumentName,
                dataset_type = _datasetType
            WHERE prep_request_id = _id;

            -- If _callingUser is defined, update system_account in t_sample_prep_request_updates
            If Trim(Coalesce(_callingUser, '')) <> '' Then
                CALL public.alter_entered_by_user ('public', 't_sample_prep_request_updates', 'request_id', _id, _callingUser,
                                                   _entryDateColumnName => 'date_of_change', _enteredByColumnName => 'system_account', _message => _alterEnteredByMessage);
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

END
$$;

COMMENT ON PROCEDURE public.add_update_rna_prep_request IS 'AddUpdateRNAPrepRequest';
