--
CREATE OR REPLACE PROCEDURE public.update_dataset_interval
(
    _instrumentName text,
    _startDate timestamp,
    _endDate timestamp,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates dataset interval and creates entries
**      for long intervals in the intervals table
**
**  Auth:   grk
**  Date:   02/08/2012
**          02/10/2012 mem - Now updating Acq_Length_Minutes in T_Dataset
**          02/13/2012 grk - Raised _maxNormalInterval to ninety minutes
**          02/15/2012 mem - No longer updating Acq_Length_Minutes in T_Dataset since now a computed column
**          03/07/2012 mem - Added parameter _infoOnly
**                         - Now validating _instrumentName
**          03/29/2012 grk - Interval values in T_Run_Interval were not being updated
**          04/10/2012 grk - Now deleting 'short' long intervals
**          06/08/2012 grk - Added lookup for _maxNormalInterval
**          08/30/2012 grk - Extended dataset update to include beginning of next month
**          11/19/2013 mem - Now updating Interval_to_Next_DS in T_Dataset only if the newly computed interval differs from the stored interval
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/03/2019 mem - Use EUS_Instrument_ID for DMS instruments that share a single eusInstrumentId
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _maxNormalInterval int;
    _instrumentNameMatch text := '';
    _eusInstrumentId int := 0;
    _maxSeq Int;
    _start timestamp, _end timestamp, _interval int;
    _index int := 1;
    _seqIncrement int := 1;

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
    _message := '';
    _returnCode := '';

    _infoOnly := Coalesce(_infoOnly, false);

    _maxNormalInterval := get_long_interval_threshold();

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
        -- Make sure _instrumentName is valid (and is properly capitalized)
        ---------------------------------------------------

        SELECT instrument
        INTO _instrumentNameMatch
        FROM t_instrument_name
        WHERE instrument = _instrumentName

        If Coalesce(_instrumentNameMatch, '') = '' Then
            _message := format('Unknown instrument: %s', _instrumentName);
            If _infoOnly Then
                RAISE INFO '%', _message;
            End If;

            RETURN;
        Else
            _instrumentName := _instrumentNameMatch;
        End If;

        ---------------------------------------------------
        -- Temp table to hold time information about datasets
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_Durations (
            Seq int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            Dataset_ID int,
            Dataset text,
            Instrument text,
            Time_Start timestamp,
            Time_End timestamp,
            Duration int,                -- Duration of run, in minutes
            Interval int NULL
        )

        ---------------------------------------------------
        -- Auto switch to _eusInstrumentId if needed
        ---------------------------------------------------

        SELECT InstMapping.eus_instrument_id
        INTO _eusInstrumentId
        FROM t_instrument_name InstName
             INNER JOIN t_emsl_dms_instrument_mapping InstMapping
               ON InstName.instrument_id = InstMapping.dms_instrument_id
             INNER JOIN ( SELECT InstMapping.eus_instrument_id
                          FROM t_instrument_name InstName
                               INNER JOIN t_emsl_dms_instrument_mapping InstMapping
                                 ON InstName.instrument_id = InstMapping.dms_instrument_id
                          GROUP BY InstMapping.eus_instrument_id
                          HAVING COUNT(InstName.instrument_id) > 1 ) LookupQ
               ON InstMapping.eus_instrument_id = LookupQ.eus_instrument_id
        WHERE InstName.instrument = _instrumentName;

        If _eusInstrumentId > 0 Then
            INSERT INTO Tmp_Durations (
                dataset_id,
                dataset,
                instrument,
                Time_Start,
                Time_End,
                Duration
            )
            SELECT DS.dataset_id,
                   DS.dataset,
                   InstName.instrument,
                   DS.acq_time_start,
                   DS.acq_time_end,
                   extract(epoch FROM DS.acq_time_end - DS.acq_time_start) / 60.0
            FROM t_dataset DS
                 INNER JOIN t_instrument_name InstName
                   ON DS.instrument_id = InstName.instrument_id
                 INNER JOIN t_emsl_dms_instrument_mapping InstMapping
                   ON InstName.instrument_id = InstMapping.dms_instrument_id
            WHERE _startDate <= DS.acq_time_start AND
                  DS.acq_time_start <= _endDate AND
                  InstMapping.eus_instrument_id = _eusInstrumentId
            ORDER BY DS.acq_time_start;

        Else
            INSERT INTO Tmp_Durations (
                dataset_id,
                dataset,
                instrument,
                Time_Start,
                Time_End,
                Duration
            )
            SELECT DS.dataset_id,
                   DS.dataset,
                   InstName.instrument,
                   DS.acq_time_start,
                   DS.acq_time_end,
                   extract(epoch FROM DS.acq_time_end - DS.acq_time_start) / 60.0
            FROM t_dataset DS
                 INNER JOIN t_instrument_name InstName
                   ON DS.instrument_id = InstName.instrument_id
            WHERE _startDate <= DS.acq_time_start AND
                  DS.acq_time_start <= _endDate AND
                  InstName.instrument = _instrumentName
            ORDER BY DS.Acq_Time_Start;
        End If;

        ---------------------------------------------------
        -- Calculate inter-run intervals and update temp table
        ---------------------------------------------------

        SELECT MAX(Seq)
        INTO _maxSeq
        FROM Tmp_Durations;

        WHILE _index < _maxSeq
        LOOP
            _start := NULL;
            _end := NULL;

            SELECT Time_Start
            INTO _start
            FROM Tmp_Durations
            WHERE Seq = _index + _seqIncrement

            SELECT Time_End
            INTO _end
            FROM Tmp_Durations
            WHERE Seq = _index

            _interval := CASE WHEN _start <= _end THEN 0
                              ELSE Coalesce(extract(epoch FROM _start - _end) / 60.0, 0)
                         END;

            -- Make sure that start and end times are not null
            --
            If (NOT _start IS NULL) AND (NOT _end IS NULL) Then
                UPDATE Tmp_Durations
                SET Interval = Coalesce(_interval, 0)
                WHERE Seq = _index
            End If;

            _index := _index + _seqIncrement;
        END LOOP;

        If _infoOnly Then

            ---------------------------------------------------
            -- Preview dataset intervals
            ---------------------------------------------------

            RAISE INFO '';

            _formatSpecifier := '%-25s %-80s %-10s %-20s %-20s %-19s %-13s';

            _infoHead := format(_formatSpecifier,
                                'Instrument',
                                'Dataset',
                                'Dataset_ID',
                                'Created',
                                'Acq_Time_Start',
                                'Interval_to_Next_DS',
                                'Long_Interval'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '-------------------------',
                                         '--------------------------------------------------------------------------------',
                                         '----------',
                                         '--------------------',
                                         '--------------------',
                                         '-------------------',
                                         '-------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT InstName.Instrument,
                       DS.Dataset,
                       DS.Dataset_ID,
                       public.timestamp_text(DS.Created) AS Created,
                       public.timestamp_text(DS.Acq_Time_Start) AS Acq_Time_Start,
                       Tmp_Durations.Interval AS Interval_to_Next_DS,
                       CASE
                           WHEN Interval > _maxNormalInterval THEN 'Yes'
                           ELSE ''
                       END AS Long_Interval
                FROM t_dataset DS
                     INNER JOIN Tmp_Durations
                       ON DS.dataset_id = Tmp_Durations.dataset_id
                     INNER JOIN t_instrument_name InstName
                       ON DS.instrument_id = InstName.instrument_id
                ORDER BY CASE
                             WHEN Interval > _maxNormalInterval THEN 'Yes'
                             ELSE ''
                         END, DS.Dataset_ID
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Instrument,
                                    _previewData.Dataset,
                                    _previewData.Dataset_ID,
                                    _previewData.Created,
                                    _previewData.Acq_Time_Start,
                                    _previewData.Interval_to_Next_DS,
                                    _previewData.Long_Interval
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            DROP TABLE Tmp_Durations;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Update intervals in dataset table
        ---------------------------------------------------

        UPDATE DS
        SET interval_to_next_ds = Tmp_Durations.Interval
        FROM t_dataset DS
             INNER JOIN Tmp_Durations
               ON DS.dataset_id = Tmp_Durations.dataset_id
        WHERE Coalesce(DS.interval_to_next_ds, 0) <> Coalesce(Tmp_Durations.Interval, DS.interval_to_next_ds, 0)

        ---------------------------------------------------
        -- Update intervals in long interval table
        ---------------------------------------------------

        UPDATE t_run_interval
        SET Interval = Tmp_Durations.Interval
        FROM Tmp_Durations
        WHERE t_run_interval.ID = Tmp_Durations.Dataset_ID AND
              Coalesce(target.Interval, 0) <> Coalesce(Tmp_Durations.Interval, target.Interval, 0);

        ---------------------------------------------------
        -- Make entries in interval tracking table
        -- for long intervals
        ---------------------------------------------------

        INSERT INTO t_run_interval( interval_id,
                                    instrument,
                                    start,
                                    Interval )
        SELECT Tmp_Durations.dataset_id,
               InstName.instrument,
               Tmp_Durations.Time_End,
               Tmp_Durations.Interval
        FROM t_dataset DS
             INNER JOIN Tmp_Durations
               ON DS.dataset_id = Tmp_Durations.dataset_id
             INNER JOIN t_instrument_name InstName
               ON DS.instrument_id = InstName.instrument_id
        WHERE NOT Tmp_Durations.dataset_id IN ( SELECT interval_id FROM t_run_interval ) AND
              Tmp_Durations.Interval > _maxNormalInterval;

        ---------------------------------------------------
        -- Delete 'short' long intervals
        -- (intervals that are less than threshold)
        ---------------------------------------------------

        DELETE FROM t_run_interval
        WHERE interval < _maxNormalInterval;

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

    If _infoOnly And _returnCode <> '' Then
        RAISE INFO '%', _message;
    End If;

    DROP TABLE IF EXISTS Tmp_Durations;
END
$$;

COMMENT ON PROCEDURE public.update_dataset_interval IS 'UpdateDatasetInterval';
