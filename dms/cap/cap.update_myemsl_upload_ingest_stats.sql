--
-- Name: update_myemsl_upload_ingest_stats(integer, integer, integer, boolean, integer, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.update_myemsl_upload_ingest_stats(IN _datasetid integer, IN _statusnum integer, IN _ingeststepscompleted integer, IN _fatalerror boolean DEFAULT false, IN _transactionid integer DEFAULT 0, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Updates column ingest_steps_completed in cap.t_myemsl_uploads for the given MyEMSL ingest task
**      If _fatalError is true, sets error_code to -1 if null or 0
**
**      This procedure is called by the ArchiveStatusCheckPlugin in the DMS Capture Manager
**
**  Arguments:
**    _datasetID                Dataset ID
**    _statusNum                The status number must match the specified DatasetID (this is a safety check)
**    _ingestStepsCompleted     Number of ingest steps that were completed for this entry
**    _fatalError               True if the ingest failed and the error_code column needs to be set to -1 (if currently 0 or null)
**    _transactionId            Transaction ID (null or 0 if unknown); between July 2017 and May 2019, transactionId and status_num would always match; since May 2019, transaction_id is always null
**    _message                  Output message
**    _returnCode               Return code
**
**  Auth:   mem
**  Date:   12/18/2014 mem - Initial version
**          06/23/2016 mem - Add parameter _fatalError
**          05/31/2017 mem - Update TransactionID in T_MyEMSL_Uploads using _transactionId
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          07/12/2017 mem - Update TransactionId if null yet Ingest_Steps_Completed and Error_Code are unchanged
**          08/01/2017 mem - Use THROW instead of RAISERROR
**          07/15/2019 mem - Filter on both Status_Num and Dataset_ID when updating T_MyEMSL_Uploads
**          01/31/2020 mem - Add _returnCode, which duplicates the integer returned by this procedure; _returnCode is varchar for compatibility with Postgres error codes
**          06/29/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _errorCode int;

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

        _datasetID            := Coalesce(_datasetID, 0);
        _statusNum            := Coalesce(_statusNum, 0);
        _ingestStepsCompleted := Coalesce(_ingestStepsCompleted, 0);
        _fatalError           := Coalesce(_fatalError, false);
        _transactionId        := Coalesce(_transactionId, 0);

        _message := '';

        If _datasetID <= 0 Then
            _message := '_datasetID must be positive; unable to continue';
            _returnCode := 'U5201';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Make sure the _statusNum exists in cap.t_myemsl_uploads
        ---------------------------------------------------

        If Not Exists (SELECT * FROM cap.t_myemsl_uploads WHERE status_num = _statusNum) Then
            _message := format('status_num %s not found in cap.t_myemsl_uploads', _statusNum);
            _returnCode := 'U5202';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Make sure the Dataset_ID is correct
        -- Also lookup the current error code for this upload task
        ---------------------------------------------------

        SELECT error_code
        INTO _errorCode
        FROM cap.t_myemsl_uploads
        WHERE status_num = _statusNum AND
              dataset_id = _datasetID;

        If Not FOUND Then
            _message := format('The DatasetID for Status_Num %s is not %s; will not update Ingest_Steps_Completed', _statusNum, _datasetID);
            _returnCode := 'U5203';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Possibly update the error code
        ---------------------------------------------------

        If _fatalError And Coalesce(_errorCode, 0) = 0 Then
            _errorCode := -1;
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
              (ingest_steps_completed IS DISTINCT FROM _ingestStepsCompleted OR
               error_code             IS DISTINCT FROM _errorCode OR
               transaction_id         IS DISTINCT FROM _transactionId
              );

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


ALTER PROCEDURE cap.update_myemsl_upload_ingest_stats(IN _datasetid integer, IN _statusnum integer, IN _ingeststepscompleted integer, IN _fatalerror boolean, IN _transactionid integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_myemsl_upload_ingest_stats(IN _datasetid integer, IN _statusnum integer, IN _ingeststepscompleted integer, IN _fatalerror boolean, IN _transactionid integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.update_myemsl_upload_ingest_stats(IN _datasetid integer, IN _statusnum integer, IN _ingeststepscompleted integer, IN _fatalerror boolean, IN _transactionid integer, INOUT _message text, INOUT _returncode text) IS 'UpdateMyEMSLUploadIngestStats';

