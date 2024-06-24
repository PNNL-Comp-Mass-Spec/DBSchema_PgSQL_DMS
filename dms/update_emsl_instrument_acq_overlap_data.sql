--
-- Name: update_emsl_instrument_acq_overlap_data(text, integer, integer, boolean, boolean, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_emsl_instrument_acq_overlap_data(IN _instrument text, IN _year integer, IN _month integer, IN _infoonly boolean DEFAULT false, IN _showstarttimes boolean DEFAULT false, IN _showpendingupdates boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Populate column dataset_id_acq_overlap in t_emsl_instrument_usage_report
**      This is used to track datasets with identical acquisition start times
**
**  Arguments:
**    _instrument           Instrument name
**    _year                 If 0, process all rows for the given instrument
**    _month                If 0, do not filter on month
**    _infoOnly             When true, preview updates
**    _showStartTimes       When _infoOnly is true, set this to true to also show the contents of Tmp_DatasetStartTimes
**    _showPendingUpdates   When _infoOnly is true, set this to true to also show Tmp_UpdatesToApply without joining to T_EMSL_Instrument_Usage_Report
**    _message              Status message
**    _returnCode           Return code
**
**  Auth:   mem
**  Date:   03/17/2022 mem - Initial version
**          08/29/2023 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _matchCount int;
    _dmsInstrumentID int;
    _startDate timestamp;
    _endDate timestamp;
    _startTimeInfo record;
    _datasetID int;
    _lastSeq int;

    _updateCountOverall int;
    _updateCount int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := Trim(Coalesce(_message, ''));
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name, name_with_schema
    INTO _currentSchema, _currentProcedure, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        BEGIN
            -- Commit changes to persist the message logged to public.t_log_entries
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
            -- The commit failed, likely because this procedure was called from the DMS website, which wraps procedure calls in a transaction
            -- Ignore the commit error (t_log_entries will not be updated, but _message will be updated)
        END;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Validate parameters
    ---------------------------------------------------

    _instrument := Trim(Coalesce(_instrument, ''));
    _year       := Coalesce(_year, 0);
    _month      := Coalesce(_month, 0);

    _infoOnly           := Coalesce(_infoOnly, false);
    _showStartTimes     := Coalesce(_showStartTimes, false);
    _showPendingUpdates := Coalesce(_showPendingUpdates, false);

    If _instrument = '' Then
        _message := 'Instrument must be specified';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    SELECT instrument_id
    INTO _dmsInstrumentID
    FROM t_instrument_name
    WHERE instrument = _instrument::citext;

    If Not FOUND Then
        _message := format('Unrecognized instrument name: %s', _instrument);
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    If Not _month Between 0 And 12 Then
        _message := format('Invalid month: %s', _month);
        RAISE WARNING '%', _message;

        _returnCode := 'U5203';
        RETURN;
    End If;

    BEGIN

        ---------------------------------------------------
        -- Temporary table for rows to process
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_DatasetStartTimes (
            Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            DMS_Inst_ID int NOT NULL,
            ItemType text NOT NULL,         -- 'Dataset' or 'Interval'
            StartTime timestamp NOT NULL,
            Datasets int NULL               -- Number of datasets or number of long intervals with this start time
        );

        -- ItemType and Datasets are included here so that they're included in the index, removing the need for a table lookup
        CREATE UNIQUE INDEX IX_Tmp_DatasetStartTimes_ID_Datasets On Tmp_DatasetStartTimes (Entry_ID, ItemType, Datasets);

        -- Also create an index that supports StartTime lookup by dataset and type
        CREATE UNIQUE INDEX IX_Tmp_DatasetStartTimes_InstID_StartTime On Tmp_DatasetStartTimes (DMS_Inst_ID, ItemType, StartTime);

        ---------------------------------------------------
        -- Temporary table to hold rows to update when previewing updates
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_UpdatesToApply (
            Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            DMS_Inst_ID int NOT NULL,
            ItemType text NOT NULL,         -- 'Dataset' or 'Interval'
            Start timestamp NOT NULL,
            Dataset_ID int NOT NULL,
            Seq int NOT NULL,
            Dataset text NULL,
            Dataset_ID_Acq_Overlap int NULL
        );

        If _infoOnly Then
            RAISE INFO '';
        End If;

        If _year <= 0 Then
            INSERT INTO Tmp_DatasetStartTimes (
                DMS_Inst_ID,
                ItemType,
                StartTime,
                Datasets
            )
            SELECT dms_inst_id,
                   type,
                   start,
                   COUNT(seq)
            FROM t_emsl_instrument_usage_report
            WHERE dms_inst_id = _dmsInstrumentID
            GROUP BY dms_inst_id, type, start
            ORDER BY dms_inst_id, type, start;
            --
            GET DIAGNOSTICS _matchCount = ROW_COUNT;

            If _infoOnly Then
                RAISE INFO 'Processing % % for instrument % in t_emsl_instrument_usage_report (no date filter)',
                            _matchCount, public.check_plural(_matchCount, 'start time', 'start times'), _instrument;
            End If;
        Else
            If _month <= 0 Then
                _startDate := make_date(_year, 1, 1);
                _endDate   := _startDate + INTERVAL '1 year';
            Else
                _startDate := make_date(_year, _month, 1);
                _endDate := _startDate + INTERVAL '1 month';
            End If;

            INSERT INTO Tmp_DatasetStartTimes (
                DMS_Inst_ID,
                ItemType,
                StartTime,
                Datasets
            )
            SELECT dms_inst_id,
                   type,
                   start,
                   COUNT(seq)
            FROM t_emsl_instrument_usage_report
            WHERE start BETWEEN _startDate AND _endDate AND
                  dms_inst_id = _dmsInstrumentID
            GROUP BY dms_inst_id, type, start
            ORDER BY dms_inst_id, type, start;
            --
            GET DIAGNOSTICS _matchCount = ROW_COUNT;

            If _infoOnly Then
                RAISE INFO 'Processing % % for instrument % in t_emsl_instrument_usage_report',
                            _matchCount, public.check_plural(_matchCount, 'start time', 'start times'), _instrument;

                RAISE INFO 'Filtering for start between % and %',
                            to_char(_startDate, 'yyyy-mm-dd'),
                            to_char(_endDate, 'yyyy-mm-dd');
            End If;
        End If;

        If Not _infoOnly Then
            -- Set Dataset_ID_Acq_Overlap to Null for any entries where it is currently not null,
            -- yet there is only one dataset (or interval) for the given start time

            UPDATE t_emsl_instrument_usage_report InstUsage
            SET dataset_id_acq_overlap = NULL
            FROM (SELECT DMS_Inst_ID,
                         ItemType,
                         StartTime
                  FROM Tmp_DatasetStartTimes
                  WHERE Datasets = 1
                 ) FilterQ
            WHERE InstUsage.dms_inst_id = FilterQ.DMS_Inst_ID AND
                  InstUsage.type = FilterQ.ItemType AND
                  InstUsage.start = FilterQ.StartTime AND
                  NOT InstUsage.dataset_id_acq_overlap IS NULL;

        End If;

        If _infoOnly And _showStartTimes Then

            RAISE INFO '';

            _formatSpecifier := '%-8s %-17s %-10s %-20s %-8s';

            _infoHead := format(_formatSpecifier,
                                'Entry_ID',
                                'DMS_Instrument_ID',
                                'Item_Type',
                                'Start_Time',
                                'Datasets'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '--------',
                                         '-----------------',
                                         '----------',
                                         '--------------------',
                                         '--------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Entry_ID,
                       DMS_Inst_ID AS DMS_Instrument_ID,
                       ItemType AS Item_Type,
                       public.timestamp_text(StartTime) AS Start_Time,
                       Datasets
                FROM Tmp_DatasetStartTimes
                ORDER BY Entry_ID
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Entry_ID,
                                    _previewData.DMS_Instrument_ID,
                                    _previewData.Item_Type,
                                    _previewData.Start_Time,
                                    _previewData.Datasets
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

        _updateCountOverall := 0;

        FOR _startTimeInfo IN
            SELECT DMS_Inst_ID AS DmsInstrumentID,
                   ItemType,
                   StartTime
            FROM Tmp_DatasetStartTimes
            WHERE Datasets > 1
            ORDER BY Entry_ID
        LOOP
            -- Find the best dataset ID to represent the group of datasets (or group of intervals) that start at _startTimeInfo.StartTime
            -- Choose the dataset (or interval) with the longest runtime
            -- If ties, sort by dataset name

            -- If a dataset was deleted from DMS then re-uploaded under a new name,
            -- table t_emsl_instrument_usage_report may have two rows for the dataset
            -- Since this query uses an inner join, it will select the dataset_id of the existing dataset

            _datasetID := null;
            _lastSeq := null;

            SELECT InstUsage.dataset_id,
                   InstUsage.seq
            INTO _datasetID, _lastSeq
            FROM t_emsl_instrument_usage_report InstUsage
                 INNER JOIN t_dataset DS
                   ON InstUsage.dataset_id = DS.dataset_id
            WHERE InstUsage.dms_inst_id = _startTimeInfo.DmsInstrumentID AND
                  InstUsage.start = _startTimeInfo.StartTime AND
                  InstUsage.type = _startTimeInfo.ItemType
            ORDER BY InstUsage.minutes DESC, DS.dataset ASC, seq DESC
            LIMIT 1;

            If Not FOUND Then
                -- All of the entries in t_emsl_instrument_usage_report with this start time are missing from t_dataset
                -- Re-query, this time only using t_emsl_instrument_usage_report

                SELECT dataset_id, seq
                INTO _datasetID, _lastSeq
                FROM t_emsl_instrument_usage_report
                WHERE dms_inst_id = _startTimeInfo.DmsInstrumentID AND
                      start = _startTimeInfo.StartTime AND
                      type = _startTimeInfo.ItemType
                ORDER BY minutes DESC, dataset_id DESC, seq DESC
                LIMIT 1;
            End If;

            If Not _infoOnly Then
                -- Store Null in Dataset_ID_Acq_Overlap for dataset ID _datasetID
                -- Store _datasetID in Dataset_ID_Acq_Overlap for the other datasets that start at _startTimeInfo.StartTime
                -- _lastSeq is used to assure that only one entry has a null value for Dataset_ID_Acq_Overlap

                UPDATE t_emsl_instrument_usage_report
                SET dataset_id_acq_overlap = CASE WHEN dataset_id = _datasetID AND seq = _lastSeq
                                                  THEN NULL
                                                  ELSE _datasetID
                                             END
                WHERE DMS_Inst_ID = _startTimeInfo.DmsInstrumentID AND
                      Start = _startTimeInfo.StartTime AND
                      Type = _startTimeInfo.ItemType;
                --
                GET DIAGNOSTICS _updateCount = ROW_COUNT;

                _updateCountOverall := _updateCountOverall + _updateCount;
            Else

                INSERT INTO Tmp_UpdatesToApply (
                    DMS_Inst_ID,
                    ItemType,
                    Start,
                    Dataset_ID,
                    Seq,
                    Dataset,
                    Dataset_ID_Acq_Overlap
                )
                SELECT InstUsage.DMS_Inst_ID,
                       InstUsage.Type,
                       InstUsage.Start,
                       InstUsage.Dataset_ID,
                       InstUsage.Seq,
                       DS.Dataset,
                       CASE WHEN InstUsage.Dataset_ID = _datasetID AND InstUsage.Seq = _lastSeq
                            THEN NULL
                            ELSE _datasetID
                       END
                FROM t_emsl_instrument_usage_report InstUsage
                     LEFT OUTER JOIN t_dataset DS
                       ON InstUsage.dataset_id = DS.dataset_id
                WHERE InstUsage.dms_inst_id = _startTimeInfo.DmsInstrumentID AND
                      InstUsage.start = _startTimeInfo.StartTime AND
                      InstUsage.type = _startTimeInfo.ItemType
                ORDER BY CASE WHEN InstUsage.dataset_id = _datasetID AND seq = _lastSeq THEN 1
                              WHEN InstUsage.dataset_id = _datasetID THEN 2
                              ELSE 3
                         END,
                         DS.Dataset;
            End If;

        END LOOP;

        If Not _infoOnly Then
            If _updateCountOverall > 0 Then
                RAISE INFO 'Updated % % in t_emsl_instrument_usage_report', _updateCountOverall, public.check_plural(_updateCountOverall, 'row', 'rows');
            End If;

            DROP TABLE Tmp_DatasetStartTimes;
            DROP TABLE Tmp_UpdatesToApply;
            RETURN;
        End If;

        If Not Exists (SELECT Entry_ID FROM Tmp_UpdatesToApply) Then
            RAISE INFO '';
            RAISE INFO 'No updates are required';

            DROP TABLE Tmp_DatasetStartTimes;
            DROP TABLE Tmp_UpdatesToApply;
            RETURN;
        End If;

        If _showPendingUpdates Then

            RAISE INFO '';
            RAISE INFO 'Updates to apply (as tracked by Tmp_UpdatesToApply):';
            RAISE INFO '';

            _formatSpecifier := '%-8s %-17s %-10s %-20s %-10s %-5s %-80s %-22s';

            _infoHead := format(_formatSpecifier,
                                'Entry_ID',
                                'DMS_Instrument_ID',
                                'Item_Type',
                                'Start',
                                'Dataset_ID',
                                'Seq',
                                'Dataset',
                                'Dataset_ID_Acq_Overlap'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '--------',
                                         '-----------------',
                                         '----------',
                                         '--------------------',
                                         '----------',
                                         '-----',
                                         '--------------------------------------------------------------------------------',
                                         '----------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT U.Entry_ID,
                       U.DMS_Inst_ID AS DMS_Instrument_ID,
                       U.ItemType AS Item_Type,
                       public.timestamp_text(U.Start) AS Start,
                       U.Dataset_ID,
                       U.Seq,
                       U.Dataset,
                       U.Dataset_ID_Acq_Overlap
                FROM Tmp_UpdatesToApply U
                ORDER BY Entry_ID
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Entry_ID,
                                    _previewData.DMS_Instrument_ID,
                                    _previewData.Item_Type,
                                    _previewData.Start,
                                    _previewData.Dataset_ID,
                                    _previewData.Seq,
                                    _previewData.Dataset,
                                    _previewData.Dataset_ID_Acq_Overlap
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

        RAISE INFO '';
        RAISE INFO 'Updates to apply, including acquisition length (in minutes) from t_emsl_instrument_usage_report';
        RAISE INFO '';

        _formatSpecifier := '%-8s %-17s %-10s %-20s %-7s %-10s %-5s %-80s %-22s';

        _infoHead := format(_formatSpecifier,
                            'Entry_ID',
                            'DMS_Instrument_ID',
                            'Item_Type',
                            'Start',
                            'Minutes',
                            'Dataset_ID',
                            'Seq',
                            'Dataset',
                            'Dataset_ID_Acq_Overlap'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '--------',
                                     '-----------------',
                                     '----------',
                                     '--------------------',
                                     '-------',
                                     '----------',
                                     '-----',
                                     '--------------------------------------------------------------------------------',
                                     '----------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT U.Entry_ID,
                   U.DMS_Inst_ID AS DMS_Instrument_ID,
                   U.ItemType AS Item_Type,
                   public.timestamp_text(U.Start) AS Start,
                   InstUsage.Minutes,
                   U.Dataset_ID,
                   U.Seq,
                   U.Dataset,
                   U.Dataset_ID_Acq_Overlap
            FROM Tmp_UpdatesToApply U
                 INNER JOIN t_emsl_instrument_usage_report InstUsage
                   ON U.dataset_id = InstUsage.dataset_id AND
                      U.start = InstUsage.start AND
                      U.ItemType = InstUsage.type AND
                      U.seq = InstUsage.seq
            ORDER BY Entry_ID
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Entry_ID,
                                _previewData.DMS_Instrument_ID,
                                _previewData.Item_Type,
                                _previewData.Start,
                                _previewData.Minutes,
                                _previewData.Dataset_ID,
                                _previewData.Seq,
                                _previewData.Dataset,
                                _previewData.Dataset_ID_Acq_Overlap
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

        DROP TABLE Tmp_DatasetStartTimes;
        DROP TABLE Tmp_UpdatesToApply;
        RETURN;

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

    DROP TABLE IF EXISTS Tmp_DatasetStartTimes;
    DROP TABLE IF EXISTS Tmp_UpdatesToApply;
END
$$;


ALTER PROCEDURE public.update_emsl_instrument_acq_overlap_data(IN _instrument text, IN _year integer, IN _month integer, IN _infoonly boolean, IN _showstarttimes boolean, IN _showpendingupdates boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_emsl_instrument_acq_overlap_data(IN _instrument text, IN _year integer, IN _month integer, IN _infoonly boolean, IN _showstarttimes boolean, IN _showpendingupdates boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_emsl_instrument_acq_overlap_data(IN _instrument text, IN _year integer, IN _month integer, IN _infoonly boolean, IN _showstarttimes boolean, IN _showpendingupdates boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateEMSLInstrumentAcqOverlapData';

