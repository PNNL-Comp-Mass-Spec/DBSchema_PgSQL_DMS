--
-- Name: add_missing_requested_run(text, text, text, text, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_missing_requested_run(IN _dataset text, IN _eusproposalid text DEFAULT ''::text, IN _eususagetype text DEFAULT 'CAP_DEV'::text, IN _eususerslist text DEFAULT ''::text, IN _infoonly boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Creates a requested run for the given dataset, provided it doesn't already have a requested run
**
**      The requested run will be named 'AutoReq_DatasetName'
**
**      Note that this procedure is similar to Add_Requested_Run_To_Existing_Dataset,
**      though that procedure has parameter _templateRequestID which defines
**      an existing requested run ID from which to lookup EUS information
**
**      In contrast, this procedure is intended to be run via automation
**      to add requested runs to existing datasets that don't yet have one
**
**  Auth:   mem
**  Date:   10/20/1010 mem - Initial version
**          05/08/2013 mem - Now setting _wellplateName and _wellNumber to Null when calling Add_Update_Requested_Run
**          01/29/2016 mem - Now calling Get_WP_for_EUS_Proposal to get the best work package for the given EUS Proposal
**          06/13/2017 mem - Rename _operPRN to _requestorPRN when calling Add_Update_Requested_Run
**          05/23/2022 mem - Rename _requestorPRN to _requesterPRN when calling Add_Update_Requested_Run
**          11/25/2022 mem - Update call to Add_Update_Requested_Run to use new parameter name
**          02/27/2023 mem - Use new argument name, _requestName
**          09/13/2023 mem - Ported to PostgreSQL
**          10/10/2023 mem - Rearrange argument order when calling add_update_requested_run
**
*****************************************************/
DECLARE
    _datasetInfo record;
    _requestID int;
    _requestName text;
    _workPackage text := 'none';
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _dataset       := Trim(Coalesce(_dataset, ''));
    _eusProposalID := Trim(Coalesce(_eusProposalID, ''));
    _eusUsageType  := Trim(Coalesce(_eusUsageType, 'CAP_DEV'));
    _eusUsersList  := Trim(Coalesce(_eusUsersList, ''));
    _infoOnly      := Coalesce(_infoOnly, true);

    ---------------------------------------------------
    -- Lookup the dataset details
    ---------------------------------------------------

    SELECT E.Experiment,
           DS.operator_username AS OperatorUsername,
           InstName.Instrument AS InstrumentName,
           DTN.dataset_type AS MsType,
           DS.Separation_Type AS SecSep,
           DS.dataset_id AS DatasetID
    INTO _datasetInfo
    FROM t_dataset DS
         INNER JOIN t_experiments E
           ON DS.exp_id = E.exp_id
         INNER JOIN t_instrument_name InstName
           ON DS.instrument_id = InstName.instrument_id
         INNER JOIN t_dataset_type_name DTN
           ON DS.dataset_type_id = DTN.dataset_type_id
    WHERE DS.dataset = _dataset;

    If Not FOUND Then
        _message := format('Error, dataset not found: %s', _dataset);
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make sure the dataset doesn't already have a requested run
    ---------------------------------------------------

    SELECT RR.request_id
    INTO _requestID
    FROM t_requested_run RR
         INNER JOIN t_dataset DS
           ON RR.dataset_id = DS.dataset_id
    WHERE DS.dataset_id = _datasetInfo.DatasetID;

    If FOUND Then
        _message := format('Error, dataset is already associated with requested run ID %s', _requestID);
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    If _infoOnly Then
        RAISE INFO '';
        RAISE INFO 'Dataset ID: %', _datasetInfo.DatasetID;
        RAISE INFO 'Dataset:    %', _dataset;
        RAISE INFO 'Experiment: %', _datasetInfo.Experiment;
        RAISE INFO 'Operator:   %', _datasetInfo.OperatorUsername;
        RAISE INFO 'Instrument: %', _datasetInfo.InstrumentName;
        RAISE INFO 'DS Type:    %', _datasetInfo.MsType;

        If _message <> '' Then
            RAISE INFO '%', _message;
        End If;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Create the requested run
    ---------------------------------------------------

    _requestName := format('AutoReq_%s', _dataset);

    SELECT work_package
    INTO _workPackage
    FROM public.get_wp_for_eus_proposal(_eusProposalID);

    CALL public.add_update_requested_run (
                    _requestName                 => _requestName,
                    _experimentName              => _datasetInfo.Experiment,
                    _requesterUsername           => _datasetInfo.OperatorUsername,
                    _instrumentGroup             => _datasetInfo.InstrumentName,    -- The instrument name will get auto-updated to instrument group
                    _workPackage                 => _workPackage,
                    _msType                      => _datasetInfo.MsType,            -- Dataset type
                    _instrumentSettings          => 'na',
                    _wellplateName               => null,
                    _wellNumber                  => null,
                    _internalStandard            => 'na',
                    _comment                     => 'Automatically created by Dataset entry',
                    _batch                       => 0,
                    _block                       => 0,
                    _runOrder                    => 0,
                    _eusProposalID               => _eusProposalID,
                    _eusUsageType                => _eusUsageType,
                    _eusUsersList                => _eusUsersList,
                    _mode                        => 'add-auto',
                    _secSep                      => _secSep,            -- Separation group
                    _mrmAttachment               => '',
                    _status                      => 'Completed',
                    _skipTransactionRollback     => true,
                    _autoPopulateUserListIfBlank => true,   -- Auto populate _eusUsersList if blank since this is an Auto-Request
                    _callingUser                 => '',
                    _vialingConc                 => null,
                    _vialingVol                  => null,
                    _stagingLocation             => null,
                    _requestIDForUpdate          => null,
                    _logDebugMessages            => false,
                    _request                     => _requestID,                 -- Output
                    _resolvedInstrumentInfo      => _resolvedInstrumentInfo,    -- Output
                    _message                     => _message,                   -- Output
                    _returnCode                  => _returnCode);               -- Output

    If _returnCode <> '' Or Coalesce(_requestID, 0) = 0 Then
        If Coalesce(_message, '') = '' Then
            _message := 'Error creating requested run';
        End If;

        If _returnCode = '' Then
            _returnCode := 'U5203';
        End If;

        RETURN;
    End If;

    UPDATE t_requested_run
    SET dataset_id = _datasetID
    WHERE request_id = _requestID;

    If Trim(Coalesce(_message, '')) = '' Then
        _message := 'Success';
    End If;

    RAISE INFO 'Created requested run ID % for dataset %: %', _requestID, _dataset, _message;

END
$$;


ALTER PROCEDURE public.add_missing_requested_run(IN _dataset text, IN _eusproposalid text, IN _eususagetype text, IN _eususerslist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_missing_requested_run(IN _dataset text, IN _eusproposalid text, IN _eususagetype text, IN _eususerslist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_missing_requested_run(IN _dataset text, IN _eusproposalid text, IN _eususagetype text, IN _eususerslist text, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'AddMissingRequestedRun';

