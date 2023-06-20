--
CREATE OR REPLACE PROCEDURE cap.make_new_tasks_from_dms
(
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _maxJobsToProcess int = 0,
    _logIntervalThreshold int = 15,
    _loggingEnabled boolean = false,
    _infoOnly boolean = false,
    _debugMode boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Add dataset capture task jobs for datasets in state New in public.t_dataset
**
**  Arguments:
**    _message                 Output message
**    _maxJobsToProcess        Maximum number of jobs to process
**    _logIntervalThreshold    If this procedure runs longer than this threshold (in seconds), status messages will be posted to the log
**    _loggingEnabled          Set to true to immediately enable progress logging; if false, logging will auto-enable if _logIntervalThreshold seconds elapse
**    _infoOnly                True to preview changes that would be made
**    _debugMode               True to see debug messages
**
**  Auth:   grk
**  Date:   09/02/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          02/10/2010 dac - Removed comment stating that capture task jobs were created from test script
**          03/09/2011 grk - Added logic to choose different capture script based on instrument group
**          09/17/2015 mem - Added parameter _infoOnly
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          06/27/2019 mem - Use get_dataset_capture_priority to determine capture capture task jobs priority using dataset name and instrument group
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _formatSpecifier text := '%-20s %-10s %-10s %-50s';
    _infoHead text;
    _infoHeadSeparator text;
    _infoData text;
    _previewData record;

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

        _infoOnly := Coalesce(_infoOnly, false);
        _debugMode := Coalesce(_debugMode, false);
        _maxJobsToProcess := Coalesce(_maxJobsToProcess, 0);

        _message := '';

        If _maxJobsToProcess <= 0 Then
            _maxJobsToAddResetOrResume := 1000000;
        Else
            _maxJobsToAddResetOrResume := _maxJobsToProcess;
        End If;

        _startTime := CURRENT_TIMESTAMP;
        _loggingEnabled := Coalesce(_loggingEnabled, false);
        _logIntervalThreshold := Coalesce(_logIntervalThreshold, 15);

        If _logIntervalThreshold = 0 Then
            _loggingEnabled := true;
        End If;

        If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
            _statusMessage := 'Entering make_new_tasks_from_dms';
            CALL public.post_log_entry('Progress', _statusMessage, 'Make_New_Tasks_From_DMS', 'cap');
        End If;

        ---------------------------------------------------
        -- Add new capture task jobs
        ---------------------------------------------------

        If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
            _statusMessage := 'Querying DMS';
            CALL public.post_log_entry('Progress', _statusMessage, 'Make_New_Tasks_From_DMS', 'cap');
        End If;

        If Not _infoOnly Then

            INSERT INTO cap.t_tasks( Script,
                                     comment,
                                     Dataset,
                                     Dataset_ID,
                                     Priority)
            SELECT CASE
                       WHEN Src.IN_Group = 'IMS' THEN 'IMSDatasetCapture'
                       ELSE 'DatasetCapture'
                   END AS Script,
                   '' AS comment,
                   Src.Dataset,
                   Src.Dataset_ID,
                   cap.get_dataset_capture_priority(Src.Dataset, Src.IN_Group)
            FROM cap.V_DMS_Get_New_Datasets Src
                 LEFT OUTER JOIN cap.t_tasks Target
                   ON Src.Dataset_ID = Target.Dataset_ID
            WHERE Target.Dataset_ID IS NULL;

        Else
            RAISE INFO '';

            _infoHead := format(_formatSpecifier,
                                'Script',
                                'Dataset_ID',
                                'Priority',
                                'Dataset'
                            );

            _infoHeadSeparator := format(_formatSpecifier,
                                '--------------------',
                                '----------',
                                '----------',
                                '--------------------------------------------------'
                            );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT CASE
                           WHEN Src.IN_Group = 'IMS' THEN 'IMSDatasetCapture'
                           ELSE 'DatasetCapture'
                       END AS Script,
                       Src.Dataset_ID,
                       cap.get_dataset_capture_priority(Src.Dataset, Src.IN_Group) As Priority
                       Src.Dataset,
                FROM cap.V_DMS_Get_New_Datasets Src
                     LEFT OUTER JOIN cap.t_tasks Target
                       ON Src.Dataset_ID = Target.Dataset_ID
                WHERE Target.Dataset_ID IS NULL
            LOOP
                _infoData := format(_formatSpecifier,
                                        _previewData.Script,
                                        _previewData.Dataset_ID,
                                        _previewData.Priority,
                                        _previewData.Dataset
                                );

                RAISE INFO '%', _infoData;

            END LOOP;

        End If;

        If _loggingEnabled Or extract(epoch FROM clock_timestamp() - _startTime) >= _logIntervalThreshold Then
            _statusMessage := 'Exiting';
            CALL public.post_log_entry('Progress', _statusMessage, 'Make_New_Tasks_From_DMS', 'cap');
        End If;

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

COMMENT ON PROCEDURE cap.make_new_tasks_from_dms IS 'MakeNewJobsFromDMS';
