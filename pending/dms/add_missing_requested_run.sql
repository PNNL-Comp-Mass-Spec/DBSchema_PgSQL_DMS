--
CREATE OR REPLACE PROCEDURE public.add_missing_requested_run
(
    _dataset text,
    _eusProposalID text = '',
    _eusUsageType text = 'Cap_Dev',
    _eusUsersList text = '',
    _infoOnly boolean = true,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Creates a requested run for the given dataset,
**      provided it doesn't already have a requested run
**
**      The requested run will be named 'AutoReq_DatasetName'
**
**
**      Note that this procedure is similar to AddRequestedRunToExistingDataset,
**      though that procedure has parameter _templateRequestID which defines
**      an existing requested run ID from which to lookup EUS information
**
**      In contrast, this procedure is intended to be run via automation
**      to add requested runs to existing datasets that don't yet have one
**
**
**  Auth:   mem
**  Date:   10/20/1010 mem - Initial version
**          05/08/2013 mem - Now setting _wellplateName and _wellNumber to Null when calling AddUpdateRequestedRun
**          01/29/2016 mem - Now calling GetWPforEUSProposal to get the best work package for the given EUS Proposal
**          06/13/2017 mem - Rename _operPRN to _requestorPRN when calling AddUpdateRequestedRun
**          05/23/2022 mem - Rename _requestorPRN to _requesterPRN when calling AddUpdateRequestedRun
**          11/25/2022 mem - Update call to AddUpdateRequestedRun to use new parameter name
**          02/27/2023 mem - Use new argument name, _requestName
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetInfo record;
    _requestID int;
    _requestName text;
    _workPackage text := 'none';
    _requestID int;
BEGIN
    _message := '';
    _returnCode:= '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _dataset := Coalesce(_dataset, '');
    _infoOnly := Coalesce(_infoOnly, true);

    ---------------------------------------------------
    -- Lookup the dataset details
    ---------------------------------------------------

    SELECT V.Experiment,
           D.operator_username As OperatorUsername,
           V.Instrument As InstrumentName,
           V.Type As MsType,
           V.Separation_Type As SecSep,
           D.dataset_id As DatasetID
    INTO _datasetInfo
    FROM V_Dataset_Detail_Report_Ex V
         INNER JOIN t_dataset D
           ON V.dataset = D.dataset
    WHERE V.dataset = _dataset

    If Not FOUND Then
        _message := format('Error, Dataset not found: %s', _dataset);
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Make sure the dataset doesn't already have a requested run
    ---------------------------------------------------

    SELECT t_requested_run.request_id
    INTO _requestID
    FROM t_requested_run
         INNER JOIN t_dataset
           ON t_requested_run.dataset_id = t_dataset.dataset_id
    WHERE t_dataset.dataset = _dataset;

    If FOUND Then
        _message := format('Error, Dataset is already associated with Request ID %s', _requestID);
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    If _infoOnly Then
        SELECT _datasetInfo.DatasetID AS DatasetID,
               _dataset AS Dataset,
               _datasetInfo.Experiment,
               _datasetInfo.OperatorUsername AS Operator,
               _datasetInfo.InstrumentName AS Instrument,
               _datasetInfo.MsType AS DS_Type,
               _message AS Message
    Else
        -- Create the request

        _requestName := format('AutoReq_%s', _dataset);

        SELECT work_package
        INTO _workPackage
        FROM public.get_wp_for_eus_proposal (_eusProposalID);

        CALL add_update_requested_run(
                                _requestName => _requestName,
                                _experimentName =>_datasetInfo.Experiment,
                                _requesterUsername => _datasetInfo.OperatorUsername,
                                _instrumentName => _datasetInfo.InstrumentName,
                                _workPackage => _workPackage,
                                _msType => _datasetInfo.MsType,     -- Dataset type
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
                                _mRMAttachment => '',
                                _status => 'Completed',
                                _skipTransactionRollback => true,
                                _autoPopulateUserListIfBlank => true);        -- Auto populate _eusUsersList if blank since this is an Auto-Request

        If _returnCode <> '' Or Coalesce(_requestID, 0) = 0 Then
            If Coalesce(_message, '') = '' Then
                _message := 'Error creating requested run';
            End If;

            If _returnCode = '' Then
                _returnCode := 'U5203'
            End If;

            RETURN;
        Else
            UPDATE t_requested_run
            SET dataset_id = _datasetID
            WHERE (request_id = _requestID)

            If Coalesce(_message, '') = '' Then
                _message := 'Success';
            End If;

            RAISE INFO 'Dataset %, request %: %', _dataset, _requestID, _message;

        End If;
    End If;

    If _returnCode <> '' Then
        RAISE INFO '%', _message;
    End If;

END
$$;

COMMENT ON PROCEDURE public.add_missing_requested_run IS 'AddMissingRequestedRun';
