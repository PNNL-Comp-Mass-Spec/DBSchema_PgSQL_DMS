--
CREATE OR REPLACE PROCEDURE cap.set_myemsl_upload_superseded_if_failed
(
    _datasetID int,
    _statusNumList text,
    _ingestStepsCompleted int,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Marks one or more failed MyEMSL upload tasks as superseded,
**      meaning a subsequent upload task successfully uploaded the dataset files
**
**      This procedure is called by the ArchiveStatusCheckPlugin if it finds that two
**      tasks uploaded the same files, the first task failed, but the second task succeeded
**
**  Arguments:
**    _statusNumList          The status numbers in this list must match the specified DatasetID (this is a safety check)
**    _ingestStepsCompleted   Number of ingest steps that were completed for these status nums (assumes that all the status nums completed the same steps)
**
**  Auth:   mem
**  Date:   12/16/2014 mem - Initial version
**          12/18/2014 mem - Added parameter _ingestStepsCompleted
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
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

        _datasetID := Coalesce(_datasetID, 0);
        _statusNumList := Coalesce(_statusNumList, '');
        _ingestStepsCompleted := Coalesce(_ingestStepsCompleted, 0);

        _message := '';

        If _datasetID <= 0 Then
            _message := '_datasetID must be positive; unable to continue';
            _returnCode := 'U5201';
            RETURN;
        End If;

        If char_length(_statusNumList) = 0 Then
            _message := '_statusNumList was empty; unable to continue';
            _returnCode := 'U5202';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Split the StatusNumList on commas, storing in a temporary table
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_StatusNumListTable (
            Status_Num int NOT NULL
        );

        INSERT INTO Tmp_StatusNumListTable (Status_Num)
        SELECT DISTINCT Value
        FROM public.parse_delimited_integer_list(_statusNumList, ',')
        ORDER BY Value

        If Not FOUND Then
            _message := 'No status nums were found in _statusNumList; unable to continue';
            _returnCode := 'U5203';

            DROP TABLE Tmp_StatusNumListTable;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Make sure the StatusNums in Tmp_StatusNumListTable exist in cap.t_myemsl_uploads
        ---------------------------------------------------

        If Exists (SELECT * FROM Tmp_StatusNumListTable SL LEFT OUTER JOIN cap.t_myemsl_uploads MU ON MU.status_num = SL.status_num WHERE MU.entry_id IS NULL) Then
            _message := format('One or more StatusNums in _statusNumList were not found in cap.t_myemsl_uploads: %s', _statusNumList);
            _returnCode := 'U5204';

            DROP TABLE Tmp_StatusNumListTable;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Make sure the Dataset_ID is correct
        ---------------------------------------------------

        If Exists (Select * FROM cap.t_myemsl_uploads WHERE status_num IN (Select status_num From Tmp_StatusNumListTable) And dataset_id <> _datasetID) Then
            _message := format('One or more StatusNums in _statusNumList do not have dataset_id %s in cap.t_myemsl_uploads: %s',
                                _datasetID, _statusNumList);
            _returnCode := 'U5205';

            DROP TABLE Tmp_StatusNumListTable;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Perform the update
        -- Skipping any entries that do not have 0 for ErrorCode or Verified
        ---------------------------------------------------

        UPDATE cap.t_myemsl_uploads
        SET error_code = 101
        WHERE error_code = 0 AND
              verified = 0 AND
              status_num IN ( SELECT status_num FROM Tmp_StatusNumListTable )


        If _returnCode <> '' Then
            If _message = '' Then
                _message := 'Error in set_myemsl_upload_superseded_if_failed';
            End If;

            _message := format('%s; error code = %s', _message, _returnCode);

            CALL public.post_log_entry ('Error', _message, 'Set_MyEMSL_Upload_Superseded_If_Failed', 'cap');
        End If;

        DROP TABLE Tmp_StatusNumListTable;

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

        DROP TABLE IF EXISTS Tmp_StatusNumListTable;
    END;
END
$$;

COMMENT ON PROCEDURE cap.set_myemsl_upload_superseded_if_failed IS 'SetMyEMSLUploadSupersededIfFailed';
