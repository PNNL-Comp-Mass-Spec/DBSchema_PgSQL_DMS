--
-- Name: get_monthly_emsl_instrument_usage_report(text, text, boolean, boolean); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_monthly_emsl_instrument_usage_report(_year text, _month text, _infoonly boolean DEFAULT false, _getusagereportdata boolean DEFAULT true) RETURNS TABLE(emsl_inst_id integer, dms_instrument public.citext, type public.citext, start timestamp without time zone, minutes integer, proposal public.citext, usage public.citext, users public.citext, operator public.citext, comment public.citext)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Create a monthly usage report for multiple instruments for given year and month
**
**  Arguments:
**    _year                 Year (as text, for compatibility with the website)
**    _month                Month (as text)
**    _infoOnly             When true, show debug information
**    _getUsageReportData   When _infoOnly is true, if this is false, do not call procedure get_monthly_instrument_usage_report
**
**  Auth:   grk
**  Date:   03/16/2012
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/03/2019 mem - Add support for DMS instruments that share a single eusInstrumentId
**          02/14/2022 mem - Add new columns to temporary table Tmp_InstrumentUsageData (to match data returned by GetMonthlyInstrumentUsageReport)
**                         - Add _infoOnly parameter
**          02/14/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _instrument text;
    _eusInstrumentId int;
    _message text := '';
    _returnCode text := '';

    _previewData text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _year               := Trim(Coalesce(_year, ''));
    _month              := Trim(Coalesce(_month, ''));
    _infoOnly           := Coalesce(_infoOnly, false);
    _getUsageReportData := Coalesce(_getUsageReportData, true);

    ---------------------------------------------------
    -- Temp table to hold results
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_InstrumentUsageData (
        EMSL_Inst_ID int,
        Instrument citext,
        Type citext,
        Start timestamp,
        Minutes int,
        Proposal citext NULL,
        Usage citext NULL,
        Users citext NULL,
        Operator citext NULL,
        Comment citext NULL,
        Year int,
        Month int,
        ID int
    );

    ---------------------------------------------------
    -- Temp table to hold list of production instruments
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_Instruments (
        EntryID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        Instrument text
    );

    ---------------------------------------------------
    -- Temp table to track DMS instruments that share the same EUS ID
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_InstrumentsToProcessByID (
        EUS_Instrument_ID int NOT NULL,
        Instrument text NOT NULL
    );

    ---------------------------------------------------
    -- Accumulate data for all instruments, one at a time
    ---------------------------------------------------

    BEGIN
        ---------------------------------------------------
        -- Find production instruments that we need to process by EUS_Instrument_ID
        -- because two (or more) DMS Instruments have the same EUS_Instrument_ID
        ---------------------------------------------------

        INSERT INTO Tmp_InstrumentsToProcessByID ( eus_instrument_id, instrument )
        SELECT InstMapping.eus_instrument_id,
               InstName.instrument
        FROM t_instrument_name InstName
             INNER JOIN t_emsl_dms_instrument_mapping InstMapping
               ON InstName.instrument_id = InstMapping.dms_instrument_id
             INNER JOIN ( SELECT eus_instrument_id
                          FROM t_instrument_name InstName
                               INNER JOIN t_emsl_dms_instrument_mapping InstMapping
                                 ON InstName.instrument_id = InstMapping.dms_instrument_id
                          GROUP BY eus_instrument_id
                          HAVING COUNT(InstMapping.dms_instrument_id) > 1
                        ) LookupQ
               ON InstMapping.eus_instrument_id = LookupQ.eus_instrument_id
        WHERE InstName.status = 'Active' AND
              InstName.operations_role = 'Production';

        ---------------------------------------------------
        -- Get list of active production instruments
        ---------------------------------------------------

        INSERT INTO Tmp_Instruments( instrument )
        SELECT instrument
        FROM t_instrument_name
        WHERE status = 'Active' AND
              operations_role = 'Production' AND
              NOT instrument IN ( SELECT instrument
                                  FROM Tmp_InstrumentsToProcessByID );

        If _infoOnly Then
            RAISE INFO '';

            SELECT string_agg(instrument, ', ' ORDER BY instrument)
            INTO _previewData
            FROM Tmp_Instruments;

            RAISE INFO 'Active production instruments: %', Coalesce(_previewData, '');

            SELECT string_agg(format('EUS ID %s: %s', EUS_Instrument_ID, Instrument), ', ' ORDER BY EUS_Instrument_ID)
            INTO _previewData
            FROM Tmp_InstrumentsToProcessByID;

            RAISE INFO 'Instruments to process by EUS ID: %', Coalesce(_previewData, '');
        End If;

        ---------------------------------------------------
        -- Get usage data for instruments, by name
        ---------------------------------------------------

        FOR _instrument IN
            SELECT Instrument
            FROM Tmp_Instruments
            ORDER BY EntryID
        LOOP

            If _infoOnly Then
                RAISE INFO 'SELECT * FROM get_monthly_instrument_usage_report (%, 0, %, %, ''report'');', _instrument, _year, _month;
            End If;

            If Not _infoOnly Or _infoOnly And _getUsageReportData Then
                INSERT INTO Tmp_InstrumentUsageData (Instrument, EMSL_Inst_ID, Start, Type, Minutes, Usage, Proposal, Users, Operator, Comment, Year, Month, ID)
                SELECT U.Instrument,
                       U.EMSL_Inst_ID,
                       U.Start,
                       U.Type,
                       U.Minutes,
                       U.Usage,
                       U.Proposal,
                       U.Users,
                       U.Operator,
                       U.Comment,
                       U.Year,
                       Month,
                       Dataset_ID
                FROM public.get_monthly_instrument_usage_report(_instrument, 0, _year, _month, 'report') U;
            End If;

        END LOOP;

        ---------------------------------------------------
        -- Get usage data for instruments, by EUS Instrument ID
        ---------------------------------------------------

        FOR _instrument, _eusInstrumentId IN
            SELECT Instrument,
                   EUS_Instrument_ID
            FROM Tmp_InstrumentsToProcessByID
            ORDER BY EUS_Instrument_ID
        LOOP
            If _infoOnly Then
                RAISE INFO 'SELECT * FROM public.get_monthly_instrument_usage_report('''', %, %, %, ''report'')', _eusInstrumentId, _year, _month;
            End If;

            If Not _infoOnly Or _infoOnly And _getUsageReportData Then
                INSERT INTO Tmp_InstrumentUsageData (Instrument, EMSL_Inst_ID, Start, Type, Minutes, Usage, Proposal, Users, Operator, Comment, Year, Month, ID)
                SELECT U.Instrument,
                       U.EMSL_Inst_ID,
                       U.Start,
                       U.Type,
                       U.Minutes,
                       U.Usage,
                       U.Proposal,
                       U.Users,
                       U.Operator,
                       U.Comment,
                       U.Year,
                       U.Month,
                       U.Dataset_ID
                FROM public.get_monthly_instrument_usage_report('', _eusInstrumentId, _year, _month, 'report') U;
            End If;

        END LOOP;

        ---------------------------------------------------
        -- Return accumulated report
        ---------------------------------------------------

        RETURN QUERY
        SELECT U.EMSL_Inst_ID,
               U.Instrument AS DMS_Instrument,
               U.Type,
               U.Start,
               U.Minutes,
               U.Proposal,
               U.Usage,
               U.Users,
               U.Operator,
               U.Comment
        FROM Tmp_InstrumentUsageData U;

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

    DROP TABLE IF EXISTS Tmp_InstrumentUsageData;
    DROP TABLE IF EXISTS Tmp_Instruments;
    DROP TABLE IF EXISTS Tmp_InstrumentsToProcessByID;
END
$$;


ALTER FUNCTION public.get_monthly_emsl_instrument_usage_report(_year text, _month text, _infoonly boolean, _getusagereportdata boolean) OWNER TO d3l243;

--
-- Name: FUNCTION get_monthly_emsl_instrument_usage_report(_year text, _month text, _infoonly boolean, _getusagereportdata boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_monthly_emsl_instrument_usage_report(_year text, _month text, _infoonly boolean, _getusagereportdata boolean) IS 'GetMonthlyEMSLInstrumentUsageReport';

