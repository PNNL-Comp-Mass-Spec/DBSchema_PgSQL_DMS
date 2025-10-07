--
-- Name: reset_failed_dataset_capture_tasks(integer, integer, boolean, text, text, integer); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.reset_failed_dataset_capture_tasks(IN _resetholdoffhours integer DEFAULT 2, IN _maxdatasetstoreset integer DEFAULT 0, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, INOUT _resetcount integer DEFAULT 0)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Look for dataset entries with state=5 (Capture Failed) and a comment
**      that indicates it is safe to automatically retry capture, including:
**         "Exception validating constant"
**         "File size changed"
**         "Folder size changed%"
**         "Error running OpenChrom"
**         "Authentication failure: The user name or password is incorrect"
**
**      Also look for capture task jobs with state=5 and a failed DatasetInfo step, with message
**         "The process cannot access the file 'chromatography-data.sqlite' because it is being used by another process"
**
**  Arguments:
**    _resetHoldoffHours    Holdoff time, in hours, to apply to column last_affected
**    _maxDatasetsToReset   If greater than 0, will limit the number of datasets to reset
**    _infoOnly             When true, preview the datasets that would be reset
**    _message              Status message
**    _returnCode           Return code
**    _resetCount           Output: Number of datasets that were reset
**
**  Auth:   mem
**  Date:   10/25/2016 mem - Initial version
**          10/27/2016 mem - Update T_Log_Entries in DMS_Capture
**          11/02/2016 mem - Check for Folder size changed and File size changed
**          01/30/2017 mem - Switch from DateDiff to DateAdd
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          08/08/2017 mem - Use remove_capture_errors_from_string() instead of remove_from_string()
**          08/16/2017 mem - Look for failed Openchrom conversion tasks
**                         - Prevent dataset from being automatically reset more than 4 times
**          08/16/2017 mem - Look for 'Authentication failure: The user name or password is incorrect'
**          05/28/2019 mem - Use a holdoff of 15 minutes for authentication errors
**          08/25/2022 mem - Use new column name in T_Log_Entries
**          02/21/2024 mem - Ported to PostgreSQL
**          06/26/2024 mem - Reset datasets with a DatasetInfo job step with error "The process cannot access the file 'chromatography-data.sqlite' because it is being used by another process."
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

    _resetHoldoffHours  := Coalesce(_resetHoldoffHours, 2);
    _maxDatasetsToReset := Coalesce(_maxDatasetsToReset, 0);
    _infoOnly           := Coalesce(_infoOnly, false);

    _resetCount := 0;

    If _maxDatasetsToReset <= 0 Then
        _maxDatasetsToReset := 1000000;
    End If;

    BEGIN
        ------------------------------------------------
        -- Create a temporary table
        ------------------------------------------------

        CREATE TEMP TABLE Tmp_Datasets (
            Dataset_ID int NOT NULL,
            Dataset text NOT NULL,
            Reset_Comment text NOT NULL,
            Error_Message text NOT NULL
        );

        ------------------------------------------------
        -- Populate the temporary table with datasets
        -- that have dataset state 5=Capture Failed
        -- and a comment containing known errors
        ------------------------------------------------

        INSERT INTO Tmp_Datasets (
            Dataset_ID,
            Dataset,
            Reset_Comment,
            Error_Message
        )
        SELECT A.dataset_id,
               A.dataset,
               '' AS Reset_Comment,
               Coalesce(A.comment, 'Unknown error') AS Error_Message
        FROM (SELECT dataset_id,
                     dataset,
                     comment
              FROM t_dataset
              WHERE dataset_state_id = 5 AND    -- Capture Failed
                    (comment ILIKE '%Exception validating constant%' OR
                     comment ILIKE '%File size changed%' OR
                     comment ILIKE '%Folder size changed%' OR
                     comment ILIKE '%Error running OpenChrom%') AND
                     last_affected < CURRENT_TIMESTAMP - make_interval(hours => _resetHoldoffHours)
              LIMIT _maxDatasetsToReset
             ) A
        UNION
        SELECT dataset_id,
               dataset,
               '' AS Reset_Comment,
               Coalesce(comment, 'Unknown error') AS Error_Message
        FROM t_dataset
        WHERE dataset_state_id = 5 AND          -- Capture Failed
              comment ILIKE '%Authentication failure%password is incorrect%' AND
              last_affected < CURRENT_TIMESTAMP - Interval '15 minutes'
        UNION
        SELECT T.dataset_id,
               T.dataset,
               '' AS Reset_Comment,
               Coalesce(TS.Completion_Message, 'Unknown Error') AS Error_Message
        FROM cap.T_Task_Steps AS TS
             INNER JOIN cap.T_Tasks AS T
               ON TS.Job = T.Job
        WHERE T.State = 5 AND                   -- Capture task job failed
              TS.State = 6 AND                  -- Job step failed
              TS.Tool LIKE '%datasetinfo' AND
              TS.Completion_Message LIKE '%The process cannot access the file %sqlite% used by another process%' AND
              TS.Finish < CURRENT_TIMESTAMP - Interval '15 minutes'
        ORDER BY dataset_id
        LIMIT _maxDatasetsToReset;

        If Not FOUND Then
            _message := 'No candidate datasets were found to reset';
            If _infoOnly Then
                RAISE INFO '';
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
        WHERE Dataset_ID IN (SELECT DS.Dataset_ID
                             FROM t_event_target ET
                                  INNER JOIN t_event_log EL
                                    ON ET.target_type_id = EL.target_type
                                  INNER JOIN Tmp_Datasets DS
                                    ON EL.target_id = DS.Dataset_ID
                             WHERE ET.target_type = 'Dataset' AND
                                   EL.target_state = 1 AND
                                   EL.prev_target_state = 5
                             GROUP BY DS.Dataset_ID
                             HAVING (COUNT(DS.Dataset_ID) > 4)
                            );

        If _infoOnly Then

            ------------------------------------------------
            -- Preview the datasets to reset
            ------------------------------------------------

            RAISE INFO '';

            _formatSpecifier := '%-80s %-10s %-25s %-5s %-20s %-160s %-80s %-80s %-40s';

            _infoHead := format(_formatSpecifier,
                                'Dataset',
                                'Dataset_id',
                                'Instrument',
                                'State',
                                'Last_Affected',
                                'Error Message',
                                'Current Dataset Comment',
                                'Updated Dataset Comment',
                                'Reset_Comment'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '--------------------------------------------------------------------------------',
                                         '----------',
                                         '-------------------------',
                                         '-----',
                                         '--------------------',
                                         '----------------------------------------------------------------------------------------------------------------------------------------------------------------',
                                         '--------------------------------------------------------------------------------',
                                         '--------------------------------------------------------------------------------',
                                         '----------------------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT DS.dataset,
                       DS.dataset_id AS DatasetID,
                       Inst.instrument,
                       DS.dataset_state_id AS State,
                       public.timestamp_text(DS.Last_Affected) AS LastAffected,
                       Src.Error_Message AS ErrorMessage,
                       DS.comment AS CurrentComment,
                       remove_capture_errors_from_string(DS.comment) AS UpdatedComment,
                       Src.Reset_Comment AS ResetComment
                FROM Tmp_Datasets Src
                     INNER JOIN t_dataset DS
                       ON Src.dataset_id = DS.dataset_id
                     INNER JOIN t_instrument_name Inst
                       ON DS.instrument_id = Inst.instrument_id
                ORDER BY Inst.instrument, DS.dataset
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Dataset,
                                    _previewData.DatasetID,
                                    _previewData.Instrument,
                                    _previewData.State,
                                    _previewData.LastAffected,
                                    _previewData.ErrorMessage,
                                    _previewData.CurrentComment,
                                    _previewData.UpdatedComment,
                                    _previewData.ResetComment
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

        INSERT INTO t_log_entries (
            posted_by,
            entered,
            type,
            message
        )
        SELECT 'Reset_Failed_Dataset_Capture_Tasks',
               CURRENT_TIMESTAMP,
               'Error',
               format('%s %s', DS.Reset_Comment, DS.Dataset) AS Log_Message
        FROM Tmp_Datasets DS
             LEFT OUTER JOIN t_log_entries Logs
               ON Logs.message = format('%s %s', DS.Reset_Comment, DS.Dataset) AND
                  posted_by IN ('Reset_Failed_Dataset_Capture_Tasks', 'ResetFailedDatasetCaptureTasks')
        WHERE DS.Reset_Comment <> '' AND
              Logs.message IS NULL;

        DELETE FROM Tmp_Datasets
        WHERE Reset_Comment <> '';

        ------------------------------------------------
        -- Reset the datasets
        ------------------------------------------------

        UPDATE t_dataset target
        SET dataset_state_id = 1,
            comment = remove_capture_errors_from_string(target.comment)
        WHERE EXISTS (SELECT 1
                      FROM Tmp_Datasets Src
                      WHERE target.dataset_id = Src.Dataset_ID);
        --
        GET DIAGNOSTICS _resetCount = ROW_COUNT;

        If _resetCount > 0 Then

            _message := format('Reset dataset state from "Capture Failed" to "New" for %s %s',
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
                WHERE type = 'Error' AND
                      message ILIKE '%' || _datasetName || '%' AND
                      message ILIKE '%exception%' AND
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


ALTER PROCEDURE public.reset_failed_dataset_capture_tasks(IN _resetholdoffhours integer, IN _maxdatasetstoreset integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, INOUT _resetcount integer) OWNER TO d3l243;

--
-- Name: PROCEDURE reset_failed_dataset_capture_tasks(IN _resetholdoffhours integer, IN _maxdatasetstoreset integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, INOUT _resetcount integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.reset_failed_dataset_capture_tasks(IN _resetholdoffhours integer, IN _maxdatasetstoreset integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, INOUT _resetcount integer) IS 'ResetFailedDatasetCaptureTasks';

