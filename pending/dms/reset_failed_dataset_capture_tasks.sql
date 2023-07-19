--
CREATE OR REPLACE PROCEDURE public.reset_failed_dataset_capture_tasks
(
    _resetHoldoffHours real = 2,
    _maxDatasetsToReset int = 0,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _resetCount int = 0 output
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Looks for dataset entries with state=5 (Capture Failed)
**      and a comment that indicates that we should be able to automatically
**      retry capture.  For example:
**         "Dataset not ready: Exception validating constant folder size"
**         "Dataset not ready: Exception validating constant file size"
**
**  Arguments:
**    _resetHoldoffHours    Holdoff time to apply to column Last_Affected
**    _maxDatasetsToReset   If greater than 0, will limit the number of datasets to reset
**    _infoOnly             True to preview the datasets that would be reset
**    _message              Status message
**    _resetCount           Number of datasets that were reset
**
**  Auth:   mem
**  Date:   10/25/2016 mem - Initial version
**          10/27/2016 mem - Update T_Log_Entries in DMS_Capture
**          11/02/2016 mem - Check for Folder size changed and File size changed
**          01/30/2017 mem - Switch from DateDiff to DateAdd
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          08/08/2017 mem - Call Remove_Capture_Errors_From_String instead of Remove_From_String
**          08/16/2017 mem - Look for failed Openchrom conversion tasks
**                         - Prevent dataset from being automatically reset more than 4 times
**          08/16/2017 mem - Look for 'Authentication failure: The user name or password is incorrect'
**          05/28/2019 mem - Use a holdoff of 15 minutes for authentication errors
**          08/25/2022 mem - Use new column name in T_Log_Entries
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetName text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';


    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _resetHoldoffHours := Coalesce(_resetHoldoffHours, 2);
    _maxDatasetsToReset := Coalesce(_maxDatasetsToReset, 0);
    _infoOnly := Coalesce(_infoOnly, false);

    _resetCount := 0;

    If _maxDatasetsToReset <= 0 Then
        _maxDatasetsToReset := 1000000;
    End If;

    BEGIN

        ------------------------------------------------
        -- Create a temporary table
        ------------------------------------------------

        CREATE TEMP TABLE Tmp_Datasets (
            Dataset_ID int not null,
            Dataset text not null,
            Reset_Comment text not null
        )

        ------------------------------------------------
        -- Populate a temporary table with datasets
        -- that have Dataset State 5=Capture Failed
        -- and a comment containing known errors
        ------------------------------------------------

        INSERT INTO Tmp_Datasets( dataset_id,
                                  dataset,
                                  Reset_Comment )
        SELECT dataset_id,
               dataset AS Dataset,
               '' As Reset_Comment
        FROM t_dataset
        WHERE dataset_state_id = 5 AND
              (comment LIKE '%Exception validating constant%' OR
               comment LIKE '%File size changed%' OR
               comment LIKE '%Folder size changed%' OR
               comment LIKE '%Error running OpenChrom%') AND
               last_affected < CURRENT_TIMESTAMP - make_interval(hours => _resetHoldoffHours)
        LIMIT _maxDatasetsToReset
        UNION
        SELECT dataset_id,
               dataset AS Dataset,
               '' As Reset_Comment
        FROM t_dataset
        WHERE dataset_state_id = 5 AND
              (comment Like '%Authentication failure%password is incorrect%') AND
               last_affected < CURRENT_TIMESTAMP - INTERVAL '15 minutes'
        ORDER BY dataset_id
        LIMIT _maxDatasetsToReset;

        If Not FOUND Then
            _message := 'No candidate datasets were found to reset';
            If _infoOnly Then
                RAISE INFO '%', _message;
            End If;

            DROP TABLE Tmp_Datasets;
            RETURN;
        End If;

        ------------------------------------------------
        -- Look for datasets that have been reset more than 4 times
        ------------------------------------------------

        UPDATE Tmp_Datasets
        SET Reset_Comment = 'Capture of dataset has been attempted 5 times; will not reset'
        WHERE Dataset_ID IN ( SELECT DS.Dataset_ID
                              FROM t_event_target ET
                                   INNER JOIN t_event_log EL
                                     ON ET.target_type_id = EL.target_type
                                   INNER JOIN Tmp_Datasets DS
                                     ON EL.target_id = DS.Dataset_ID
                              WHERE ET.target_type = 'Dataset' AND
                                    EL.target_state = 1 AND
                                    EL.prev_target_state = 5
                              GROUP BY DS.Dataset_ID
                              HAVING (COUNT(DS.Dataset_ID) > 4) )

        If _infoOnly Then

            ------------------------------------------------
            -- Preview the datasets to reset
            ------------------------------------------------

            -- ToDo: Update this to use RAISE INFO

            RAISE INFO '';

            _formatSpecifier := '%-10s %-10s %-10s %-10s %-10s';

            _infoHead := format(_formatSpecifier,
                                'abcdefg',
                                'abcdefg',
                                'abcdefg',
                                'abcdefg',
                                'abcdefg'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '---',
                                         '---',
                                         '---',
                                         '---',
                                         '---'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN

                SELECT DS.Dataset,
                       DS.Dataset_id,
                       Inst.Instrument,
                       DS.dataset_state_id AS State,
                       DS.Last_Affected,
                       DS.Comment,
                       Src.Reset_Comment
                FROM Tmp_Datasets Src
                    INNER JOIN t_dataset DS
                    ON Src.dataset_id = DS.dataset_id
                    INNER JOIN t_instrument_name Inst
                    ON DS.instrument_id = Inst.instrument_id
                ORDER BY Inst.instrument, DS.dataset
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Dataset,
                                    _previewData.Dataset_id,
                                    _previewData.Instrument,
                                    _previewData.State,
                                    _previewData.Last_Affected,
                                    _previewData.Comment,
                                    _previewData.Reset_Comment
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            DROP TABLE Tmp_Datasets;
            RETURN;
        End If;

        ------------------------------------------------
        -- Possibly post log error messages for datasets with a reset comment,
        -- then remove those datasets from Tmp_Datasets
        ------------------------------------------------

        INSERT INTO t_log_entries( posted_by,
                                   Entered,
                                   type,
                                   message )
        SELECT 'Reset_Failed_Dataset_Capture_Tasks',
               CURRENT_TIMESTAMP,
               'Error',
               format('%s %s', DS.Reset_Comment, DS.Dataset) AS Log_Message
        FROM Tmp_Datasets DS
             LEFT OUTER JOIN t_log_entries Logs
               ON Logs.message = format('%s %s', DS.Reset_Comment, DS.Dataset) AND
                  posted_by IN ('Reset_Failed_Dataset_Capture_Tasks', 'ResetFailedDatasetCaptureTasks')
        WHERE DS.Reset_Comment <> '' AND
              Logs.message IS NULL

        DELETE FROM Tmp_Datasets
        WHERE Reset_Comment <> '';

        ------------------------------------------------
        -- Reset the datasets
        ------------------------------------------------

        UPDATE t_dataset
        SET dataset_state_id = 1,
            comment = remove_capture_errors_from_string(comment)
        FROM Tmp_Datasets Src
            INNER JOIN t_dataset DS
            ON Src.dataset_id = DS.dataset_id
        --
        GET DIAGNOSTICS _resetCount = ROW_COUNT;

        If _resetCount > 0 Then
        -- <c>
            _message := format('Reset dataset state from "Capture Failed" to "New" for %s %s'
                                _resetCount, public.check_plural(_resetCount, 'Dataset', 'Datasets'));

            CALL post_log_entry ('Normal', _message, 'Reset_Failed_Dataset_Capture_Tasks');

            ------------------------------------------------
            -- Look for log entries in cap.t_log_entries to auto-update
            ------------------------------------------------

            FOR _datasetName IN
                SELECT Dataset
                FROM Tmp_Datasets
                ORDER BY Dataset_ID
            LOOP
                UPDATE cap.t_log_entries
                SET type = 'ErrorAutoFixed'
                WHERE type = 'error' AND
                      message LIKE '%' || _datasetName || '%' AND
                      message LIKE '%exception%' AND
                      Entered < CURRENT_TIMESTAMP;

            END LOOP;
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

    DROP TABLE IF EXISTS Tmp_Datasets;
END
$$;

COMMENT ON PROCEDURE public.reset_failed_dataset_capture_tasks IS 'ResetFailedDatasetCaptureTasks';
