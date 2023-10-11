--
-- Name: add_requested_run_to_existing_dataset(integer, text, integer, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_requested_run_to_existing_dataset(IN _datasetid integer, IN _datasetname text, IN _templaterequestid integer, IN _mode text DEFAULT 'add'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Creates a requested run and associates it with the given dataset
**      (throws an exception if an existing requested run already references _datasetID)
**
**      Example auto-created requested run names:
**      'AutoReq_DatasetName'
**      'AutoReq2_DatasetName'
**      'AutoReq3_DatasetName'
**
**      Note that this procedure is similar to Add_Missing_Requested_Run,
**      though that procedure is intended to be run via automation to add
**      requested runs to existing datasets that don't yet have one
**
**      In contrast, this procedure has parameter _templateRequestID which defines an existing requested run ID from which to lookup EUS information
**
**  Arguments:
**    _datasetID            Dataset ID; can supply ID for dataset or name for dataset (but not both)
**    _datasetName          Dataset name
**    _templateRequestID    Existing requested run to use for looking up some parameters for the new requested run (throws an exception if this is null or 0)
**    _mode                 Compatibility with web entry page and possible future use; supports 'add', 'add-debug', and 'preview'
**
**  Auth:   grk
**  Date:   05/23/2011 grk - Initial release
**          11/29/2011 mem - Now auto-determining OperatorUsername if _callingUser is empty
**          12/14/2011 mem - Now passing _callingUser to Add_Update_Requested_Run and Consume_Scheduled_Run
**          05/08/2013 mem - Now setting _wellplateName and _wellNumber to Null when calling Add_Update_Requested_Run
**          01/29/2016 mem - Now calling Get_WP_for_EUS_Proposal to get the best work package for the given EUS Proposal
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/22/2017 mem - If necessary, change the prefix from AutoReq_ to AutoReq2_ or AutoReq3 to avoid conflicts
**          06/13/2017 mem - Rename _operPRN to _requestorPRN when calling Add_Update_Requested_Run
**          08/06/2018 mem - Rename Operator PRN column to RDS_Requestor_PRN
**          01/24/2020 mem - Add mode 'preview'
**          01/31/2020 mem - Display all of the values sent to Add_Update_Requested_Run when mode is 'preview'
**          02/04/2020 mem - Add mode 'add-debug', which will associate the requested run with the dataset, but will also print out debug statements
**          05/23/2022 mem - Rename _requestorPRN to _requesterPRN when calling Add_Update_Requested_Run
**          11/25/2022 mem - Update call to Add_Update_Requested_Run to use new parameter name
**          02/27/2023 mem - Use new argument name, _requestName
**          09/13/2023 mem - Ported to PostgreSQL
**          10/10/2023 mem - Rearrange argument order when calling add_update_requested_run
**
*****************************************************/
DECLARE
    _existingCount int;
    _showDebugStatements boolean := false;
    _existingDatasetID int;
    _existingDatasetName text;
    _requestID int;
    _requestName citext;
    _iteration int;
    _experimentName text;
    _instrumentGroup text;
    _msType text;
    _comment text;
    _workPackage citext := 'none';
    _requesterUsername text := '';
    _eusProposalID text := 'na';
    _eusUsageType text;
    _eusUsersList text := '';
    _secSep text := 'LC-Formic_1hr';
    _resolvedInstrumentInfo text;
    _msg text := '';
    _addUpdateMode text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _logMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    _mode := Trim(Lower(Coalesce(_mode, '')));

    If _mode Like 'add%debug' Then
        _showDebugStatements := true;
        _mode := 'add';
    End If;

    BEGIN

        ---------------------------------------------------
        -- Validate dataset identification
        -- (either name or ID, but not both)
        ---------------------------------------------------

        _datasetID   := Coalesce(_datasetID, 0);
        _datasetName := Trim(Coalesce(_datasetName, ''));

        If _datasetID <> 0 And _datasetName <> '' Then
            RAISE EXCEPTION 'Cannot specify both dataset ID "%" and dataset name "%"', _datasetID, _datasetName;
        End If;

        ---------------------------------------------------
        -- Require that _templateRequestID be defined
        ---------------------------------------------------

        If Coalesce(_templateRequestID, 0) = 0 Then
            RAISE EXCEPTION 'Template request ID must be non-zero when calling add_requested_run_to_existing_dataset';
        End If;

        ---------------------------------------------------
        -- Does dataset exist?
        ---------------------------------------------------

        SELECT dataset_id,
               dataset
        INTO _existingDatasetID, _existingDatasetName
        FROM t_dataset
        WHERE dataset_id = _datasetID;
        --
        GET DIAGNOSTICS _existingCount = ROW_COUNT;

        If _existingCount = 0 And _datasetName <> '' Then
            SELECT dataset_id,
                   dataset
            INTO _existingDatasetID, _existingDatasetName
            FROM t_dataset
            WHERE dataset = _datasetName::citext;
            --
            GET DIAGNOSTICS _existingCount = ROW_COUNT;
        End If;

        If _existingCount = 0 Then
            RAISE EXCEPTION 'Could not find dataset ID "%" or dataset "%"', _datasetID, _datasetName;
        End If;

        _datasetID   := _existingDatasetID;
        _datasetName := _existingDatasetName;

        ---------------------------------------------------
        -- Does the dataset have an associated requested run?
        ---------------------------------------------------

        SELECT RR.request_id
        INTO _requestID
        FROM t_requested_run AS RR
        WHERE RR.dataset_id = _datasetID;

        If FOUND Then
            RAISE EXCEPTION 'Dataset ID "%" has existing requested run, ID "%"', _datasetID, _requestID;
        End If;

        ---------------------------------------------------
        -- Parameters for creating requested run
        ---------------------------------------------------

        _requestName := format('AutoReq_%s', _datasetName);
        _iteration   := 1;

        If _showDebugStatements Then
            RAISE INFO '';
        End If;

        WHILE true
        LOOP
            If _showDebugStatements Then
                RAISE INFO 'Looking for existing requested run named %', _requestName;
            End If;

            If Exists (SELECT request_id FROM t_requested_run WHERE request_name = _requestName) Then
                -- Requested run already exists; bump up _iteration and try again
                _iteration := _iteration + 1;
                _requestName := format('AutoReq%s_%s', _iteration, _datasetName);
            Else
                -- Break out of the while loop
                EXIT;
            End If;
        END LOOP;

        ---------------------------------------------------
        -- Fill in some requested run parameters from dataset
        ---------------------------------------------------

        If _showDebugStatements Then
            RAISE INFO 'Querying t_dataset, t_instrument_name, etc. for dataset_id %', _datasetID;
        End If;

        SELECT E.experiment,
               InstName.instrument_group,
               DSType.Dataset_Type,
               SS.separation_type
        INTO _experimentName, _instrumentGroup, _msType, _secSep
        FROM t_dataset AS TD
             INNER JOIN t_instrument_name AS InstName
               ON TD.instrument_id = InstName.instrument_id
             INNER JOIN t_dataset_type_name AS DSType
               ON TD.dataset_type_ID = DSType.dataset_type_ID
             INNER JOIN t_experiments AS E
               ON TD.exp_id = E.exp_id
             INNER JOIN t_secondary_sep AS SS
               ON TD.separation_type = SS.separation_type
        WHERE TD.dataset_id = _datasetID;

        ---------------------------------------------------
        -- Fill in some parameters from existing requested run
        ---------------------------------------------------

        _comment := 'Automatically created by Dataset entry';

        If _showDebugStatements Then
            RAISE INFO 'Querying t_requested_run and t_eus_usage_type for request eus_usage_type_id  %', _templateRequestID;
        End If;

        SELECT RR.work_package,
               RR.requester_username,
               RR.eus_proposal_id,
               EUT.eus_usage_type,
               public.get_requested_run_eus_users_list(RR.request_id, 'I')
        INTO _workPackage, _requesterUsername, _eusProposalID, _eusUsageType, _eusUsersList
        FROM t_requested_run AS RR
             INNER JOIN t_eus_usage_type AS EUT
               ON RR.eus_usage_type_id = EUT.eus_usage_type_id
        WHERE RR.request_id = _templateRequestID;

        If Not FOUND Then
            _message := format('Template request ID %s not found', _templateRequestID);
            If _showDebugStatements Then
                RAISE INFO '%', _message;
            End If;

            RAISE EXCEPTION '%', _message;
        End If;

        _comment := format('%s using request %s', _comment, _templateRequestID);

        If _showDebugStatements Then
            RAISE INFO '%', _comment;
        End If;

        If Lower(Coalesce(_workPackage, 'none')) = 'none' Then
            If _showDebugStatements Then
                RAISE INFO 'Calling Get_WP_for_EUS_Proposal with proposal %', _eusProposalID;
            End If;

            SELECT work_package
            INTO _workPackage
            FROM public.get_wp_for_eus_proposal(_eusProposalID);

            If _showDebugStatements Then
                RAISE INFO 'Get_WP_for_EUS_Proposal returned work package %', _workPackage;
            End If;
        End If;

        ---------------------------------------------------
        -- Create requested run and attach it to dataset
        ---------------------------------------------------

        If Coalesce(_callingUser, '') <> '' Then
            _requesterUsername := _callingUser;
        End If;

        If _mode = 'preview' Then
            _addUpdateMode := 'check-add';

            RAISE INFO '';
            RAISE INFO 'Request_Name: %', requestName;
            RAISE INFO 'Experiment: %', experimentName;
            RAISE INFO 'RequesterUsername: %', requesterUsername;
            RAISE INFO 'InstrumentName: %', instrumentName;
            RAISE INFO 'WorkPackage: %', workPackage;
            RAISE INFO 'MsType: %', msType;
            RAISE INFO 'InstrumentSettings: na';
            RAISE INFO 'Wellplate: Null';
            RAISE INFO 'WellNum: Null';
            RAISE INFO 'InternalStandard: na';
            RAISE INFO 'Comment: %', comment;
            RAISE INFO 'EusProposalID: %', eusProposalID;
            RAISE INFO 'EusUsageType: %', eusUsageType;
            RAISE INFO 'EusUsersList: %', eusUsersList;
            RAISE INFO 'Mode: %', addUpdateMode;
            RAISE INFO 'SecSep: %', secSep;
            RAISE INFO 'MRMAttachment: ';
            RAISE INFO 'Status: Completed';
            RAISE INFO 'SkipTransactionRollback: 1';
            RAISE INFO 'AutoPopulateUserListIfBlank: 1';
            RAISE INFO 'CallingUser: %', callingUser;
            RAISE INFO '';
        Else
            _addUpdateMode := 'add-auto';
        End If;

        If _showDebugStatements Then
            RAISE INFO 'Calling add_update_requested_run with mode %', _addUpdateMode;
        End If;

        CALL public.add_update_requested_run (
                        _requestName                 => _requestName,
                        _experimentName              => _experimentName,
                        _requesterUsername           => _requesterUsername,
                        _instrumentGroup             => _instrumentGroup,
                        _workPackage                 => _workPackage,
                        _msType                      => _msType,                    -- Dataset type
                        _instrumentSettings          => 'na',
                        _wellplateName               => null,
                        _wellNumber                  => null,
                        _internalStandard            => 'na',
                        _comment                     => _comment,
                        _batch                       => 0,
                        _block                       => 0,
                        _runOrder                    => 0,
                        _eusProposalID               => _eusProposalID,
                        _eusUsageType                => _eusUsageType,
                        _eusUsersList                => _eusUsersList,
                        _mode                        => _addUpdateMode,
                        _secSep                      => _secSep,                    -- Separation group
                        _mrmAttachment               => '',
                        _status                      => 'Completed',
                        _skipTransactionRollback     => true,
                        _autoPopulateUserListIfBlank => true,                       -- Auto populate _eusUsersList if blank since this is an Auto-Request
                        _callingUser                 => _callingUser,
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
            RAISE EXCEPTION '%', _msg;
        End If;

        If _requestID = 0 Then
            RAISE EXCEPTION 'Add_Update_Requested_Run returned request ID 0';
        End If;

        If _showDebugStatements Then
            RAISE INFO 'Add_Update_Requested_Run reported that it created Request ID %', _requestID;
        End If;

        If _addUpdateMode = 'add-auto' Then
            ---------------------------------------------------
            -- Consume the requested run
            ---------------------------------------------------

            If _showDebugStatements Then
                RAISE INFO 'Calling consume_scheduled_run with DatasetID % and RequestID %', _datasetID, _requestID;
            End If;

            CALL public.consume_scheduled_run (
                            _datasetID,
                            _requestID,
                            _message          => _msg,          -- Output
                            _returnCode       => _returnCode,   -- Output
                            _callingUser      => _callingUser,
                            _logDebugMessages => false);

            If _returnCode <> '' Then
                RAISE EXCEPTION '%', _msg;
            End If;

            If _showDebugStatements Then
                RAISE INFO 'Consume_Scheduled_Run returned message "%"', _msg;
            End If;

        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _mode <> 'preview' Then
            -- Log the error

            _logMessage := format('%s; Job %s', _exceptionMessage, _job);

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


ALTER PROCEDURE public.add_requested_run_to_existing_dataset(IN _datasetid integer, IN _datasetname text, IN _templaterequestid integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE add_requested_run_to_existing_dataset(IN _datasetid integer, IN _datasetname text, IN _templaterequestid integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.add_requested_run_to_existing_dataset(IN _datasetid integer, IN _datasetname text, IN _templaterequestid integer, IN _mode text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'AddRequestedRunToExistingDataset';

