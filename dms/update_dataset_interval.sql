--
-- Name: update_dataset_interval(text, timestamp without time zone, timestamp without time zone, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_dataset_interval(IN _instrumentname text, IN _startdate timestamp without time zone, IN _enddate timestamp without time zone, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update dataset intervals in public.t_dataset and creates entries for long intervals in public.t_run_interval
**
**  Arguments:
**    _instrumentName       Instrument name
**    _startDate            Start date
**    _endDate              End date
**    _infoOnly             When true, preview updates
**    _message              Status message
**    _returnCode           Return code
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
**          08/28/2023 mem - Ported to PostgreSQL
**          08/31/2023 mem - Exit the procedure if no datasets are found between the start and end dates
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _insertCount int;
    _maxNormalInterval int;
    _instrumentNameMatch text := '';
    _eusInstrumentId int := 0;
    _maxSeq int;
    _start timestamp;
    _end timestamp;
    _interval int;
    _index int;

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

        _instrumentNameMatch := Trim(Coalesce(_instrumentNameMatch, ''));
        _infoOnly            := Coalesce(_infoOnly, false);

        -- Lookup the long interval threshold (which should be 180 minutes)
        _maxNormalInterval := public.get_long_interval_threshold();

        ---------------------------------------------------
        -- Make sure _instrumentName is valid (and is properly capitalized)
        ---------------------------------------------------

        SELECT instrument
        INTO _instrumentNameMatch
        FROM t_instrument_name
        WHERE instrument = _instrumentName::citext;

        If Not FOUND Then
            _message := format('Unknown instrument: %s', _instrumentName);

            If _infoOnly Then
                RAISE INFO '';
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
        );

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
                          HAVING COUNT(InstName.instrument_id) > 1
                        ) LookupQ
               ON InstMapping.eus_instrument_id = LookupQ.eus_instrument_id
        WHERE InstName.instrument = _instrumentName::citext;

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
                   Extract(epoch from DS.acq_time_end - DS.acq_time_start) / 60   -- Length, in minutes
            FROM t_dataset DS
                 INNER JOIN t_instrument_name InstName
                   ON DS.instrument_id = InstName.instrument_id
                 INNER JOIN t_emsl_dms_instrument_mapping InstMapping
                   ON InstName.instrument_id = InstMapping.dms_instrument_id
            WHERE DS.acq_time_start BETWEEN _startDate AND _endDate AND
                  InstMapping.eus_instrument_id = _eusInstrumentId
            ORDER BY DS.acq_time_start;
            --
            GET DIAGNOSTICS _insertCount = ROW_COUNT;

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
                   Extract(epoch from DS.acq_time_end - DS.acq_time_start) / 60  -- Length, in minutes
            FROM t_dataset DS
                 INNER JOIN t_instrument_name InstName
                   ON DS.instrument_id = InstName.instrument_id
            WHERE DS.acq_time_start BETWEEN _startDate AND _endDate AND
                  InstName.instrument = _instrumentName::citext
            ORDER BY DS.Acq_Time_Start;
            --
            GET DIAGNOSTICS _insertCount = ROW_COUNT;

        End If;

        If _insertCount = 0 Then
            RAISE INFO 'No datasets were found for instrument % between % and %',
                        _instrumentName, _startDate::date, _endDate::date;

            DROP TABLE Tmp_Durations;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Calculate inter-run intervals and update temp table
        ---------------------------------------------------

        SELECT MAX(Seq)
        INTO _maxSeq
        FROM Tmp_Durations;

        If _infoOnly Then
            RAISE INFO 'Calculating inter-run intervals for instrument %: % %', _instrumentName, _insertCount, public.check_plural(_insertCount, 'dataset', 'datasets');
        End If;

        FOR _index IN 1 .. Coalesce(_maxSeq, 0)
        LOOP
            SELECT Time_Start
            INTO _start
            FROM Tmp_Durations
            WHERE Seq = _index + 1;

            If Not FOUND Then
                CONTINUE;
            End If;

            SELECT Time_End
            INTO _end
            FROM Tmp_Durations
            WHERE Seq = _index;

            If Not FOUND Then
                CONTINUE;
            End If;

            -- Compute the interval from the end time of the first dataset to the start time of the next dataset
            -- Thus, use "epoch from _start - _end" since _start is after _end

            _interval := CASE WHEN _start <= _end THEN 0
                              ELSE Coalesce(Extract(epoch from _start - _end) / 60, 0)  -- Length, in minutes
                         END;

            -- Update the durations table, provided start and end times are not null

            If Not _start Is Null And Not _end Is Null Then
                UPDATE Tmp_Durations
                SET Interval = Coalesce(_interval, 0)
                WHERE Seq = _index;
            End If;

        END LOOP;

        If _infoOnly Then

            ---------------------------------------------------
            -- Preview the dataset intervals
            ---------------------------------------------------

            RAISE INFO '';

            _formatSpecifier := '%-25s %-80s %-10s %-20s %-20s %-19s %-13s %-35s';

            _infoHead := format(_formatSpecifier,
                                'Instrument',
                                'Dataset',
                                'Dataset_ID',
                                'Created',
                                'Acq_Time_Start',
                                'Interval_to_Next_DS',
                                'Long_Interval',
                                'Comment'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '-------------------------',
                                         '--------------------------------------------------------------------------------',
                                         '----------',
                                         '--------------------',
                                         '--------------------',
                                         '-------------------',
                                         '-------------',
                                         '-----------------------------------'
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
                       DS.interval_to_next_ds AS Current_Interval_to_Next_DS,
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
                         END,
                         DS.Dataset_ID
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Instrument,
                                    _previewData.Dataset,
                                    _previewData.Dataset_ID,
                                    _previewData.Created,
                                    _previewData.Acq_Time_Start,
                                    _previewData.Interval_to_Next_DS,
                                    _previewData.Long_Interval,
                                    CASE WHEN Not _previewData.Interval_to_Next_DS IS NULL AND
                                              _previewData.Current_Interval_to_Next_DS Is NULL THEN 'Storing new interval'
                                         WHEN Not _previewData.Interval_to_Next_DS IS DISTINCT FROM _previewData.Current_Interval_to_Next_DS THEN ''   -- Matches existing interval
                                         ELSE
                                             CASE WHEN Not _previewData.Interval_to_Next_DS IS NULL AND
                                                       _previewData.Current_Interval_to_Next_DS IS DISTINCT FROM _previewData.Interval_to_Next_DS
                                                  THEN format('Updating interval: %s -> %s',
                                                                _previewData.Current_Interval_to_Next_DS,
                                                                _previewData.Interval_to_Next_DS)
                                                  ELSE format('New interval is null; leaving existing interval unchanged: %s',
                                                                CASE WHEN _previewData.Current_Interval_to_Next_DS IS NULL
                                                                     THEN '<Null>'
                                                                     ELSE _previewData.Current_Interval_to_Next_DS::text
                                                                END)
                                             END
                                    END
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            DROP TABLE Tmp_Durations;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Update intervals in dataset table
        ---------------------------------------------------

        UPDATE t_dataset target
        SET interval_to_next_ds = Tmp_Durations.Interval
        FROM Tmp_Durations
        WHERE target.dataset_id = Tmp_Durations.dataset_id AND
              NOT Tmp_Durations.Interval IS NULL AND
              target.interval_to_next_ds IS DISTINCT FROM Tmp_Durations.Interval;

        ---------------------------------------------------
        -- Update intervals in long interval table
        ---------------------------------------------------

        UPDATE t_run_interval target
        SET Interval = Tmp_Durations.Interval
        FROM Tmp_Durations
        WHERE target.dataset_id = Tmp_Durations.Dataset_ID AND
              Coalesce(target.Interval, 0) <> Coalesce(Tmp_Durations.Interval, target.Interval, 0);

        ---------------------------------------------------
        -- Make entries in interval tracking table for long intervals
        ---------------------------------------------------

        INSERT INTO t_run_interval (
            dataset_id,
            instrument,
            start,
            interval
        )
        SELECT Tmp_Durations.dataset_id,
               InstName.instrument,
               Tmp_Durations.Time_End,
               Tmp_Durations.Interval
        FROM t_dataset DS
             INNER JOIN Tmp_Durations
               ON DS.dataset_id = Tmp_Durations.dataset_id
             INNER JOIN t_instrument_name InstName
               ON DS.instrument_id = InstName.instrument_id
        WHERE NOT Tmp_Durations.dataset_id IN ( SELECT dataset_id FROM t_run_interval ) AND
              Tmp_Durations.Interval > _maxNormalInterval;

        ---------------------------------------------------
        -- Delete 'short' long intervals
        -- (intervals that are less than threshold)
        ---------------------------------------------------

        DELETE FROM t_run_interval
        WHERE interval < _maxNormalInterval;

        DROP TABLE Tmp_Durations;
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

    If _infoOnly And _returnCode <> '' Then
        RAISE INFO '%', _message;
    End If;

    DROP TABLE IF EXISTS Tmp_Durations;
END
$$;


ALTER PROCEDURE public.update_dataset_interval(IN _instrumentname text, IN _startdate timestamp without time zone, IN _enddate timestamp without time zone, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_dataset_interval(IN _instrumentname text, IN _startdate timestamp without time zone, IN _enddate timestamp without time zone, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_dataset_interval(IN _instrumentname text, IN _startdate timestamp without time zone, IN _enddate timestamp without time zone, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateDatasetInterval';

