--
CREATE OR REPLACE PROCEDURE public.duplicate_dataset
(
    _sourceDataset text,
    _newDataset text,
    _newComment text = '',
    _newCaptureSubfolder text = '',
    _newOperatorUsername text = '',
    _datasetStateID int = 1,
    _infoOnly boolean = true,
    INOUT _message text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Duplicates a dataset by adding a new row to T_Dataset and calling AddUpdateRequestedRun
**
**  Arguments:
**    _sourceDataset         Existing dataset to copy
**    _newDataset            New dataset name
**    _newComment            New dataset comment; use source dataset's comment if blank; use a blank comment if '.' or '<blank>' or '<empty>'
**    _newCaptureSubfolder   Capture subfolder name; use source dataset's capture subfolder if blank
**    _newOperatorUsername   Operator username
**    _datasetStateID        1 for a new dataset, which will create a dataset capture job; 3=Complete; 4=Inactive; 13=Holding
**    _infoOnly              False to create the dataset, true to preview
**    _message               Output message
**
**  Auth:   mem
**  Date:   12/12/2018 mem - Initial version
**          08/19/2020 mem - Add _newOperatorUsername
**                         - Add call to UpdateCachedDatasetInstruments
**          10/19/2020 mem - Rename the instrument group column to instrument_group
**          12/08/2020 mem - Lookup Username from T_Users using the validated user ID
**          05/23/2022 mem - Rename _requestorPRN to _requesterPRN when calling AddUpdateRequestedRun
**          11/25/2022 mem - Rename variable and update call to AddUpdateRequestedRun to use new parameter name
**          02/27/2023 mem - Use new argument name, _requestName
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE

    _myRowCount int := 0;
    _datasetInfo record
    _datasetID int := 0;
    _requestedRunInfo record;
    _requestName text;
    _eusUsersList text := '';
    _requestID int;
    _userID int;
    _matchCount int;
    _newUsername text;
    _transName text := 'AddNewDataset';
BEGIN
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _sourceDataset := Coalesce(_sourceDataset, '');
    _newDataset := Coalesce(_newDataset, '');
    _newComment := Coalesce(_newComment, '');
    _newCaptureSubfolder := Coalesce(_newCaptureSubfolder, '');
    _newOperatorUsername := Coalesce(_newOperatorUsername, '');
    _datasetStateID := Coalesce(_datasetStateID, 1);
    _infoOnly := Coalesce(_infoOnly, true);

    _message := '';

    If _sourceDataset = '' Then
        _message := '_sourceDataset is empty';
        RAISE ERROR '%', _message;

        RETURN;
    End If;

    If _newDataset = '' Then
        _message := '_newDataset is empty';
        RAISE ERROR '%', _message;

        RETURN;
    End If;

    If Not Exists (Select * From t_dataset Where dataset = _sourceDataset) Then
        _message := 'Source dataset not found in t_dataset: ' || _sourceDataset;
        RAISE ERROR '%', _message;

        RETURN;
    End If;

    If Exists (Select * From t_dataset Where dataset = _newDataset) Then
        _message := 't_dataset already has dataset: ' || _newDataset;
        RAISE ERROR '%', _message;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Lookup the source dataset info, including Experiment name
    ---------------------------------------------------
    --
    SELECT D.dataset_id AS SourceDatasetId
           D.operator_username AS OperatorUsername,
           D.comment AS Comment,
           D.instrument_id AS InstrumentID,
           D.dataset_type_ID AS DatasetTypeID,
           D.well AS WellNum,
           D.separation_type AS SecSep,
           D.storage_path_ID AS StoragePathID,
           D.exp_id AS ExperimentID,
           D.dataset_rating_id AS RatingID,
           D.lc_column_ID AS ColumnID,
           D.wellplate AS Wellplate,
           D.internal_standard_id AS IntStdID,
           D.capture_subfolder AS CaptureSubfolder,
           D.cart_config_id AS CartConfigID,
           E.experiment AS ExperimentName
    INTO _datasetInfo
    FROM t_dataset D
         INNER JOIN t_experiments E
           ON D.exp_id = E.exp_id
    WHERE D.dataset = _sourceDataset

    If Not FOUND Then
        _message := 'Dataset not found: ' || _sourceDataset;
        RAISE ERROR '%', _message;

        RETURN;
    End If;

    If _newComment <> '' Then
        _datasetInfo.Comment := Trim(_newComment);

        If _datasetInfo.Comment::citext In ('.', '<blank>', 'blank', '<empty>', 'empty') Then
            _datasetInfo.Comment := '';
        End If;
    End If;

    If _newCaptureSubfolder <> '' Then
        _datasetInfo.CaptureSubfolder := _newCaptureSubfolder;
    End If;

    ---------------------------------------------------
    -- Lookup requested run information
    ---------------------------------------------------
    --
    SELECT RR.request_id As SourceDatasetRequestID,
           RR.instrument_group As InstrumentName,
           RR.work_package As WorkPackage,
           RR.instrument_setting As InstrumentSettings,
           DTN.Dataset_Type As MsType,
           RR.separation_group As SeparationGroup,
           RR.eus_proposal_id As EusProposalID,
           EUT.eus_usage_type As EusUsageType
    INTO _requestedRunInfo
    FROM t_requested_run AS RR
         INNER JOIN t_dataset_rating_name AS DTN
           ON RR.request_type_id = DTN.DST_Type_ID
         INNER JOIN t_eus_usage_type AS EUT
           ON RR.eus_usage_type_id = EUT.request_id
    WHERE dataset_id = _datasetInfo.SourceDatasetId

    If Not FOUND Then
        _message := 'Source dataset does not have a requested run; use AddMissingRequestedRun to add one';
        RAISE ERROR '%', _message;

        RETURN;
    End If;

    _eusUsersList := get_requested_run_eus_users_list(_requestedRunInfo.SourceDatasetRequestID, 'I');

    If _newOperatorUsername <> '' Then
        ---------------------------------------------------
        -- Resolve user ID for operator username
        ---------------------------------------------------

        _userID := public.get_user_id (_newOperatorUsername);

        If _userID > 0 Then
            -- Function get_user_id recognizes both a username and the form 'LastName, FirstName (Username)'
            -- Assure that _operatorUsername contains simply the username
            --
            SELECT username
            INTO _datasetInfo.OperatorUsername
            FROM t_users
            WHERE user_id = _userID;
        Else
            -- Could not find entry in database for username _newOperatorUsername
            -- Try to auto-resolve the name

            Call auto_resolve_name_to_username (_newOperatorUsername, _matchCount => _matchCount, _matchingUsername => _newUsername, _matchingUserID => _userID);

            If _matchCount = 1 Then
                -- Single match found; update _operatorUsername
                _datasetInfo.OperUsername := _newUsername;
            Else
                _message := 'Could not find entry in database for operator username ' || _newOperatorUsername;
                RAISE ERROR '%', _message;
                RETURN;
            End If;
        End If;
    End If;

    If _infoOnly Then
        -- ToDo: Update the following two queries to use RAISE INFO
        --
        SELECT _newDataset AS Dataset,
               _datasetInfo.OperUsername AS Operator_Username,
               _datasetInfo.Comment AS Comment,
               CURRENT_TIMESTAMP AS Created,
               _datasetInfo.InstrumentID AS Instrument_ID,
               _datasetInfo.DatasetTypeID AS DS_TypeID,
               _datasetInfo.WellNum AS WellNum,
               _datasetInfo.SecSep AS SecondarySep,
               _datasetStateID AS DatasetStateID,
               _newDataset AS Dataset_Folder,
               _datasetInfo.StoragePathID AS StoragePathID,
               _datasetInfo.ExperimentID AS ExperimentID,
               _datasetInfo.RatingID AS RatingID,
               _datasetInfo.ColumnID AS ColumnID,
               _datasetInfo.Wellplate AS Wellplate,
               _datasetInfo.IntStdID AS InternalStandardID,
               _datasetInfo.CaptureSubfolder AS Capture_SubFolder,
               _datasetInfo.CartConfigID AS CartConfigID;

        Select 'AutoReq_' || _newDataset As Requested_Run,
                                _datasetInfo.ExperimentName As Experiment,
                                _datasetInfo.OperatorUsername As Operator_Username,
                                _requestedRunInfo.InstrumentName As Instrument,
                                _requestedRunInfo.WorkPackage As WP,
                                _requestedRunInfo.MsType As MSType,
                                _requestedRunInfo.SeparationGroup As SeparationGroup,
                                _requestedRunInfo.InstrumentSettings As Instrument_Settings,
                                _datasetInfo.Wellplate As Wellplate,
                                _datasetInfo.WellNum As WellNum,
                                'na' As InternalStandard,
                                'Automatically created by Dataset entry' As Comment,
                                _requestedRunInfo.EusProposalID As EUS_ProposalID,
                                _requestedRunInfo.EusUsageType As EUS_ProposalType,
                                _eusUsersList As EUS_ProposalUsers,
                                _requestedRunInfo.SeparationGroup As SeparationGroup,
                                '' As MRMAttachment,
                                'Completed' As Status

    Else

        Begin transaction _transName

        ---------------------------------------------------
        -- Create the new dataset
        ---------------------------------------------------
        --
        INSERT INTO t_dataset (
            dataset,
            operator_username,
            comment,
            created,
            instrument_id,
            dataset_type_ID,
            well,
            separation_type,
            dataset_state_id,
            folder_name,
            storage_path_ID,
            exp_id,
            dataset_rating_id,
            lc_column_ID,
            wellplate,
            internal_standard_ID,
            capture_subfolder,
            cart_config_id
        ) VALUES (
            _newDataset,
            _datasetInfo.OperUsername,
            _datasetInfo.Comment,
            CURRENT_TIMESTAMP,
            _datasetInfo.InstrumentID,
            _datasetInfo.DatasetTypeID,
            _datasetInfo.WellNum,
            _datasetInfo.SecSep,
            _datasetStateID,
            _newDataset,        -- folder_name
            _datasetInfo.StoragePathID,
            _datasetInfo.ExperimentID,
            _datasetInfo.RatingID,
            _datasetInfo.ColumnID,
            _datasetInfo.Wellplate,
            _datasetInfo.IntStdID,
            _datasetInfo.CaptureSubfolder,
            _datasetInfo.CartConfigID
        )
        RETURNING dataset_id
        INTO _datasetID;

        ---------------------------------------------------
        -- Create a requested run
        ---------------------------------------------------
        --
        _requestName := 'AutoReq_' || _newDataset;

        Call add_update_requested_run (
                _requestName => _requestName,
                _experimentName => _datasetInfo.ExperimentName,
                _requesterUsername => _datasetInfo.OperUsername,
                _instrumentName => _requestedRunInfo.InstrumentName,
                _workPackage => _requestedRunInfo.WorkPackage,
                _msType => _requestedRunInfo.MsType,
                _instrumentSettings => _requestedRunInfo.InstrumentSettings,
                _wellplateName => _datasetInfo.Wellplate,
                _wellNumber => _datasetInfo.WellNum,
                _internalStandard => 'na',
                _comment => 'Automatically created by Dataset entry',
                _eusProposalID => _requestedRunInfo.EusProposalID,
                _eusUsageType => _requestedRunInfo.EusUsageType,
                _eusUsersList => _eusUsersList,
                _mode => 'add-auto',
                _request => _requestID,         -- Output
                _message => _message,           -- Output
                _returnCode => _returnCode,     -- Output
                _secSep => _requestedRunInfo.SeparationGroup,
                _mRMAttachment => '',
                _status => 'Completed',
                _skipTransactionRollback => true,
                _autoPopulateUserListIfBlank => true);        -- Auto populate _eusUsersList if blank since this is an Auto-Request

        If _returnCode <> '' Then
            ROLLBACK;

            _message := format('Create AutoReq run request failed: dataset %s with Proposal ID %s, Usage Type %s, and Users List % -> %s',
                                _newDataset, _requestedRunInfo.EusProposalID, _requestedRunInfo.EusUsageType, _eusUsersList, _message

            RAISE ERROR '%', _message;

            RETURN;
        End If;

        ---------------------------------------------------
        -- Consume the scheduled run
        ---------------------------------------------------

        Call consume_scheduled_run _datasetID, _requestID, _message => _message
        --
        If _returnCode <> '' Then
            ROLLBACK;

            _message := 'Consume operation failed: dataset ' || _newDataset || ' -> ' || _message;
            RAISE ERROR '%', _message;

            RETURN;
        End If;

        Commit transaction _transName

        -- Update t_cached_dataset_instruments
        Call public.update_cached_dataset_instruments (_processingMode => 0, _datasetId => _datasetID, _infoOnly => false);

        Select _newDataset As Dataset_New, _datasetID As Dataset_ID, _requestID As RequestedRun_ID, 'Duplicated dataset ' || _sourceDataset As Status

        SELECT *
        FROM V_Dataset_Detail_Report_Ex
        WHERE ID = _datasetID

    End If;

END
$$;

COMMENT ON PROCEDURE public.duplicate_dataset IS 'DuplicateDataset';
