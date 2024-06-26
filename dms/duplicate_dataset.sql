--
-- Name: duplicate_dataset(text, text, text, text, text, integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.duplicate_dataset(IN _sourcedataset text, IN _newdataset text, IN _newcomment text DEFAULT ''::text, IN _newcapturesubfolder text DEFAULT ''::text, IN _newoperatorusername text DEFAULT ''::text, IN _datasetstateid integer DEFAULT 1, IN _infoonly boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Duplicate a dataset by adding a new row to t_dataset and calling add_update_requested_run
**
**  Arguments:
**    _sourceDataset        Source dataset name
**    _newDataset           New dataset name
**    _newComment           New dataset comment; use source dataset's comment if blank; use a blank comment if '.' or '<blank>' or '<empty>'
**    _newCaptureSubfolder  Capture subfolder name; use source dataset's capture subfolder if blank
**    _newOperatorUsername  Operator username
**    _datasetStateID       1 for a new dataset, which will create a dataset capture job; 3=Complete; 4=Inactive; 13=Holding
**    _infoOnly             When true, preview the dataset that would be created
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   mem
**  Date:   12/12/2018 mem - Initial version
**          08/19/2020 mem - Add _newOperatorUsername
**                         - Add call to Update_Cached_Dataset_Instruments
**          10/19/2020 mem - Rename the instrument group column to instrument_group
**          12/08/2020 mem - Lookup Username from T_Users using the validated user ID
**          05/23/2022 mem - Rename _requestorPRN to _requesterPRN when calling Add_Update_Requested_Run
**          11/25/2022 mem - Rename variable and update call to Add_Update_Requested_Run to use new parameter name
**          02/27/2023 mem - Use new argument name, _requestName
**          02/12/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetInfo record;
    _datasetID int;
    _requestedRunInfo record;
    _requestName text;
    _eusUsersList text;
    _requestID int;
    _userID int;
    _matchCount int;
    _newUsername text;
    _resolvedInstrumentInfo text;

    _formatSpecifierDS text;
    _infoHeadDS text;
    _infoHeadSeparatorDS text;

    _formatSpecifierRR text;
    _infoHeadRR text;
    _infoHeadSeparatorRR text;

    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _sourceDataset       := Trim(Coalesce(_sourceDataset, ''));
    _newDataset          := Trim(Coalesce(_newDataset, ''));
    _newComment          := Trim(Coalesce(_newComment, ''));
    _newCaptureSubfolder := Trim(Coalesce(_newCaptureSubfolder, ''));
    _newOperatorUsername := Trim(Coalesce(_newOperatorUsername, ''));
    _datasetStateID      := Coalesce(_datasetStateID, 1);
    _infoOnly            := Coalesce(_infoOnly, true);

    If _sourceDataset = '' Then
        _message := 'Source dataset name must be specified';
        RAISE WARNING '%', _message;

        RETURN;
    End If;

    If _newDataset = '' Then
        _message := 'New dataset name must be specified';
        RAISE WARNING '%', _message;

        RETURN;
    End If;

    If Not Exists (SELECT dataset_id FROM t_dataset WHERE dataset = _sourceDataset::citext) Then
        _message := format('Source dataset not found in t_dataset: %s', _sourceDataset);
        RAISE WARNING '%', _message;

        RETURN;
    End If;

    If Exists (SELECT dataset_id FROM t_dataset WHERE dataset = _newDataset::citext) Then
        _message := format('Dataset already exists in t_dataset: %s', _newDataset);
        RAISE WARNING '%', _message;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Lookup the source dataset info, including experiment name
    ---------------------------------------------------

    SELECT D.dataset_id           AS SourceDatasetId,
           D.operator_username    AS OperatorUsername,
           D.comment              AS Comment,
           D.instrument_id        AS InstrumentID,
           D.dataset_type_ID      AS DatasetTypeID,
           D.well                 AS WellNum,
           D.separation_type      AS SecSep,
           D.storage_path_ID      AS StoragePathID,
           D.exp_id               AS ExperimentID,
           D.dataset_rating_id    AS RatingID,
           D.lc_column_ID         AS ColumnID,
           D.wellplate            AS Wellplate,
           D.internal_standard_id AS IntStdID,
           D.capture_subfolder    AS CaptureSubfolder,
           D.cart_config_id       AS CartConfigID,
           E.experiment           AS ExperimentName
    INTO _datasetInfo
    FROM t_dataset D
         INNER JOIN t_experiments E
           ON D.exp_id = E.exp_id
    WHERE D.dataset = _sourceDataset::citext;

    If Not FOUND Then
        _message := format('Dataset not found: %s', _sourceDataset);
        RAISE WARNING '%', _message;

        RETURN;
    End If;

    If _newComment <> '' Then
        If _datasetInfo.Comment::citext In ('.', '<blank>', 'blank', '<empty>', 'empty') Then
            _datasetInfo.Comment := '';
        Else
            _datasetInfo.Comment := _newComment;
        End If;
    End If;

    If _newCaptureSubfolder <> '' Then
        _datasetInfo.CaptureSubfolder := _newCaptureSubfolder;
    End If;

    ---------------------------------------------------
    -- Lookup requested run information
    ---------------------------------------------------

    SELECT RR.request_id         AS SourceDatasetRequestID,
           RR.instrument_group   AS InstrumentGroup,
           RR.work_package       AS WorkPackage,
           RR.instrument_setting AS InstrumentSettings,
           DSType.Dataset_Type   AS DatasetType,
           RR.separation_group   AS SeparationGroup,
           RR.eus_proposal_id    AS EusProposalID,
           EUT.eus_usage_type    AS EusUsageType
    INTO _requestedRunInfo
    FROM t_requested_run AS RR
         INNER JOIN t_dataset_type_name AS DSType
           ON RR.request_type_id = DSType.dataset_type_id
         INNER JOIN t_eus_usage_type AS EUT
           ON RR.eus_usage_type_id = EUT.eus_usage_type_id
    WHERE RR.dataset_id = _datasetInfo.SourceDatasetId;

    If Not FOUND Then
        _message := 'Source dataset does not have a requested run; use Add_Missing_Requested_Run to add one';
        RAISE WARNING '%', _message;

        RETURN;
    End If;

    _eusUsersList := public.get_requested_run_eus_users_list(_requestedRunInfo.SourceDatasetRequestID, 'I');

    If _newOperatorUsername <> '' Then
        ---------------------------------------------------
        -- Resolve user ID for operator username
        ---------------------------------------------------

        _userID := public.get_user_id(_newOperatorUsername);

        If _userID > 0 Then
            -- Function get_user_id recognizes both a username and the form 'LastName, FirstName (Username)'
            -- Assure that _operatorUsername contains simply the username

            SELECT username
            INTO _datasetInfo.OperatorUsername
            FROM t_users
            WHERE user_id = _userID;
        Else
            -- Could not find entry in database for username _newOperatorUsername
            -- Try to auto-resolve the name

            CALL public.auto_resolve_name_to_username (
                    _newOperatorUsername,
                    _matchCount       => _matchCount,   -- Output
                    _matchingUsername => _newUsername,  -- Output
                    _matchingUserID   => _userID);      -- Output

            If _matchCount = 1 Then
                -- Single match found; update _operatorUsername
                _datasetInfo.OperatorUsername := _newUsername;
            Else
                If _matchCount = 0 Then
                    _message := format('Invalid operator username: "%s" does not exist', _newOperatorUsername);
                Else
                    _message := format('Invalid operator username: "%s" matches more than one user', _newOperatorUsername);
                End If;

                RAISE WARNING '%', _message;
                RETURN;
            End If;
        End If;
    End If;

    -- Format info for previewing the dataset that would be created, or for showing the newly created dataset
    _formatSpecifierDS := '%-10s %-80s %-80s %-20s %-13s %-13s';

    _infoHeadDS := format(_formatSpecifierDS,
                          'Dataset_ID',
                          'Dataset',
                          'Comment',
                          'Created',
                          'Instrument_ID',
                          'Experiment_ID'
                         );

    _infoHeadSeparatorDS := format(_formatSpecifierDS,
                                   '----------',
                                   '--------------------------------------------------------------------------------',
                                   '--------------------------------------------------------------------------------',
                                   '--------------------',
                                   '-------------',
                                   '-------------'
                                  );

    -- Format info for previewing the requested run that would be created, or for showing the newly created requested run
    _formatSpecifierRR := '%-10s %-80s %-60s %-10s %-25s %-10s %-20s %-35s %-60s';

    _infoHeadRR := format(_formatSpecifierRR,
                          'Request_ID',
                          'Requested_Run',
                          'Experiment',
                          'Operator',
                          'Instrument_Group',
                          'WP',
                          'Dataset_Type',
                          'Sep_Group',
                          'Comment'
                         );

    _infoHeadSeparatorRR := format(_formatSpecifierRR,
                                   '----------',
                                   '--------------------------------------------------------------------------------',
                                   '------------------------------------------------------------',
                                   '----------',
                                   '-------------------------',
                                   '----------',
                                   '--------------------',
                                   '-----------------------------------',
                                   '------------------------------------------------------------'
                                  );

    _requestName := format('AutoReq_%s', _newDataset);

    If _infoOnly Then

        -- Show the dataset that would be created
        RAISE INFO '';
        RAISE INFO '%', _infoHeadDS;
        RAISE INFO '%', _infoHeadSeparatorDS;
        RAISE INFO '%', format(_formatSpecifierDS,
                               0,                   -- Dataset_ID
                               _newDataset,
                               _datasetInfo.Comment,
                               public.timestamp_text(CURRENT_TIMESTAMP),
                               _datasetInfo.InstrumentID,
                               _datasetInfo.ExperimentID
                              );

        -- Show the requested run that would be created
        RAISE INFO '';
        RAISE INFO '%', _infoHeadRR;
        RAISE INFO '%', _infoHeadSeparatorRR;
        RAISE INFO '%', format(_formatSpecifierRR,
                               _requestedRunInfo.SourceDatasetRequestID,
                               _requestName,
                               _datasetInfo.ExperimentName,
                               _datasetInfo.OperatorUsername,
                               _requestedRunInfo.InstrumentGroup,
                               _requestedRunInfo.WorkPackage,
                               _requestedRunInfo.DatasetType,
                               _requestedRunInfo.SeparationGroup,
                               'Automatically created by Dataset entry');

        RETURN;
    End If;

    ---------------------------------------------------
    -- Create the new dataset
    ---------------------------------------------------

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
        _datasetInfo.OperatorUsername,
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

    CALL public.add_update_requested_run (
                    _requestName                 => _requestName,
                    _experimentName              => _datasetInfo.ExperimentName,
                    _requesterUsername           => _datasetInfo.OperatorUsername,
                    _instrumentGroup             => _requestedRunInfo.InstrumentGroup,
                    _workPackage                 => _requestedRunInfo.WorkPackage,
                    _msType                      => _requestedRunInfo.DatasetType,
                    _instrumentSettings          => _requestedRunInfo.InstrumentSettings,
                    _wellplateName               => _datasetInfo.Wellplate,
                    _wellNumber                  => _datasetInfo.WellNum,
                    _internalStandard            => 'na',
                    _comment                     => 'Automatically created by Dataset entry',
                    _batch                       => 0,
                    _block                       => 0,
                    _runOrder                    => 0,
                    _eusProposalID               => _requestedRunInfo.EusProposalID,
                    _eusUsageType                => _requestedRunInfo.EusUsageType,
                    _eusUsersList                => _eusUsersList,
                    _mode                        => 'add-auto',
                    _secSep                      => _requestedRunInfo.SeparationGroup,
                    _mrmAttachment               => '',
                    _status                      => 'Completed',
                    _skipTransactionRollback     => true,
                    _autoPopulateUserListIfBlank => true,       -- Auto populate _eusUsersList if blank since this is an Auto-Request
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

    If _returnCode <> '' Then
        ROLLBACK;

        _message := format('Create AutoReq run request failed: dataset %s with Proposal ID %s, Usage Type %s, and Users List %s; %s',
                            _newDataset, _requestedRunInfo.EusProposalID, _requestedRunInfo.EusUsageType, _eusUsersList, _message);

        RAISE WARNING '%', _message;

        RETURN;
    End If;

    ---------------------------------------------------
    -- Consume the scheduled run
    ---------------------------------------------------

    CALL public.consume_scheduled_run (
                    _datasetID         => _datasetID,
                    _requestID         => _requestID,
                    _message           => _message,     -- Output
                    _returnCode        => _returnCode,  -- Output
                    _callingUser       => '',
                    _logDebugMessages  => false);

    If _returnCode <> '' Then
        ROLLBACK;

        _message := format('Consume operation failed: dataset %s -> %s', _newDataset, _message);
        RAISE WARNING '%', _message;

        RETURN;
    End If;

    -- Update t_cached_dataset_stats
    CALL public.update_cached_dataset_instruments (
                    _processingMode => 0,
                    _datasetId      => _datasetID,
                    _infoOnly       => false,
                    _message        => _message,        -- Output
                    _returnCode     => _returnCode);    -- Output

    RAISE INFO '';
    RAISE INFO 'Duplicated dataset %, creating %', _sourceDataset, _newDataset;
    RAISE INFO 'New Dataset ID: %, New Requested Run ID: %', _datasetID, _requestID;

    -- Show the dataset that was created
    RAISE INFO '';
    RAISE INFO '%', _infoHeadDS;
    RAISE INFO '%', _infoHeadSeparatorDS;

    FOR _previewData IN
        SELECT dataset_id, dataset, comment, created, instrument_id, exp_id
        FROM t_dataset
        WHERE dataset_id = _datasetID
    LOOP
        _infoData := format(_formatSpecifierDS,
                            _previewData.dataset_id,
                            _previewData.dataset,
                            _previewData.comment,
                            public.timestamp_text(_previewData.created),
                            _previewData.instrument_id,
                            _previewData.exp_id
                           );

        RAISE INFO '%', _infoData;
    END LOOP;

    -- Show the requested run that was created
    RAISE INFO '';
    RAISE INFO '%', _infoHeadRR;
    RAISE INFO '%', _infoHeadSeparatorRR;

    FOR _previewData IN
        SELECT RR.request_id,
               RR.request_name,
               E.experiment,
               DS.operator_username,
               RR.instrument_group,
               RR.work_package,
               DSType.dataset_type,
               RR.separation_group,
               RR.comment
        FROM t_requested_run AS RR
             INNER JOIN t_dataset DS
               ON DS.dataset_id = RR.dataset_id
             INNER JOIN t_dataset_type_name AS DSType
               ON RR.request_type_id = DSType.dataset_type_id
             INNER JOIN t_eus_usage_type AS EUT
               ON RR.eus_usage_type_id = EUT.eus_usage_type_id
             INNER JOIN t_experiments E
               ON DS.exp_id = E.exp_id
        WHERE DS.dataset_id = _datasetID
    LOOP
        _infoData := format(_formatSpecifierRR,
                            _previewData.request_id,
                            _previewData.request_name,
                            _previewData.experiment,
                            _previewData.operator_username,
                            _previewData.instrument_group,
                            _previewData.work_package,
                            _previewData.dataset_type,
                            _previewData.separation_group,
                            _previewData.comment);

        RAISE INFO '%', _infoData;
    END LOOP;

END
$$;


ALTER PROCEDURE public.duplicate_dataset(IN _sourcedataset text, IN _newdataset text, IN _newcomment text, IN _newcapturesubfolder text, IN _newoperatorusername text, IN _datasetstateid integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE duplicate_dataset(IN _sourcedataset text, IN _newdataset text, IN _newcomment text, IN _newcapturesubfolder text, IN _newoperatorusername text, IN _datasetstateid integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.duplicate_dataset(IN _sourcedataset text, IN _newdataset text, IN _newcomment text, IN _newcapturesubfolder text, IN _newoperatorusername text, IN _datasetstateid integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'DuplicateDataset';

