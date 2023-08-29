--
CREATE OR REPLACE PROCEDURE public.lookup_eus_from_experiment_sample_prep
(
    _experimentName text,
    INOUT _eusUsageType text,
    INOUT _eusProposalID text,
    INOUT _eusUsersList text,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Get values for EUS field from the sample prep request
**      associated with the given experiment (if there is one)
**
**  Arguments:
**    _eusUsageType    If this is '(lookup)', will override with the EUS info from the sample prep request (if found)
**    _eusProposalID   If this is '(lookup)', will override with the EUS info from the sample prep request (if found)
**    _eusUsersList    If this is '(lookup)', will override with the EUS info from the sample prep request (if found)
**
**  Auth:   grk
**  Date:   07/11/2007 grk - Ticket #499
**          07/16/2007 grk - Added check for '(lookup)'
**          08/02/2018 mem - T_Sample_Prep_Request now tracks EUS User ID as an integer
**          05/25/2021 mem - Change _eusUsageType to USER_REMOTE if the prep request has UsageType USER_REMOTE, even if _eusUsageType is already USER_ONSITE
**          06/16/2023 mem - Change _eusUsageType to RESOURCE_OWNER if the prep request has UsageType RESOURCE_OWNER and @eusUsageType is 'USER', 'USER_ONSITE', or 'USER_REMOTE'
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _prepRequestID int := 0;
    _usageTypeSamplePrep citext,
    _proposalIdSamplePrep citext,
    _userListSamplePrep citext
    _ovr citext := '(lookup)';
BEGIN
    _message := '';
    _returnCode := '';

    _eusUsageType := Trim(Coalesce(_eusUsageType, ''));
    _eusProposalID := Trim(Coalesce(_eusProposalID, ''));
    _eusUsersList := Trim(Coalesce(_eusUsersList, ''));

    ---------------------------------------------------
    -- Find associated sample prep request for experiment
    ---------------------------------------------------

    --
    SELECT sample_prep_request_id
    INTO _prepRequestID
    FROM t_experiments
    WHERE experiment = _experimentName

    ---------------------------------------------------
    -- If there is no associated sample prep request
    -- we are done
    ---------------------------------------------------

    If Not FOUND Then
        RETURN;
    End If;

    ---------------------------------------------------
    -- Lookup EUS fields from sample prep request
    ---------------------------------------------------

    SELECT Coalesce(EUS_UsageType, ''),
           Coalesce(EUS_Proposal_ID, ''),
           CASE WHEN EUS_User_ID IS NULL THEN ''
                ELSE Cast(EUS_User_ID AS text)
           END
    INTO _usageTypeSamplePrep, _proposalIdSamplePrep, _userListSamplePrep
    FROM t_sample_prep_request
    WHERE prep_request_id = _prepRequestID;

    ---------------------------------------------------
    -- Handle overrides
    ---------------------------------------------------

    _eusUsageType  := CASE WHEN _eusUsageType::citext  = _ovr THEN _usageTypeSamplePrep  ELSE _eusUsageType  END;
    _eusProposalID := CASE WHEN _eusProposalID::citext = _ovr THEN _proposalIdSamplePrep ELSE _eusProposalID END;
    _eusUsersList  := CASE WHEN _eusUsersList::citext  = _ovr THEN _userListSamplePrep   ELSE _eusUsersList  END;

    If _usageTypeSamplePrep = 'USER_REMOTE' And _eusUsageType::citext In ('USER', 'USER_ONSITE') Then
        _message := format('Changed Usage Type to USER_REMOTE based on Prep Request ID %s', _prepRequestID);
        _eusUsageType := 'USER_REMOTE';
    End If;

    If _usageTypeSamplePrep = 'RESOURCE_OWNER' And _eusUsageType::citext In ('USER', 'USER_ONSITE', 'USER_REMOTE') Then
        _message := format('Changed Usage Type to RESOURCE_OWNER based on Prep Request ID %s', _prepRequestID);
        _eusUsageType := 'RESOURCE_OWNER';
    End If;

END
$$;

COMMENT ON PROCEDURE public.lookup_eus_from_experiment_sample_prep IS 'LookupEUSFromExperimentSamplePrep';
