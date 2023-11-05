--
-- Name: set_myemsl_upload_verified(integer, text, text, integer, text, text); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.set_myemsl_upload_verified(IN _datasetid integer, IN _statusnumlist text, IN _statusurilist text, IN _ingeststepscompleted integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Marks one or more MyEMSL upload tasks as verified by the MyEMSL ingest process
**
**      This procedure should only be called after the MyEMSL Status page includes the text "state": "OK"
**      For example, see https://ingestdms.my.emsl.pnl.gov/get_state?job_id=2825262
**
**  Arguments:
**    _statusNumList          Comma-separated list of status numbers; these must all match the specified DatasetID and they must match the cap.t_myemsl_uploads entries that the _statusURIList values match
**    _statusURIList          Comma-separated list of status URIs; these must all match the specified DatasetID using V_MyEMSL_Uploads (this is a safety check)
**    _ingestStepsCompleted   Number of ingest steps that were completed for these status nums (assumes that all the status nums completed the same steps)
**
**  Auth:   mem
**  Date:   09/20/2013 mem - Initial version
**          12/19/2014 mem - Added parameter _ingestStepsCompleted
**          05/31/2017 mem - Add logging
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          07/13/2017 mem - Add parameter _statusURIList (required to avoid conflicts between StatusNums from the old MyEMSL backend vs. transaction IDs from the new backend)
**          08/01/2017 mem - Use THROW if not authorized
**          06/26/2023 mem - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_list or parse_delimited_integer_list for a comma-separated list
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _statusNumCount int;
    _statusURICount int;
    _entryIDCount int;

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
        _statusNumList        := Trim(Coalesce(_statusNumList, ''));
        _statusURIList        := Trim(Coalesce(_statusURIList, ''));
        _ingestStepsCompleted := Coalesce(_ingestStepsCompleted, 0);

        If _datasetID <= 0 Then
            _message := '_datasetID must be positive; unable to continue';
            _returnCode := 'U5201';
            RETURN;
        End If;

        If _statusNumList = '' Then
            _message := '_statusNumList was empty; unable to continue';
            _returnCode := 'U5202';
            RETURN;
        End If;

        If _statusURIList = '' Then
            _message := '_statusURIList was empty; unable to continue';
            _returnCode := 'U5203';
            RETURN;
        End If;

        ---------------------------------------------------
        -- Split StatusNumList and StatusURIList on commas, storing in temporary tables
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_StatusNumListTable (
            Status_Num int NOT NULL
        );

        CREATE TEMP TABLE Tmp_StatusURIListTable (
            Status_URI text NOT NULL
        );

        INSERT INTO Tmp_StatusNumListTable (Status_Num)
        SELECT DISTINCT Value
        FROM public.parse_delimited_integer_list(_statusNumList)
        ORDER BY Value;

        GET DIAGNOSTICS _statusNumCount = ROW_COUNT;

        If _statusNumCount = 0 Then
            _message := 'No status nums were found in _statusNumList; unable to continue';
            _returnCode := 'U5204';

            DROP TABLE Tmp_StatusNumListTable;
            DROP TABLE Tmp_StatusURIListTable;
            RETURN;
        End If;

        INSERT INTO Tmp_StatusURIListTable (Status_URI)
        SELECT DISTINCT Value
        FROM public.parse_delimited_list(_statusURIList)
        ORDER BY Value;

        GET DIAGNOSTICS _statusURICount = ROW_COUNT;

        If _statusURICount = 0 Then
            _message := 'No status URIs were found in _statusURIList; unable to continue';
            _returnCode := 'U5205';

            DROP TABLE Tmp_StatusNumListTable;
            DROP TABLE Tmp_StatusURIListTable;
            RETURN;
        End If;

        If _statusNumCount <> _statusURICount Then
            _message := 'Differing number of Status Nums and Status URIs; unable to continue';
            _returnCode := 'U5206';

            DROP TABLE Tmp_StatusNumListTable;
            DROP TABLE Tmp_StatusURIListTable;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Make sure the transaction IDs in Tmp_StatusNumListTable exist in cap.t_myemsl_uploads
        ---------------------------------------------------

        If Exists (SELECT * FROM Tmp_StatusNumListTable SL LEFT OUTER JOIN cap.t_myemsl_uploads MU ON MU.status_num = SL.status_num WHERE MU.entry_id IS NULL) Then
            _message := format('One or more Status Nums in _statusNumList were not found in cap.t_myemsl_uploads: %s', _statusNumList);
            _returnCode := 'U5207';

            DROP TABLE Tmp_StatusNumListTable;
            DROP TABLE Tmp_StatusURIListTable;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Find the Entry_ID values of the status entries to examine, storing in a temporary table
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_StatusEntryIDsTable (
            Entry_ID int NOT NULL,
            Dataset_ID int NOT NULL
        );

        INSERT INTO Tmp_StatusEntryIDsTable (Entry_ID, Dataset_ID)
        SELECT Entry_ID, Dataset_ID
        FROM cap.V_MyEMSL_Uploads
        WHERE Status_Num IN (SELECT Status_Num FROM Tmp_StatusNumListTable) AND
              Status_URI IN (SELECT Status_URI FROM Tmp_StatusURIListTable);

        GET DIAGNOSTICS _entryIDCount = ROW_COUNT;

        If _entryIDCount < _statusURICount Then
            _message := format('One or more Status URIs do not correspond to a given Status Num in V_MyEMSL_Uploads; see %s and %s', _statusNumList, _statusURIList);
            _returnCode := 'U5208';

            DROP TABLE Tmp_StatusNumListTable;
            DROP TABLE Tmp_StatusURIListTable;
            DROP TABLE Tmp_StatusEntryIDsTable;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Make sure the Dataset_ID is correct
        ---------------------------------------------------

        If Exists (SELECT Dataset_ID FROM Tmp_StatusEntryIDsTable WHERE Dataset_ID <> _datasetID) Then
            _message := format('One or more Status Nums in _statusNumList do not have Dataset_ID %s in V_MyEMSL_Uploads; see %s and %s', _datasetID, _statusNumList, _statusURIList);
            _returnCode := 'U5209';

            DROP TABLE Tmp_StatusNumListTable;
            DROP TABLE Tmp_StatusURIListTable;
            DROP TABLE Tmp_StatusEntryIDsTable;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Perform the update
        ---------------------------------------------------

        -- First update Ingest_Steps_Completed for steps that have already been verified
        --
        UPDATE cap.t_myemsl_uploads
        SET ingest_steps_completed = _ingestStepsCompleted
        WHERE verified = 1 AND
              entry_id IN ( SELECT entry_id FROM Tmp_StatusEntryIDsTable ) AND
              (ingest_steps_completed Is Null Or ingest_steps_completed < _ingestStepsCompleted);

        -- Now update newly verified steps
        --
        UPDATE cap.t_myemsl_uploads
        SET verified = 1,
            ingest_steps_completed = _ingestStepsCompleted
        WHERE verified = 0 AND
              entry_id IN ( SELECT entry_id FROM Tmp_StatusEntryIDsTable );

        DROP TABLE Tmp_StatusNumListTable;
        DROP TABLE Tmp_StatusURIListTable;
        DROP TABLE Tmp_StatusEntryIDsTable;

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
        DROP TABLE IF EXISTS Tmp_StatusURIListTable;
        DROP TABLE IF EXISTS Tmp_StatusEntryIDsTable;
    END;

END
$$;


ALTER PROCEDURE cap.set_myemsl_upload_verified(IN _datasetid integer, IN _statusnumlist text, IN _statusurilist text, IN _ingeststepscompleted integer, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE set_myemsl_upload_verified(IN _datasetid integer, IN _statusnumlist text, IN _statusurilist text, IN _ingeststepscompleted integer, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.set_myemsl_upload_verified(IN _datasetid integer, IN _statusnumlist text, IN _statusurilist text, IN _ingeststepscompleted integer, INOUT _message text, INOUT _returncode text) IS 'SetMyEMSLUploadVerified';

