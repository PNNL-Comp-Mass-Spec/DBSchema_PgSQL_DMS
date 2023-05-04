--
CREATE OR REPLACE PROCEDURE public.update_emsl_instrument_acq_overlap_data
(
    _instrument text,
    _year int,
    _month int,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = false,
    _showStartTimes boolean = false
    _showPendingUpdates boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Populate field Dataset_ID_Acq_Overlap in T_EMSL_Instrument_Usage_Report
**      This is used to track datasets with identical acquisition start times
**
**  Arguments:
**    _instrument           Instrument name
**    _year                 If 0, process all rows for the given instrument
**    _month                If 0, do not filter on month
**    _infoOnly             When true, preview updates
**    _showStartTimes       When _infoOnly is true, set this to true to also show the contents of Tmp_DatasetStartTimes
**    _showPendingUpdates   When _infoOnly is true, set this to true to also show Tmp_UpdatesToApply without joining to T_EMSL_Instrument_Usage_Report
**
**  Auth:   mem
**  Date:   03/17/2022 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _myRowCount int := 0;
    _dmsInstrumentID Int;
    _startDate timestamp;
    _endDate timestamp;
    _startTimeInfo record
    _datasetID int;
    _lastSeq int;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := Trim(Coalesce(_message, ''));
    _returnCode := '';

    _instrument := Coalesce(_instrument, '');
    _year := Coalesce(_year, 0);
    _month := Coalesce(_month, 0);

    _infoOnly := Coalesce(_infoOnly, false);
    _showStartTimes := Coalesce(_showStartTimes, false);
    _showPendingUpdates := Coalesce(_showPendingUpdates, false);

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    ------------------------------------------------------
    -- Validate parameters
    ------------------------------------------------------
    --
    If _instrument = '' Then
        _message := '_instrument must be defined';
        RAISE WARNING '%', _message;

        _returnCode := 'U5201';
        RETURN;
    End If;

    SELECT instrument_id
    INTO _dmsInstrumentID
    FROM t_instrument_name
    WHERE instrument = _instrument;

    If Not FOUND Then
        _message := 'Invalid DMS instrument name: ' || _instrument;
        RAISE WARNING '%', _message;

        _returnCode := 'U5202';
        RETURN;
    End If;

    BEGIN

        ---------------------------------------------------
        -- Temporary table for rows to process
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_DatasetStartTimes (
            ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            DMS_Inst_ID int Not Null,
            ItemType text Not Null,         -- 'Dataset' or 'Interval'
            StartTime timestamp Not Null,
            Datasets int Null                       -- Number of datasets or number of long intervals with this start time
        )

        -- ItemType and Datasets are included here so that they're included in the index, removing the need for a table lookup
        CREATE UNIQUE INDEX IX_Tmp_DatasetStartTimes_ID_Datasets On Tmp_DatasetStartTimes (ID, ItemType, Datasets);

        -- Also create an index that supports StartTime lookup by dataset and type
        CREATE UNIQUE INDEX IX_Tmp_DatasetStartTimes_InstID_StartTime On Tmp_DatasetStartTimes (DMS_Inst_ID, ItemType, StartTime);

        ---------------------------------------------------
        -- Temporary table to hold rows to update when previewing updates
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_UpdatesToApply (
            ID Int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            DMS_Inst_ID int Not Null,
            ItemType text Not Null,         -- 'Dataset' or 'Interval'
            Start timestamp Not Null,
            Dataset_ID int Not Null,
            Seq Int Not Null,
            Dataset text Null,
            Dataset_ID_Acq_Overlap int Null
        )

        If _year <= 0 Then
            INSERT INTO Tmp_DatasetStartTimes( DMS_Inst_ID,
                                               ItemType,
                                               StartTime,
                                               Datasets )
            SELECT dms_inst_id,
                   type,
                   start,
                   COUNT(*)
            FROM t_emsl_instrument_usage_report
            WHERE dms_inst_id = _dmsInstrumentID
            GROUP BY dms_inst_id, type, start
            ORDER BY dms_inst_id, type, start
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _infoOnly Then
                RAISE INFO 'Processing % start times for instrument % in t_emsl_instrument_usage_report (no date filter)',
                            _myRowCount, _instrument;
            End If;
        Else
            If _month <= 0 Then
                _startDate := make_date(_year, 1, 1);
                _endDate   := _startDate + INTERVAL '1 year';
            Else
                _startDate := make_date(_year, _month, 1);
                _endDate := _startDate + INTERVAL '1 month';
            End If;

            INSERT INTO Tmp_DatasetStartTimes( DMS_Inst_ID,
                                               ItemType,
                                               StartTime,
                                               Datasets )
            SELECT dms_inst_id,
                   type,
                   start,
                   COUNT(*)
            FROM t_emsl_instrument_usage_report
            WHERE start >= _startDate AND
                  start < _endDate AND
                  dms_inst_id = _dmsInstrumentID
            GROUP BY dms_inst_id, type, start
            ORDER BY dms_inst_id, type, start
            --
            GET DIAGNOSTICS _myRowCount = ROW_COUNT;

            If _infoOnly Then
                RAISE INFO 'Processing % start times for instrument % in t_emsl_instrument_usage_report',
                            _myRowCount, _instrument;

                RAISE INFO 'Filtering for start between % and %',
                            to_char(_startDate, 'yyyy-mm-dd'),
                            to_char(_endDate, 'yyyy-mm-dd');
            End If;
        End If;

        If Not _infoOnly Then
            -- Set Dataset_ID_Acq_Overlap to Null for any entries where it is currently not null,
            -- yet there is only one dataset (or interval) for the given start time
            --
            UPDATE t_emsl_instrument_usage_report InstUsage
            SET dataset_id_acq_overlap = NULL
            FROM ( SELECT DMS_Inst_ID,
                          ItemType,
                          StartTime
                   FROM Tmp_DatasetStartTimes
                   WHERE Datasets = 1 ) FilterQ
            WHERE InstUsage.DMS_Inst_ID = FilterQ.DMS_Inst_ID AND
                  InstUsage.TYPE = FilterQ.ItemType AND
                  InstUsage.Start = FilterQ.StartTime AND
                  NOT Dataset_ID_Acq_Overlap IS NULL;

        End If;

        If _infoOnly And _showStartTimes Then

            -- ToDo: Show the data using RAISE INFO

            Select *
            From Tmp_DatasetStartTimes
        End If;

        FOR _startTimeInfo IN
            SELECT DMS_Inst_ID AS DmsInstrumentID,
                   ItemType,
                   StartTime
            FROM Tmp_DatasetStartTimes
            WHERE Datasets > 1
            ORDER BY ID
        LOOP

            -- Find the best dataset ID to represent the group of datasets (or group of intervals) that start at _startTimeInfo.StartTime
            -- Choose the dataset (or interval) with the longest runtime
            --   If ties, sort by dataset name

            -- If a dataset was deleted from DMS then re-uploaded under a new name,
            -- table t_emsl_instrument_usage_report may have two rows for the dataset
            -- Since this query uses an inner join, it will grab the dataset_id of the existing dataset

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
                --
                UPDATE t_emsl_instrument_usage_report
                SET dataset_id_acq_overlap = CASE WHEN dataset_id = _datasetID AND seq = _lastSeq
                                                  THEN NULL
                                                  ELSE _datasetID
                                             END
                WHERE DMS_Inst_ID = _startTimeInfo.DmsInstrumentID AND
                      Start = _startTimeInfo.StartTime AND
                      Type = _startTimeInfo.ItemType
            Else
                INSERT INTO Tmp_UpdatesToApply( DMS_Inst_ID,
                                                ItemType,
                                                Start,
                                                Dataset_ID,
                                                Seq,
                                                Dataset,
                                                Dataset_ID_Acq_Overlap )
                SELECT InstUsage.DMS_Inst_ID,
                       InstUsage.Type,
                       InstUsage.Start,
                       InstUsage.Dataset_ID,
                       InstUsage.Seq,
                       DS.Dataset_Name,
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
                ORDER BY CASE WHEN InstUsage.dataset_id = _datasetID And seq = _lastSeq THEN 1
                              WHEN InstUsage.dataset_id = _datasetID THEN 2
                              ELSE 3
                         END,
                         DS.Dataset_Name
            End If;

        END LOOP;

        If _infoOnly Then

            If _showPendingUpdates Then

                -- ToDo: Show data using RAISE INFO

                SELECT U.*
                FROM Tmp_UpdatesToApply U
                ORDER BY ID
            End If;

            -- ToDo: Show data using RAISE INFO

            SELECT U.ID,
                   U.dms_inst_id,
                   U.ItemType,
                   U.start,
                   InstUsage.minutes,
                   U.dataset_id,
                   U.seq,
                   U.Dataset,
                   U.dataset_id_acq_overlap
            FROM Tmp_UpdatesToApply U
                 INNER JOIN t_emsl_instrument_usage_report InstUsage
                   ON U.dataset_id = InstUsage.dataset_id AND
                      U.start = InstUsage.start AND
                      U.ItemType = InstUsage.type AND
                      U.seq = InstUsage.seq
            ORDER BY ID
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

    DROP TABLE IF EXISTS Tmp_DatasetStartTimes;
    DROP TABLE IF EXISTS Tmp_UpdatesToApply;
END
$$;

COMMENT ON PROCEDURE public.update_emsl_instrument_acq_overlap_data IS 'UpdateEMSLInstrumentAcqOverlapData';
