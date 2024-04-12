--
-- Name: lookup_eus_from_experiment_sample_prep(text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.lookup_eus_from_experiment_sample_prep(IN _experimentname text, INOUT _eususagetype text DEFAULT ''::text, INOUT _eusproposalid text DEFAULT ''::text, INOUT _eususerslist text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Get values for EUS field from the sample prep request associated with the given experiment (if there is one)
**
**  Arguments:
**    _experimentName   Experiment name
**    _eusUsageType     Input/output: EUS usage type;  if this is '(lookup)', will override with the EUS info from the sample prep request (if found)
**    _eusProposalID    Input/output: EUS proposal id; if this is '(lookup)', will override with the EUS info from the sample prep request (if found)
**    _eusUsersList     Input/output: EUS user list;   if this is '(lookup)', will override with the EUS info from the sample prep request (if found)
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   grk
**  Date:   07/11/2007 grk - Ticket #499
**          07/16/2007 grk - Added check for '(lookup)'
**          08/02/2018 mem - T_Sample_Prep_Request now tracks EUS User ID as an integer
**          05/25/2021 mem - Change _eusUsageType to USER_REMOTE if the prep request has UsageType USER_REMOTE, even if _eusUsageType is already USER_ONSITE
**          06/16/2023 mem - Change _eusUsageType to RESOURCE_OWNER if the prep request has UsageType RESOURCE_OWNER and @eusUsageType is 'USER', 'USER_ONSITE', or 'USER_REMOTE'
**          09/13/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _prepRequestID int;
    _usageTypeSamplePrep citext;
    _proposalIdSamplePrep citext;
    _userListSamplePrep citext;
    _ovr citext := '(lookup)';
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _experimentName := Trim(Coalesce(_experimentName, ''));
    _eusUsageType   := Trim(Coalesce(_eusUsageType, ''));
    _eusProposalID  := Trim(Coalesce(_eusProposalID, ''));
    _eusUsersList   := Trim(Coalesce(_eusUsersList, ''));

    ---------------------------------------------------
    -- Find associated sample prep request for experiment
    ---------------------------------------------------

    SELECT sample_prep_request_id
    INTO _prepRequestID
    FROM t_experiments
    WHERE experiment = _experimentName::citext;

    If Not FOUND Then
        _message := format('Experiment does not exist: %s',_experimentName);

        RAISE WARNING '%', _message;
        _returnCode := 'U5201';
        RETURN;
    End If;

    If Coalesce(_prepRequestID, 0) = 0 Then
        -- There is no associated sample prep request
        RETURN;
    End If;

    ---------------------------------------------------
    -- Lookup EUS fields from sample prep request
    ---------------------------------------------------

    SELECT Coalesce(eus_usage_type, ''),
           Coalesce(eus_proposal_id, ''),
           CASE WHEN eus_user_id IS NULL THEN ''
                ELSE eus_user_id::text
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
        _message := format('Changed usage type to USER_REMOTE based on prep request ID %s', _prepRequestID);
        _eusUsageType := 'USER_REMOTE';
    End If;

    If _usageTypeSamplePrep = 'RESOURCE_OWNER' And _eusUsageType::citext In ('USER', 'USER_ONSITE', 'USER_REMOTE') Then
        _message := format('Changed usage type to RESOURCE_OWNER based on prep request ID %s', _prepRequestID);
        _eusUsageType := 'RESOURCE_OWNER';
    End If;

END
$$;


ALTER PROCEDURE public.lookup_eus_from_experiment_sample_prep(IN _experimentname text, INOUT _eususagetype text, INOUT _eusproposalid text, INOUT _eususerslist text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE lookup_eus_from_experiment_sample_prep(IN _experimentname text, INOUT _eususagetype text, INOUT _eusproposalid text, INOUT _eususerslist text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.lookup_eus_from_experiment_sample_prep(IN _experimentname text, INOUT _eususagetype text, INOUT _eusproposalid text, INOUT _eususerslist text, INOUT _message text, INOUT _returncode text) IS 'LookupEUSFromExperimentSamplePrep';

