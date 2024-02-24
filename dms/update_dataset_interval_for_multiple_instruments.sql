--
-- Name: update_dataset_interval_for_multiple_instruments(integer, boolean, boolean, boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_dataset_interval_for_multiple_instruments(IN _daystoprocess integer DEFAULT 60, IN _updateemslinstrumentusage boolean DEFAULT true, IN _infoonly boolean DEFAULT false, IN _previewprocedurecall boolean DEFAULT false, IN _instrumentstoprocess text DEFAULT ''::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update dataset intervals in public.t_dataset and creates entries for long intervals in public.t_run_interval
**      for all production instruments
**
**  Arguments:
**    _daysToProcess                Updates datasets acquired between the current timestamp and this many days in the past
**    _updateEMSLInstrumentUsage    When true, call update_emsl_instrument_usage_report() to update T_EMSL_Instrument_Usage_Report
**                                  Called for each month between the computed start date and the current month
**    _infoOnly                     When true, preview updates
**    _previewProcedureCall         When true, preview calls to update_dataset_interval() and update_emsl_instrument_usage_report() when _infoOnly is true
**    _instrumentsToProcess         Optional comma-separated list of instruments to process
**    _message                      Status message
**    _returnCode                   Return code
**
**  Auth:   grk
**  Date:   02/09/2012 grk - Initial version
**          03/07/2012 mem - Added parameters _daysToProcess, _infoOnly, and _message
**          03/21/2012 grk - Added call to Update_EMSL_Instrument_Usage_Report
**          03/22/2012 mem - Added parameter _updateEMSLInstrumentUsage
**          03/26/2012 grk - Added call to Update_EMSL_Instrument_Usage_Report for previous month
**          03/27/2012 grk - Added code to delete entries from T_EMSL_Instrument_Usage_Report
**          03/27/2012 grk - Using V_Instrument_Tracked
**          04/09/2012 grk - Modified algorithm
**          08/02/2012 mem - Updated _daysToProcess to default to 60 days instead of 30 days
**          09/18/2012 grk - Only do EMSL instrument updates for EMSL instruments
**          10/06/2012 grk - Removed update of EMSL usage report for previous month
**          03/12/2014 grk - Added processing for 'tracked' instruments (OMCDA-1058)
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/10/2017 mem - Add parameter _instrumentsToProcess
**          04/11/2017 mem - Now passing _infoOnly to Update_EMSL_Instrument_Usage_Report
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/03/2019 mem - Pass _eusInstrumentId to Update_EMSL_Instrument_Usage_Report for select instruments
**          01/28/2022 mem - Call Update_EMSL_Instrument_Usage_Report for both the current month, plus also previous months if _daysToProcess is greater than 15
**          02/15/2022 mem - Fix major bug decrementing _instrumentUsageMonth when processing multiple instruments
**                         - Add missing Order By clause
**          07/21/2023 mem - Look for both 'Y' and '1' when examining the eus_primary_instrument flag (aka EMSL_Primary_Instrument)
**          08/29/2023 mem - Ported to PostgreSQL
**          08/31/2023 mem - Remove invalid where clause in For Loop query
**                         - Change "months to update" variable to an integer
**          09/07/2023 mem - Align assignment statements
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          10/02/2023 mem - Do not include comma delimiter when calling parse_delimited_list for a comma-separated list
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _endDate timestamp;
    _instrumentUsageMonth timestamp;
    _currentInstrumentUsageMonth timestamp;
    _instrumentUsageMonthsToUpdate int;
    _startDate timestamp;
    _currentYear int;
    _currentMonth int;
    _day int;
    _hour int;
    _prevDate timestamp;
    _prevMonth int;
    _prevYear int;
    _nextMonth int;
    _nextYear int;
    _startOfNextMonth timestamp;
    _instrumentInfo record;
    _skipInstrument boolean := false;
    _iteration int := 0;

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

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _daysToProcess := Coalesce(_daysToProcess, 60);

    If _daysToProcess < 10 Then
        _daysToProcess := 10;
    End If;

    _updateEMSLInstrumentUsage := Coalesce(_updateEMSLInstrumentUsage, true);
    _infoOnly                  := Coalesce(_infoOnly, false);
    _previewProcedureCall      := Coalesce(_previewProcedureCall, false);
    _instrumentsToProcess      := Trim(Coalesce(_instrumentsToProcess, ''));

    ---------------------------------------------------
    -- Set up date interval and key values
    ---------------------------------------------------

    _instrumentUsageMonth := CURRENT_TIMESTAMP;

    _endDate := CURRENT_TIMESTAMP;
    _instrumentUsageMonth := CURRENT_TIMESTAMP;

    -- Update instrument usage for the current month, plus possibly the last few months, depending on _daysToProcess
    -- For example, if _daysToProcess is 60, will call Update_EMSL_Instrument_Usage_Report for this month plus the last two months
    _instrumentUsageMonthsToUpdate := (1 + Round(_daysToProcess / 31.0, 0))::int;

    _startDate        := _endDate - make_interval(days => _daysToProcess);
    _currentYear      := Extract(year  from _endDate);
    _currentMonth     := Extract(month from _endDate);
    _day              := Extract(day   from _endDate);
    _hour             := Extract(hour  from _endDate);

    _prevDate         := _endDate - INTERVAL '1 month';
    _prevMonth        := Extract(month from _prevDate);
    _prevYear         := Extract(year  from _prevDate);

    _nextMonth        := Extract(month from _endDate + INTERVAL '1 month');
    _nextYear         := Extract(year  from _endDate + INTERVAL '1 month');

    _startOfNextMonth := make_date(_nextYear, _nextMonth, 1);

    ---------------------------------------------------
    -- Temp table to hold list of production instruments
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Instruments (
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Instrument citext,
        EMSL_Primary_Instrument citext,          -- This comes from eus_primary_instrument in table t_emsl_instruments and will be '0', '1', 'N', or 'Y'
        Tracked int,
        EUS_Instrument_ID int NULL,
        Use_EUS_ID boolean NOT NULL
    );

    CREATE TEMP TABLE Tmp_InstrumentFilter (
        Instrument text
    );

    CREATE TEMP TABLE Tmp_EUS_IDs_Processed (
        EUS_Instrument_ID int NOT NULL
    );

    ---------------------------------------------------
    -- Process updates for all instruments, one at a time
    -- Filter on _instrumentsToProcess if not-blank
    ---------------------------------------------------

    BEGIN

        If _instrumentsToProcess <> '' Then

            ---------------------------------------------------
            -- Get filtered list of tracked instruments
            ---------------------------------------------------

            -- Populate Tmp_InstrumentFilter using _instrumentsToProcess

            INSERT INTO Tmp_InstrumentFilter( Instrument )
            SELECT Value
            FROM public.parse_delimited_list(_instrumentsToProcess);

            INSERT INTO Tmp_Instruments( Instrument,
                                         EMSL_Primary_Instrument,
                                         Tracked,
                                         EUS_Instrument_ID,
                                         Use_EUS_ID )
            SELECT InstList.Name,
                   InstList.EUS_Primary_Instrument AS EMSL_Primary_Instrument,
                   InstList.Tracked,
                   InstList.EUS_Instrument_ID,
                   false
            FROM V_Instrument_Tracked InstList
                 INNER JOIN Tmp_InstrumentFilter InstFilter
                   ON InstList.Name = InstFilter.Instrument
            ORDER BY Coalesce(InstList.EUS_Instrument_ID, 0), InstList.Name;

        Else

            ---------------------------------------------------
            -- Get list of tracked instruments
            ---------------------------------------------------

            INSERT INTO Tmp_Instruments( Instrument,
                                         EMSL_Primary_Instrument,
                                         Tracked,
                                         EUS_Instrument_ID,
                                         Use_EUS_ID )
            SELECT Name,
                   EUS_Primary_Instrument AS EMSL_Primary_Instrument,
                   Tracked,
                   EUS_Instrument_ID,
                   false
            FROM V_Instrument_Tracked
            ORDER BY Coalesce(EUS_Instrument_ID, 0), Name;

        End If;

        ---------------------------------------------------
        -- Flag instruments where we need to use EUS instrument ID
        -- instead of instrument name when calling Update_EMSL_Instrument_Usage_Report
        ---------------------------------------------------

        UPDATE Tmp_Instruments
        SET Use_EUS_ID = true
        FROM ( SELECT InstName.instrument,
                      InstMapping.eus_instrument_id
               FROM t_instrument_name InstName
                    INNER JOIN t_emsl_dms_instrument_mapping InstMapping
                      ON InstName.instrument_id = InstMapping.dms_instrument_id
                    INNER JOIN ( SELECT InstMapping.eus_instrument_id
                                 FROM t_instrument_name InstName
                                      INNER JOIN t_emsl_dms_instrument_mapping InstMapping
                                        ON InstName.instrument_id = InstMapping.dms_instrument_id
                                 WHERE NOT InstMapping.eus_instrument_id IS NULL
                                 GROUP BY InstMapping.eus_instrument_id
                                 HAVING COUNT(InstName.instrument_id) > 1
                               ) LookupQ
                        ON InstMapping.eus_instrument_id = LookupQ.eus_instrument_id
              ) FilterQ
        WHERE Tmp_Instruments.eus_instrument_id = FilterQ.eus_instrument_id;

        If _infoOnly Then

            RAISE INFO '';

            _formatSpecifier := '%-8s %-25s %-23s %-7s %-17s %-10s';

            _infoHead := format(_formatSpecifier,
                                'Entry_ID',
                                'Instrument',
                                'EMSL_Primary_Instrument',
                                'Tracked',
                                'EUS_Instrument_ID',
                                'Use_EUS_ID'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '--------',
                                         '-------------------------',
                                         '-----------------------',
                                         '-------',
                                         '-----------------',
                                         '----------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Entry_ID,
                       Instrument,
                       EMSL_Primary_Instrument,
                       Tracked,
                       EUS_Instrument_ID,
                       Use_EUS_ID
                FROM Tmp_Instruments
                ORDER BY Instrument
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Entry_ID,
                                    _previewData.Instrument,
                                    _previewData.EMSL_Primary_Instrument,
                                    _previewData.Tracked,
                                    _previewData.EUS_Instrument_ID,
                                    _previewData.Use_EUS_ID);

                RAISE INFO '%', _infoData;
            END LOOP;

            RAISE INFO '';
        End If;

        ---------------------------------------------------
        -- Update intervals for each instrument
        ---------------------------------------------------

        FOR _instrumentInfo IN
            SELECT Instrument,
                   EMSL_Primary_Instrument,
                   Tracked,
                   Use_EUS_ID,
                   EUS_Instrument_ID AS EusInstrumentId,
                   Entry_ID AS EntryID
            FROM Tmp_Instruments
            ORDER BY Entry_ID
        LOOP
            _skipInstrument := false;

            If _instrumentInfo.Use_EUS_ID Then
                If Exists (SELECT EUS_Instrument_ID FROM Tmp_EUS_IDs_Processed WHERE EUS_Instrument_ID = _instrumentInfo.EusInstrumentId) Then
                    _skipInstrument := true;
                Else
                    INSERT INTO Tmp_EUS_IDs_Processed (EUS_Instrument_ID)
                    VALUES (_instrumentInfo.EusInstrumentId);
                End If;
            End If;

            If _skipInstrument Then
                CONTINUE;
            End If;

            If _infoOnly And _previewProcedureCall Then
                RAISE INFO 'Call update_dataset_interval %, %, %, _infoOnly => _infoOnly)', _instrumentInfo.Instrument, _startDate, _startOfNextMonth;
            Else
                CALL public.update_dataset_interval (
                        _instrumentName => _instrumentInfo.Instrument,
                        _startDate      => _startDate,
                        _endDate        => _startOfNextMonth,
                        _infoOnly       => _infoOnly,
                        _message        => _message,        -- Output
                        _returnCode     => _returnCode);    -- Output
            End If;

            -- EMSL_Primary_Instrument comes from eus_primary_instrument in table t_emsl_instruments and will be '0', '1', 'N', or 'Y'

            If Not _updateEMSLInstrumentUsage Then
                If _infoOnly And (_instrumentInfo.EMSL_Primary_Instrument In ('Y', '1') Or _instrumentInfo.Tracked = 1) Then
                    RAISE INFO '';
                    RAISE INFO 'Skip call to Update_EMSL_Instrument_Usage_Report for Instrument %', _instrumentInfo.Instrument;
                    RAISE INFO '';
                End If;

                CONTINUE;
            End If;

            -- Call Update_EMSL_Instrument_Usage_Report for this month, plus optionally previous months (if _instrumentUsageMonthsToUpdate is greater than 1)

            _currentInstrumentUsageMonth := _instrumentUsageMonth;

            FOR _iteration IN 1 .. _instrumentUsageMonthsToUpdate
            LOOP
                If _infoOnly Then
                    RAISE INFO 'Call Update_EMSL_Instrument_Usage_Report for Instrument %, target month %-%',
                                _instrumentInfo.Instrument,
                                Extract(year  from _currentInstrumentUsageMonth),
                                Extract(month from _currentInstrumentUsageMonth);

                End If;

                If Not _infoOnly Or _infoOnly And _previewProcedureCall Then
                    If _instrumentInfo.Use_EUS_ID Then
                        CALL public.update_emsl_instrument_usage_report (
                                        _instrument      => '',
                                        _eusInstrumentId => _instrumentInfo.EusInstrumentId,
                                        _endDate         => _currentInstrumentUsageMonth,
                                        _infoOnly        => _infoOnly,
                                        _debugReports    => '',
                                        _message         => _message,       -- Output
                                        _returnCode      => _returnCode);   -- Output
                    Else
                        CALL public.update_emsl_instrument_usage_report (
                                        _instrument      => _instrumentInfo.Instrument,
                                        _eusInstrumentId => 0,
                                        _endDate         => _currentInstrumentUsageMonth,
                                        _infoOnly        => _infoOnly,
                                        _debugReports    => '',
                                        _message         => _message,       -- Output
                                        _returnCode      => _returnCode);   -- Output
                    End If;

                    If _returnCode <> '' And Not _infoOnly Then
                        RAISE EXCEPTION '%', _msg;
                    End If;

                End If;

                If _infoOnly Then
                    RAISE INFO '';
                End If;

                _currentInstrumentUsageMonth := _currentInstrumentUsageMonth - INTERVAL '1 month';
            END LOOP;

        END LOOP;

        DROP TABLE Tmp_Instruments;
        DROP TABLE Tmp_InstrumentFilter;
        DROP TABLE Tmp_EUS_IDs_Processed;
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

    DROP TABLE IF EXISTS Tmp_Instruments;
    DROP TABLE IF EXISTS Tmp_InstrumentFilter;
    DROP TABLE IF EXISTS Tmp_EUS_IDs_Processed;
END
$$;


ALTER PROCEDURE public.update_dataset_interval_for_multiple_instruments(IN _daystoprocess integer, IN _updateemslinstrumentusage boolean, IN _infoonly boolean, IN _previewprocedurecall boolean, IN _instrumentstoprocess text, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_dataset_interval_for_multiple_instruments(IN _daystoprocess integer, IN _updateemslinstrumentusage boolean, IN _infoonly boolean, IN _previewprocedurecall boolean, IN _instrumentstoprocess text, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_dataset_interval_for_multiple_instruments(IN _daystoprocess integer, IN _updateemslinstrumentusage boolean, IN _infoonly boolean, IN _previewprocedurecall boolean, IN _instrumentstoprocess text, INOUT _message text, INOUT _returncode text) IS 'UpdateDatasetIntervalForMultipleInstruments';

