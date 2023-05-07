--
CREATE OR REPLACE PROCEDURE public.update_dataset_interval_for_multiple_instruments
(
    _daysToProcess int = 60,
    _updateEMSLInstrumentUsage boolean = true
    _infoOnly boolean = false,
    _previewProcedureCall boolean = false,
    _instrumentsToProcess text = '',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates dataset interval and creates entries
**      for long intervals in the intervals table for
**      all production instruments
**
**  Arguments:
**    _daysToProcess   Also affects whether UpdateEMSLInstrumentUsageReport is called for previous months
**
**  Auth:   grk
**  Date:   02/09/2012 grk - Initial version
**          03/07/2012 mem - Added parameters _daysToProcess, _infoOnly, and _message
**          03/21/2012 grk - Added call to UpdateEMSLInstrumentUsageReport
**          03/22/2012 mem - Added parameter _updateEMSLInstrumentUsage
**          03/26/2012 grk - Added call to UpdateEMSLInstrumentUsageReport for previous month
**          03/27/2012 grk - Added code to delete entries from T_EMSL_Instrument_Usage_Report
**          03/27/2012 grk - Using V_Instrument_Tracked
**          04/09/2012 grk - modified algorithm
**          08/02/2012 mem - Updated _daysToProcess to default to 60 days instead of 30 days
**          09/18/2012 grk - Only do EMSL instrument updates for EMSL instruments
**          10/06/2012 grk - Removed update of EMSL usage report for previous month
**          03/12/2014 grk - Added processing for 'tracked' instruments (OMCDA-1058)
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/10/2017 mem - Add parameter _instrumentsToProcess
**          04/11/2017 mem - Now passing _infoOnly to UpdateEMSLInstrumentUsageReport
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/03/2019 mem - Pass _eusInstrumentId to UpdateEMSLInstrumentUsageReport for select instruments
**          01/28/2022 mem - Call UpdateEMSLInstrumentUsageReport for both the current month, plus also previous months if _daysToProcess is greater than 15
**          02/15/2022 mem - Fix major bug decrementing _instrumentUsageMonth when processing multiple instruments
**                         - Add missing Order By clause
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _endDate timestamp;
    _instrumentUsageMonth timestamp;
    _currentInstrumentUsageMonth timestamp;
    _instrumentUsageMonthsToUpdate real;
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

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _daysToProcess := Coalesce(_daysToProcess, 60);
    If _daysToProcess < 10 Then
        _daysToProcess := 10;
    End If;

    _updateEMSLInstrumentUsage := Coalesce(_updateEMSLInstrumentUsage, true);

    _infoOnly := Coalesce(_infoOnly, false);
    _previewProcedureCall := Coalesce(_previewProcedureCall, false);

    _instrumentsToProcess := Coalesce(_instrumentsToProcess, '');

    ---------------------------------------------------
    -- Set up date interval and key values
    ---------------------------------------------------

    _instrumentUsageMonth := CURRENT_TIMESTAMP;

    _endDate := CURRENT_TIMESTAMP;
    _instrumentUsageMonth := CURRENT_TIMESTAMP;

    -- Update instrument usage for the current month, plus possibly the last few months, depending on _daysToProcess
    -- For example, if _daysToProcess is 60, will call UpdateEMSLInstrumentUsageReport for this month plus the last two months
    _instrumentUsageMonthsToUpdate := 1 + Round(_daysToProcess / 31.0, 0)

    _startDate        := _endDate - make_interval(days => _daysToProcess);
    _currentYear      := Extract(year from _endDate);
    _currentMonth     := Extract(month from _endDate);
    _day              := Extract(day from _endDate);
    _hour             := Extract(hour from _endDate);

    _prevDate         := _endDate - Interval '1 month';
    _prevMonth        := Extract(month from _prevDate);
    _prevYear         := Extract(year from _prevDate);

    _nextMonth        := Extract(month from _endDate + Interval '1 month');
    _nextYear         := Extract(year from _endDate + Interval '1 month');

    _startOfNextMonth := make_date(_nextYear, _nextMonth, 1);

    ---------------------------------------------------
    -- Temp table to hold list of production instruments
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Instruments (
        Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Instrument text,
        EMSL text,
        Tracked int,
        EUS_Instrument_ID Int Null,
        Use_EUS_ID int Not Null
    );

    CREATE TEMP TABLE Tmp_InstrumentFilter (
        Instrument text
    );

    CREATE TEMP TABLE Tmp_EUS_IDs_Processed (
        EUS_Instrument_ID Int Not Null,
    );

    ---------------------------------------------------
    -- Process updates for all instruments, one at a time
    -- Filter on _instrumentsToProcess if not-blank
    ---------------------------------------------------

    BEGIN

        If char_length(_instrumentsToProcess) > 0 Then

            ---------------------------------------------------
            -- Get filtered list of tracked instruments
            ---------------------------------------------------

            -- Populate Tmp_InstrumentFilter using _instrumentsToProcess

            INSERT INTO Tmp_InstrumentFilter( Instrument )
            SELECT Value
            FROM public.parse_delimited_list ( _instrumentsToProcess, ',');

            INSERT INTO Tmp_Instruments( Instrument,
                                          EMSL,
                                          Tracked,
                                          EUS_Instrument_ID,
                                          Use_EUS_ID )
            SELECT InstList.Name,
                   InstList.EUS_Primary_Instrument AS EMSL,
                   InstList.Tracked,
                   InstList.EUS_Instrument_ID,
                   0
            FROM V_Instrument_Tracked InstList
                 INNER JOIN Tmp_InstrumentFilter InstFilter
                   ON InstList.Name = InstFilter.Instrument
            ORDER BY Coalesce(InstList.EUS_Instrument_ID, 0), InstList.Name;

        Else

            ---------------------------------------------------
            -- Get list of tracked instruments
            ---------------------------------------------------

            INSERT INTO Tmp_Instruments( Instrument,
                                          EMSL,
                                          Tracked,
                                          EUS_Instrument_ID,
                                          Use_EUS_ID )
            SELECT Name,
                   EUS_Primary_Instrument AS EMSL,
                   Tracked,
                   EUS_Instrument_ID,
                   0
            FROM V_Instrument_Tracked
            ORDER BY Coalesce(EUS_Instrument_ID, 0), Name

        End If;

        ---------------------------------------------------
        -- Flag instruments where we need to use EUS instrument ID
        -- instead of instrument name when calling UpdateEMSLInstrumentUsageReport
        ---------------------------------------------------

        UPDATE Tmp_Instruments
        SET Use_EUS_ID = 1
        FROM Tmp_Instruments

        /********************************************************************************
        ** This UPDATE query includes the target table name in the FROM clause
        ** The WHERE clause needs to have a self join to the target table, for example:
        **   UPDATE Tmp_Instruments
        **   SET ...
        **   FROM source
        **   WHERE source.id = Tmp_Instruments.id;
        ********************************************************************************/

                               ToDo: Fix this query

                INNER JOIN ( SELECT InstName.instrument,
                                    InstMapping.eus_instrument_id
                            FROM t_instrument_name InstName
                                INNER JOIN t_emsl_dms_instrument_mapping InstMapping
                                    ON InstName.instrument_id = InstMapping.dms_instrument_id
                                INNER JOIN ( SELECT eus_instrument_id
                                             FROM t_instrument_name InstName
                                                    INNER JOIN t_emsl_dms_instrument_mapping InstMapping
                                                    ON InstName.instrument_id = InstMapping.dms_instrument_id
                                             WHERE Not eus_instrument_id Is Null
                                             GROUP BY eus_instrument_id
                                             HAVING COUNT(*) > 1
                                           ) LookupQ
                                    ON InstMapping.eus_instrument_id = LookupQ.eus_instrument_id
                           ) FilterQ
                ON Tmp_Instruments.eus_instrument_id = FilterQ.eus_instrument_id

        If _infoOnly Then
            SELECT *
            FROM Tmp_Instruments
            ORDER By Instrument
        End If;

        ---------------------------------------------------
        -- Update intervals for each instrument
        ---------------------------------------------------

        FOR _instrumentInfo IN
            SELECT Instrument,
                   EMSL AS EmslInstrument,
                   Tracked,
                   Use_EUS_ID AS UseEUSid,
                   EUS_Instrument_ID AS EusInstrumentId,
                   Entry_ID AS EntryID
            FROM Tmp_Instruments
            WHERE Entry_ID > _entryID
            ORDER BY Entry_ID
        LOOP
            _skipInstrument := false;

            If _instrumentInfo.UseEUSid > 0 Then
                If Exists (Select * From Tmp_EUS_IDs_Processed Where EUS_Instrument_ID = _instrumentInfo.EusInstrumentId) Then
                    _skipInstrument := true;
                Else
                    Insert Into Tmp_EUS_IDs_Processed (EUS_Instrument_ID)
                    Values (_instrumentInfo.EusInstrumentId)
                End If;
            End If;

            If _skipInstrument Then
                CONTINUE;
            End If;

            If _infoOnly And _previewProcedureCall Then
                RAISE INFO 'Call update_dataset_interval %, %, %, _message => _message, _infoOnly => _infoOnly)', _instrumentInfo.Instrument, _startDate, _startOfNextMonth;
            Else
                Call update_dataset_interval (_instrumentInfo.Instrument, _startDate, _startOfNextMonth, _message => _message, _infoOnly => _infoOnly);
            End If;

            If Not (_updateEMSLInstrumentUsage AND (_instrumentInfo.EmslInstrument = 'Y'::citext OR _instrumentInfo.Tracked = 1)) Then
                If _infoOnly Then
                    RAISE INFO '%', 'Skip call to UpdateEMSLInstrumentUsageReport for Instrument ' || _instrument;
                    RAISE INFO ' ';
                End If;

                CONTINUE;
            End If;

            -- Call UpdateEMSLInstrumentUsageReport for this month, plus optionally previous months (if _instrumentUsageMonthsToUpdate is greater than 1)
            --
            _iteration := 0;
            _currentInstrumentUsageMonth := _instrumentUsageMonth;

            WHILE _iteration < _instrumentUsageMonthsToUpdate
            LOOP
                _iteration := _iteration + 1;

                If _infoOnly Then
                    RAISE INFO 'Call UpdateEMSLInstrumentUsageReport for Instrument %, target month %-%',
                                _instrumentInfo.Instrument,
                                Extract(year from _currentInstrumentUsageMonth),
                                Extract(month from _currentInstrumentUsageMonth);

                End If;

                If Not _infoOnly Or _infoOnly And Not _previewProcedureCall Then
                    If _instrumentInfo.UseEUSid > 0 Then
                        Call update_emsl_instrument_usage_report ('', _instrumentInfo.EusInstrumentId, _currentInstrumentUsageMonth, _message => _message, _infoOnly => _infoOnly);
                    Else
                        Call update_emsl_instrument_usage_report (_instrumentInfo.Instrument, 0, _currentInstrumentUsageMonth, _message => _message, _infoOnly => _infoOnly);
                    End If;
                End If;

                If _infoOnly Then
                    RAISE INFO '%', '';
                End If;

                _currentInstrumentUsageMonth :=  _currentInstrumentUsageMonth - Interval '1 month';
            END LOOP;

        END LOOP;

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

    If _infoOnly and _returnCode <> '' Then
        RAISE INFO '%', _message;
    End If;

    DROP TABLE IF EXISTS Tmp_Instruments;
    DROP TABLE IF EXISTS Tmp_InstrumentFilter;
    DROP TABLE IF EXISTS Tmp_EUS_IDs_Processed;
END
$$;

COMMENT ON PROCEDURE public.update_dataset_interval_for_multiple_instruments IS 'UpdateDatasetIntervalForMultipleInstruments';
