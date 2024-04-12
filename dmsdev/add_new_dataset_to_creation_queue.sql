--
-- Name: add_new_dataset_to_creation_queue(text, text, text, text, text, text, text, text, text, text, text, text, text, text, integer, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.add_new_dataset_to_creation_queue(IN _datasetname text, IN _experimentname text, IN _instrumentname text, IN _separationtype text, IN _lccartname text, IN _lccartconfig text, IN _lccolumnname text, IN _wellplatename text, IN _wellnumber text, IN _datasettype text, IN _operatorusername text, IN _dscreatorusername text, IN _comment text, IN _interestrating text, IN _requestid integer, IN _workpackage text DEFAULT ''::text, IN _eususagetype text DEFAULT ''::text, IN _eusproposalid text DEFAULT ''::text, IN _eususerslist text DEFAULT ''::text, IN _capturesubfolder text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Add a new dataset creation task to T_Dataset_Create_Queue
**
**      The Data Import Manager uses procedure request_dataset_create_task to look for entries with state 1 in T_Dataset_Create_Queue
**      For each one, it validates that the dataset file(s) are available, then creates the dataset in DMS
**
**  Arguments:
**    _datasetName          Dataset name
**    _experimentName       Experiment name
**    _instrumentName       Instrument name
**    _separationType       Separation type
**    _lcCartName           LC cart
**    _lcCartConfig         LC cart config
**    _lcColumnName         LC column
**    _wellplateName        Wellplate
**    _wellNumber           Well number
**    _datasetType          Datset type
**    _operatorUsername     Operator username
**    _dsCreatorUsername    Dataset creator username
**    _comment              Comment
**    _interestRating       Interest rating
**    _requestID            Requested run ID
**    _workPackage          Work package
**    _eusUsageType         EUS usage type
**    _eusProposalID        EUS proposal id
**    _eusUsersList         EUS users list
**    _captureSubfolder     Capture subfolder
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   mem
**  Date:   10/24/2023 mem - Initial version
**
*****************************************************/
DECLARE
    _captureShareName text;
    _captureSubdirectory text;
    _charPos int;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _logMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN
        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _datasetName      := Trim(Coalesce(_datasetName, ''));
        _experimentName   := Trim(Coalesce(_experimentName, ''));
        _instrumentName   := Trim(Coalesce(_instrumentName, ''));
        _captureSubfolder := Trim(Coalesce(_captureSubfolder, ''));
        _lcCartConfig     := Trim(Coalesce(_lcCartConfig, ''));
        _requestID        := Coalesce(_requestID, 0);

        If _datasetName = '' Then
            _message := 'Dataset name is not defined, cannot add to dataset creation queue';
            _returnCode := 'U5270';
            RETURN;
        End If;

        If _experimentName = '' Then
            _message := 'Experiment name is not defined, cannot add to dataset creation queue';
            _returnCode := 'U5271';
            RETURN;
        End If;

        If _instrumentName = '' Then
            _message := 'Instrument name is not defined, cannot add to dataset creation queue';
            _returnCode := 'U5272';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Determine the capture share name and subdirectory
        ---------------------------------------------------

        If _captureSubfolder Like '..\\%\\%' Then

            -- Capture subfolder is of the form '..\ProteomicsData2\DatasetName'
            -- Change _captureShareName to 'ProteomicsData2' and _captureSubdirectory to 'DatasetName'
            -- Example dataset: https://dms2.pnl.gov/datasetid/show/1129444

            -- Find the second backslash
            _charPos := Position('\' In Substring(_captureSubfolder, 4)) + 3;

            If _charPos > 4 Then
                _captureShareName    := Substring(_captureSubfolder, 4, _charPos - 4);
                _captureSubdirectory := Substring(_captureSubfolder, _charPos + 1, 250);
            Else
                _captureShareName    := '';
                _captureSubdirectory := _captureSubfolder;
            End If;
        Else
            _captureShareName    := '';
            _captureSubdirectory := _captureSubfolder;
        End If;

        ---------------------------------------------------
        -- If the new dataset already exists in the queue table with state 1, change the state to 5 (Inactive)
        ---------------------------------------------------

        UPDATE t_dataset_create_queue
        SET state_id = 5
        WHERE dataset = _datasetName::citext AND state_id = 1;

        INSERT INTO t_dataset_create_queue (
            state_id,
            dataset,
            experiment,
            instrument,
            separation_type,
            lc_cart,
            lc_cart_config,
            lc_column,
            wellplate,
            well,
            dataset_type,
            operator_username,
            ds_creator_username,
            comment,
            interest_rating,
            request,
            work_package,
            eus_usage_type,
            eus_proposal_id,
            eus_users,
            capture_share_name,
            capture_subdirectory,
            command
        )
        VALUES (1,           -- State=New
                _datasetName,
                _experimentName,
                _instrumentName,
                _separationType,
                _lcCartName,
                _lcCartConfig,
                _lcColumnName,
                _wellplateName,
                _wellNumber,
                _datasetType,
                _operatorUsername,
                _dsCreatorUsername,
                _comment,
                _interestRating,
                _requestID,
                _workPackage,
                _eusUsageType,
                _eusProposalID,
                _eusUsersList,
                _captureShareName,
                _captureSubdirectory,
                'add');

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _logMessage := format('Error adding dataset creation task for %s: %s', _datasetName, _exceptionMessage);

        _message := local_error_handler (
                        _sqlState, _logMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;
END
$$;


ALTER PROCEDURE public.add_new_dataset_to_creation_queue(IN _datasetname text, IN _experimentname text, IN _instrumentname text, IN _separationtype text, IN _lccartname text, IN _lccartconfig text, IN _lccolumnname text, IN _wellplatename text, IN _wellnumber text, IN _datasettype text, IN _operatorusername text, IN _dscreatorusername text, IN _comment text, IN _interestrating text, IN _requestid integer, IN _workpackage text, IN _eususagetype text, IN _eusproposalid text, IN _eususerslist text, IN _capturesubfolder text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

