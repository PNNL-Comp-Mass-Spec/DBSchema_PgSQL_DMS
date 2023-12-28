--
CREATE OR REPLACE PROCEDURE public.add_update_campaign
(
    _campaignName text,
    _projectName text,
    _progmgrUsername text,
    _piUsername text,
    _technicalLead text,
    _samplePreparationStaff text,
    _datasetAcquisitionStaff text,
    _informaticsStaff text,
    _collaborators text,
    _comment text,
    _state text,
    _description text,
    _externalLinks text,
    _eprList text,
    _eusProposalList text,
    _organisms text,
    _experimentPrefixes text,
    _dataReleaseRestrictions text,
    _fractionEMSLFunded text = '0',
    _eusUsageType text = 'USER_ONSITE',
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
**      Adds new or updates an existing campaign
**
**  Arguments:
**    _campaignName                 Campaign name
**    _projectName                  Project name
**    _progmgrUsername              Project Manager username (required)
**    _piUsername                   Principal Investigator username (required)
**    _technicalLead                Technical Lead
**    _samplePreparationStaff       Sample Prep Staff
**    _datasetAcquisitionStaff      Dataset acquisition staff
**    _informaticsStaff             Informatics staff
**    _collaborators                Collaborators
**    _comment                      Comment
**    _state                        State: 'Active' or 'Inactive'
**    _description                  Campaign description
**    _externalLinks                External links, e.g. https://pubmed.ncbi.nlm.nih.gov/32284590/
**    _eprList                      PNNL project number, e.g. 71275
**    _eusProposalList              EUS proposal, e.g. 33200
**    _organisms                    Comma-separated list of organisms
**    _experimentPrefixes           One or more experiment name prefixes
**    _dataReleaseRestrictions      Data release restriction ID, e.g. 0 for 'Not yet approved for release'; see table t_data_release_restrictions
**    _fractionEMSLFunded           Fraction EMSL funded; value between 0 and 1
**    _eusUsageType                 EUS usage type
**    _mode                         Mode: 'add' or 'update'
**    _message                      Output message
**    _returnCode                   Return code
**    _callingUser                  Calling user username
**
**  Auth:   grk
**  Date:   01/08/2002
**          03/25/2008 mem - Added optional parameter _callingUser; if provided, will call alter_event_log_entry_user (Ticket #644)
**          01/15/2010 grk - Added new fields (http://prismtrac.pnl.gov/trac/ticket/753)
**          02/05/2010 grk - Split team member field
**          02/07/2010 grk - Added validation for campaign name
**          02/07/2010 mem - No longer validating _progmgrUsername or _piUsername in this procedure since this is now handled by UpdateResearchTeamForCampaign
**          03/17/2010 grk - DataReleaseRestrictions (Ticket http://prismtrac.pnl.gov/trac/ticket/758)
**          04/21/2010 grk - Use try-catch for error handling
**          10/27/2011 mem - Added parameter _fractionEMSLFunded
**          12/01/2011 mem - Updated _fractionEMSLFunded to be a required value
**                         - Now calling alter_event_log_entry_user for updates to Fraction_EMSL_Funded or Data_Release_Restrictions
**          10/23/2012 mem - Now validating that _fractionEMSLFunded is a number between 0 and 1 using a real (since conversion of 100 to numeric(3,2) causes an overflow error)
**          06/02/2015 mem - Replaced IDENT_CURRENT with SCOPE_IDENTITY()
**          02/23/2016 mem - Add set XACT_ABORT on\
**          02/26/2016 mem - Define a default for _fractionEMSLFunded
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          07/20/2016 mem - Tweak error messages
**          11/18/2016 mem - Log try/catch errors using post_log_entry
**          11/23/2016 mem - Include the campaign name when calling post_log_entry from within the catch block
**                         - Trim trailing and leading spaces from input parameters
**          12/05/2016 mem - Exclude logging some try/catch errors
**          12/16/2016 mem - Use _logErrors to toggle logging errors caught by the try/catch block
**          06/13/2017 mem - Disable logging when the campaign name has invalid characters
**          06/14/2017 mem - Allow _fractionEMSLFundedValue to be empty
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/18/2017 mem - Disable logging certain messages to T_Log_Entries
**          05/26/2021 mem - Add _eusUsageType
**          09/29/2021 mem - Assure that EUS Usage Type is 'USER_ONSITE' if associated with a Resource Owner proposal
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          05/16/2022 mem - Fix potential arithmetic overflow error when parsing _fractionEMSLFunded
**          11/01/2023 mem - Remove unreachable code when validating campaign name
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _msg text;
    _stateID int;
    _eusUsageTypeID int := 0;
    _eusUsageTypeEnabled int := 0;
    _proposalType text;
    _percentEMSLFunded int;
    _fractionEMSLFundedValue real := 0;
    _fractionEMSLFundedToStore numeric(3,2) := 0;
    _logErrors boolean := false;
    _campaignID int := 0;
    _researchTeamID int := 0;
    _dataReleaseRestrictionsID int;
    _badCh text;
    _transName text := 'AddUpdateCampaign';
    _idConfirm int := 0;
    _debugMsg text;
    _logMessage text;
    _targetType int;
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

        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _campaignName    := Trim(Coalesce(_campaignName, ''));
        _projectName     := Trim(Coalesce(_projectName, ''));
        _progmgrUsername := Trim(Coalesce(_progmgrUsername, ''));
        _piUsername      := Trim(Coalesce(_piUsername, ''));
        _mode            := Trim(Lower(Coalesce(_mode, '')));

        If char_length(_campaignName) < 1 Then
            RAISE EXCEPTION 'Campaign name must be specified';
        End If;

        If char_length(_projectName) < 1 Then
            RAISE EXCEPTION 'Project Number must be specified';
        End If;

        If char_length(_progmgrUsername) < 1 Then
            RAISE EXCEPTION 'Project Manager username must be specified';
        End If;

        If char_length(_piUsername) < 1 Then
            RAISE EXCEPTION 'Principle Investigator username must be specified';
        End If;

        ---------------------------------------------------
        -- Is entry already in database?
        ---------------------------------------------------

        --
        SELECT campaign_id,
               Coalesce(research_team, 0)
        INTO _campaignID, _researchTeamID
        FROM t_campaign
        WHERE campaign = _campaignName

        -- Cannot create an entry that already exists
        --
        If _campaignID <> 0 and _mode = 'add' Then
            RAISE EXCEPTION 'Cannot add: Campaign "%" already in database', _campaignName;
        End If;

        -- Cannot update a non-existent entry
        --
        If _campaignID = 0 and _mode = 'update' Then
            RAISE EXCEPTION 'Cannot update: Campaign "%" is not in database', _campaignName;
        End If;

        ---------------------------------------------------
        -- Resolve data release restriction name to ID
        ---------------------------------------------------

        SELECT release_restriction_id
        INTO _dataReleaseRestrictionsID
        FROM t_data_release_restrictions
        WHERE release_restriction = _dataReleaseRestrictions;

        If Not FOUND Then
            RAISE EXCEPTION 'Could not resolve data release restriction; please select a valid entry from the list';
        End If;

        ---------------------------------------------------
        -- Validate Fraction EMSL Funded
        -- If _fractionEMSLFunded is empty we treat it as a Null value
        ---------------------------------------------------

        _fractionEMSLFunded := Trim(Coalesce(_fractionEMSLFunded, ''));
        If char_length(_fractionEMSLFunded) > 0 Then
            _fractionEMSLFundedValue := public.try_cast(_fractionEMSLFunded, null::real);

            If _fractionEMSLFundedValue Is Null Then
                RAISE EXCEPTION 'Fraction EMSL Funded must be a number between 0 and 1';
            End If;

            If _fractionEMSLFundedValue > 1 Then
                _msg := format('Fraction EMSL Funded must be a number between 0 and 1 (%s is greater than 1)', _fractionEMSLFunded);
                RAISE EXCEPTION '%', _msg;
            End If;

            If _fractionEMSLFundedValue < 0 Then
                _msg := format('Fraction EMSL Funded must be a number between 0 and 1 (%s is less than 0)', _fractionEMSLFunded);
                RAISE EXCEPTION '%', _msg;
            End If;

            _fractionEMSLFundedToStore := _fractionEMSLFunded::numeric(3,2)

        Else
            _fractionEMSLFundedToStore := 0;
        End If;

        ---------------------------------------------------
        -- Validate campaign name
        ---------------------------------------------------

        If _mode = 'add' Then
            _badCh := public.validate_chars(_campaignName, '');

            -- Campaign names can have spaces, so remove '[space]' from _badCh if present
            _badCh := Replace(_badCh, '[space]', '');

            If _badCh <> '' Then
                RAISE EXCEPTION 'Campaign name may not contain the character(s) "%"', _badCh;
            End If;
        End If;

        ---------------------------------------------------
        -- Validate EUS Usage Type
        ---------------------------------------------------

        _eusUsageType := Trim(Coalesce(_eusUsageType, ''));

        If char_length(_eusUsageType) = 0 Then
            _eusUsageType := 'USER_ONSITE';
        End If;

        SELECT eus_usage_type_id,
               enabled_campaign
        INTO _eusUsageTypeID, _eusUsageTypeEnabled
        FROM t_eus_usage_type
        WHERE eus_usage_type = _eusUsageType

        If Not FOUND Then
            RAISE EXCEPTION 'Unrecognized EUS Usage Type: %', _eusUsageType;
        End If;

        If _eusUsageTypeEnabled = 0 Then
            RAISE EXCEPTION 'EUS Usage Type is not allowed for campaigns: %', _eusUsageType;
        End If;

        If char_length(Coalesce(_eusProposalList, '')) > 0 Then
            If _eusUsageType = 'CAP_DEV' Then
                -- CAP_DEV should not be used when one or more EUS proposals are defined for a campaign
                RAISE EXCEPTION ('Please choose usage type USER_ONSITE if this campaign''s samples are for an onsite user or are for a Resource Owner project; choose USER_REMOTE if for an EMSL user';
            End If;

            -- If _eusProposalList has a single proposal, get the proposal type then validate _eusUsageType
            -- If multiple proposals are defined, the validation is skipped
            SELECT proposal_type
            INTO _proposalType
            FROM t_eus_proposals
            WHERE proposal_id = _eusProposalList

            If Coalesce(_proposalType, '') = 'Resource Owner' And _eusUsageType::citext In ('USER_REMOTE', '') Then
                _eusUsageType := 'USER_ONSITE';
                _message := 'Auto-updated EUS usage type to USER_ONSITE since this campaign has a Resource Owner project';

                SELECT eus_usage_type_id
                INTO _eusUsageTypeID
                FROM t_eus_usage_type
                WHERE eus_usage_type = _eusUsageType
            End If;
        End If;

        ---------------------------------------------------
        -- Validate Fraction EMSL Funded
        ---------------------------------------------------

        If _fractionEMSLFundedToStore > 1 Then
            _msg := format('Fraction EMSL Funded must be a number between 0 and 1 (%s is greater than 1)', _fractionEMSLFunded);
            RAISE EXCEPTION '%', _msg;
        End If;

        If _fractionEMSLFundedToStore < 0 Then
            _msg := format('Fraction EMSL Funded must be a number between 0 and 1 (%s is less than 0)', _fractionEMSLFunded);
            RAISE EXCEPTION '%', _msg;
        End If;

        _logErrors := true;

        ---------------------------------------------------
        -- Action for add mode
        ---------------------------------------------------

        If _mode = 'add' Then

            ---------------------------------------------------
            -- Create research team
            ---------------------------------------------------

            CALL public.update_research_team_for_campaign
                                _campaignName,
                                _progmgrUsername,
                                _piUsername,
                                _technicalLead,
                                _samplePreparationStaff,
                                _datasetAcquisitionStaff,
                                _informaticsStaff,
                                _collaborators,
                                _researchTeamID output,
                                _msg output
            --
            If _returnCode <> '' Then
                _message := _msg;
                RAISE EXCEPTION '%', _message;
            End If;

            ---------------------------------------------------
            -- Create campaign
            ---------------------------------------------------

            INSERT INTO t_campaign (
                campaign,
                project,
                comment,
                state,
                description,
                external_links,
                epr_list,
                eus_proposal_list,
                organisms,
                experiment_prefixes,
                created,
                research_team,
                data_release_restrictions,
                fraction_emsl_funded,
                eus_usage_type_id
            ) VALUES (
                _campaignName,
                _projectName,
                _comment,
                _state,
                _description,
                _externalLinks,
                _eprList,
                _eusProposalList,
                _organisms,
                _experimentPrefixes,
                CURRENT_TIMESTAMP,
                _researchTeamID,
                _dataReleaseRestrictionsID,
                _fractionEMSLFundedToStore,
                _eusUsageTypeID
            )
            RETURNING campaign_id
            INTO _campaignID;

            -- As a precaution, query t_campaign using campaign name to make sure we have the correct campaign ID
            --
            SELECT campaign_id
            INTO _idConfirm
            FROM t_campaign
            WHERE campaign = _campaignName;

            If _campaignID <> Coalesce(_idConfirm, _campaignID) Then
                _debugMsg := format('Warning: Inconsistent identity values when adding campaign %s: Found ID %s but the INSERT INTO query reported %s',
                                    _campaignName, _idConfirm, _campaignID);

                CALL post_log_entry ('Error', _debugMsg, 'Add_Update_Campaign');

                _campaignID := _idConfirm;
            End If;

            _stateID := 1;
            _percentEMSLFunded := (_fractionEMSLFundedToStore * 100)::int;

            -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
            If Trim(Coalesce(_callingUser, '')) <> '' Then
                _targetType := 1;
                CALL public.alter_event_log_entry_user ('public', _targetType, _campaignID, _stateID, _callingUser, _message => _alterEnteredByMessage);

                _targetType := 9;
                CALL public.alter_event_log_entry_user ('public', _targetType, _campaignID, _percentEMSLFunded, _callingUser, _message => _alterEnteredByMessage);

                _targetType := 10;
                CALL public.alter_event_log_entry_user ('public', _targetType, _campaignID, _dataReleaseRestrictionsID, _callingUser, _message => _alterEnteredByMessage);
            End If;

        End If; -- add mode

        ---------------------------------------------------
        -- Action for update mode
        ---------------------------------------------------

        If _mode = 'update' Then

            ---------------------------------------------------
            -- Update campaign
            ---------------------------------------------------

            UPDATE t_campaign
            SET project = _projectName,
                comment = _comment,
                state = _state,
                description = _description,
                external_links = _externalLinks,
                epr_list = _eprList,
                eus_proposal_list = _eusProposalList,
                organisms = _organisms,
                experiment_prefixes = _experimentPrefixes,
                data_release_restrictions = _dataReleaseRestrictionsID,
                fraction_emsl_funded = _fractionEMSLFundedToStore,
                eus_usage_type_id = _eusUsageTypeID
            WHERE campaign = _campaignName;

            ---------------------------------------------------
            -- Update research team membershipe
            ---------------------------------------------------

            CALL public.update_research_team_for_campaign (
                                _campaignName,
                                _progmgrUsername,
                                _piUsername,
                                _technicalLead,
                                _samplePreparationStaff,
                                _datasetAcquisitionStaff,
                                _informaticsStaff,
                                _collaborators,
                                _researchTeamID => _researchTeamID,     -- Output
                                _message => _msg);                      -- Output

            If _returnCode <> '' Then
                _message := _msg;
                RAISE EXCEPTION '%', _message;
            End If;

            _percentEMSLFunded := (_fractionEMSLFundedToStore * 100)::int

            -- If _callingUser is defined, call public.alter_event_log_entry_user to alter the entered_by field in t_event_log
            If Trim(Coalesce(_callingUser, '')) <> '' Then
                _targetType := 9;
                CALL public.alter_event_log_entry_user ('public', _targetType, _campaignID, _percentEMSLFunded, _callingUser, _message => _alterEnteredByMessage);

                _targetType := 10;
                CALL public.alter_event_log_entry_user ('public', _targetType, _campaignID, _dataReleaseRestrictionsID, _callingUser, _message => _alterEnteredByMessage);
            End If;
        End If; -- update mode

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _logMessage := format('%s; Campaign %s', _exceptionMessage, _campaignName);

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

COMMENT ON PROCEDURE public.add_update_campaign IS 'AddUpdateCampaign';
