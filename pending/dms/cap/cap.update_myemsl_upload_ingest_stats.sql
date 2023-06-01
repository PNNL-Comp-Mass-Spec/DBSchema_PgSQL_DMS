--
CREATE OR REPLACE PROCEDURE cap.update_myemsl_upload_ingest_stats
(
    _datasetID int,
    _statusNum int,
    _ingestStepsCompleted int,
    _fatalError boolean default false,
    _transactionId int default 0,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates column Ingest_Steps_Completed for the given MyEMSL ingest task
**
**      This procedure is called by the ArchiveStatusCheckPlugin in the DMS Capture Manager
**
**  Arguments:
**    _statusNum              The status number must match the specified DatasetID (this is a safety check)
**    _ingestStepsCompleted   Number of ingest steps that were completed for this entry
**    _fatalError             True if the ingest failed and the ErrorCode column needs to be set to -1 (if currently 0 or null)
**    _transactionId          Transaction ID (null or 0 if unknown); starting in July 2017, transactionId and Status_Num should match
**
**  Auth:   mem
**  Date:   12/18/2014 mem - Initial version
**          06/23/2016 mem - Add parameter _fatalError
**          05/31/2017 mem - Update TransactionID in T_MyEMSL_Uploads using _transactionId
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          07/12/2017 mem - Update TransactionId if null yet Ingest_Steps_Completed and ErrorCode are unchanged
**          08/01/2017 mem - Use THROW instead of RAISERROR
**          07/15/2019 mem - Filter on both Status_Num and Dataset_ID when updating T_MyEMSL_Uploads
**          01/31/2020 mem - Add _returnCode, which duplicates the integer returned by this procedure; _returnCode is varchar for compatibility with Postgres error codes
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _authorized boolean;

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

    SELECT schema_name, object_name
    INTO _currentSchema, _currentProcedure
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

        _datasetID := Coalesce(_datasetID, 0);
        _statusNum := Coalesce(_statusNum, 0);
        _ingestStepsCompleted := Coalesce(_ingestStepsCompleted, 0);
        _fatalError := Coalesce(_fatalError, false);
        _transactionId := Coalesce(_transactionId, 0);

        _message := '';

        If _datasetID <= 0 Then
            _message := '_datasetID must be positive; unable to continue';
            _returnCode := 'U5201';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Make sure the _statusNum exists in cap.t_myemsl_uploads
        ---------------------------------------------------

        If Not Exists (SELECT * FROM cap.t_myemsl_uploads MU WHERE status_num = _statusNum) Then
            _message := 'status_num ' || Cast(_statusNum as text) || ' not found in cap.t_myemsl_uploads';
            _returnCode := 'U5202';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Make sure the Dataset_ID is correct
        -- Also lookup the current ErrorCode for this upload task
        ---------------------------------------------------

        SELECT error_code
        INTO _errorCode
        FROM cap.t_myemsl_uploads
        WHERE status_num = _statusNum AND
              dataset_id = _datasetID;

        If Not FOUND Then
            _message := 'The DatasetID for Status_Num ' || Cast(_statusNum as text) || ' is not ' || Cast(_datasetID as text) || '; will not update Ingest_Steps_Completed';
            _returnCode := 'U5203';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Possibly update the error code
        ---------------------------------------------------

        If _fatalError And Coalesce(_returnCode, '') = '' Then
            _returnCode := 'U5204';
        End If;

        ---------------------------------------------------
        -- Perform the update
        ---------------------------------------------------

        UPDATE cap.t_myemsl_uploads
        SET ingest_steps_completed = _ingestStepsCompleted,
            error_code = _errorCode,
            transaction_id = CASE WHEN _transactionId = 0 THEN transaction_id ELSE _transactionId END
        WHERE status_num = _statusNum AND
              dataset_id = _datasetID AND
              (Coalesce(ingest_steps_completed, 0) <> _ingestStepsCompleted OR
               Coalesce(error_code, 0) <> Coalesce(_errorCode, 0) OR
               Coalesce(transaction_id, 0) <> Coalesce(_transactionId, 0) );

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;
END
$$;

COMMENT ON PROCEDURE cap.update_myemsl_upload_ingest_stats IS 'UpdateMyEMSLUploadIngestStats';

