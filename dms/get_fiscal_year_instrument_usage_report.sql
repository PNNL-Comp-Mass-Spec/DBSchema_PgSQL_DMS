--
-- Name: get_fiscal_year_instrument_usage_report(text, integer, integer, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_fiscal_year_instrument_usage_report(_instrument text, _eusinstrumentid integer DEFAULT 0, _fiscalyear integer DEFAULT 0, _outputformat text DEFAULT 'rollup'::text) RETURNS TABLE(instrument public.citext, emsl_inst_id integer, start timestamp without time zone, type public.citext, minutes integer, percentage numeric, proposal public.citext, usage public.citext, users public.citext, operator public.citext, comment public.citext, year integer, month integer, dataset_id integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Create a usage report for a given instrument, for the given fiscal year (October through September)
**
**      Output format 'rollup' summarizes usage by type (dataset or interval), proposal, and usage
**      Output format 'usage_rollup' summarizes usage by type and usage (but not by proposal)
**
**  Arguments:
**    _instrument           Instrument name
**    _eusInstrumentId      EMSL instrument ID to process; use this to process instruments like the 12T or the 15T where there are two instrument entries in DMS, yet they both map to the same EUS_Instrument_ID
**    _fiscalYear           Fiscal Year (if 0, create a report for the current fiscal year)
**    _outputFormat         Output format: 'report', 'details', 'rollup', 'usage_rollup'
**
**  Auth:   mem
**  Date:   11/27/2024 mem - Initial version
**
*****************************************************/
DECLARE
    _processByEUS boolean := false;
    _eusInstrumentIdAlt int;

    _logErrors boolean := false;
    _startMonth date;
    _endMonth date;
    _currentMonthStart timestamp;
    _monthlyUsageReportFormat text;
    _nextMonth timestamp;
    _daysInMonth int;
    _minutesInMonth int;
    _year int;
    _month int;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _message text;
BEGIN
    RAISE INFO '';

    BEGIN
        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _instrument      := Trim(Coalesce(_instrument, ''));
        _eusInstrumentId := Coalesce(_eusInstrumentId, 0);
        _fiscalYear      := Coalesce(_fiscalYear, 0);
        _outputFormat    := Trim(Lower(Coalesce(_outputFormat, '')));

        -- If _outputFormat is an empty string, change it to 'rollup'
        If _outputFormat = '' Then
            _outputFormat := 'rollup';
        End If;

        If Not _outputFormat In ('report', 'details', 'rollup', 'usage_rollup') Then
            RAISE EXCEPTION 'Invalid output format; should be report, details, rollup, or check';
        End If;

        If _eusInstrumentId > 0 Then
            _processByEUS := true;
        End If;

        If _fiscalYear <= 0 Then
            _fiscalYear := get_fiscal_year_from_date(CURRENT_TIMESTAMP::timestamp);
        End If;

        ---------------------------------------------------
        -- Determine the months to process
        ---------------------------------------------------

        _startMonth := make_date(_fiscalYear - 1, 10, 1);
        _endMonth   := make_date(_fiscalYear, 9, 30);

        If _endMonth > CURRENT_TIMESTAMP::date Then
            _endMonth := make_date(Extract(year from CURRENT_TIMESTAMP)::int, Extract(month from CURRENT_TIMESTAMP)::int, 28);
        End If;

        ---------------------------------------------------
        --  Auto switch to EUS Instrument ID, if needed
        ---------------------------------------------------

        If Not _processByEUS Then
            -- Look for EUS Instruments mapped to two or more DMS instruments
            -- (this query comes from function get_monthly_instrument_usage_report)

            SELECT InstMapping.eus_instrument_id
            INTO _eusInstrumentIdAlt
            FROM t_instrument_name InstName
                 INNER JOIN t_emsl_dms_instrument_mapping InstMapping
                   ON InstName.instrument_id = InstMapping.dms_instrument_id
                 INNER JOIN (SELECT InstMapping.eus_instrument_id
                             FROM t_instrument_name InstName
                                  INNER JOIN t_emsl_dms_instrument_mapping InstMapping
                                    ON InstName.instrument_id = InstMapping.dms_instrument_id
                             GROUP BY InstMapping.eus_instrument_id
                             HAVING COUNT(InstMapping.dms_instrument_id) > 1
                            ) LookupQ
                   ON InstMapping.eus_instrument_id = LookupQ.eus_instrument_id
            WHERE InstName.instrument = _instrument::citext;

            If FOUND Then
                If Coalesce(_eusInstrumentIdAlt, 0) = 0 Then
                    RAISE WARNING 'EUS Instrument ID is null in t_emsl_dms_instrument_mapping for instrument %', _instrument;
                Else
                    _processByEUS := true;
                    _eusInstrumentId := _eusInstrumentIdAlt;
                End If;
            End If;
        End If;

        ---------------------------------------------------
        -- Create a temporary table to hold report data
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_Fiscal_Year_Instrument_Usage (
            Instrument   citext,
            EMSL_Inst_ID int,
            Start        timestamp without time zone,
            Type         citext,
            Minutes      int,
            Percentage   numeric,
            Proposal     citext NULL,
            Usage        citext NULL,
            Users        citext NULL,
            Operator     citext NULL,
            Comment      citext NULL,
            Year         int,
            Month        int,
            Dataset_ID   int,
            Minutes_in_Month int
        );

        ---------------------------------------------------
        -- Query get_fiscal_year_instrument_usage_report for each month in the fiscal year
        ---------------------------------------------------

        _currentMonthStart := _startMonth;

        If _outputFormat = 'usage_rollup' Then
            _monthlyUsageReportFormat := 'rollup';
        Else
            _monthlyUsageReportFormat := _outputFormat;
        End If;

        WHILE true
        LOOP
            _year  := Extract(year from _currentMonthStart);
            _month := Extract(month from _currentMonthStart);

            _nextMonth := _currentMonthStart + INTERVAL '1 month';  -- Beginning of the next month after _currentMonthStart

            _daysInMonth := Extract(day from _nextMonth - _currentMonthStart);
            _minutesInMonth := _daysInMonth * 1440;

            If _processByEUS Then
                RAISE INFO 'Obtaining data for EUS instrument ID %, month %-%', _eusInstrumentId, _year, _month;
            Else
                RAISE INFO 'Obtaining data for instrument %, month %-%', _instrument, _year, _month;
            End If;

            INSERT INTO Tmp_Fiscal_Year_Instrument_Usage (
                Instrument,
                EMSL_Inst_ID,
                Start,
                Type,
                Minutes,
                Percentage,
                Proposal,
                Usage,
                Users,
                Operator,
                Comment,
                Year,
                Month,
                Dataset_ID,
                Minutes_in_Month
            )
            SELECT U.Instrument,
                   U.EMSL_Inst_ID,
                   U.Start,
                   U.Type,
                   U.Minutes,
                   U.Percentage,
                   U.Proposal,
                   U.Usage,
                   U.Users,
                   U.Operator,
                   U.Comment,
                   U.Year,
                   U.Month,
                   U.Dataset_ID,
                   _minutesInMonth
            FROM get_monthly_instrument_usage_report(_instrument, _eusInstrumentId, _year::text, _month::text, _monthlyUsageReportFormat) U;

            _currentMonthStart := _currentMonthStart + Interval '1 month';

            If _currentMonthStart > _endMonth Then
                -- Break out of the while loop
                EXIT;
            End If;
        END LOOP;

        If _outputFormat = 'report' Then
            ---------------------------------------------------
            -- Return results as a report
            ---------------------------------------------------

            RETURN QUERY
            SELECT U.Instrument,
                   U.EMSL_Inst_ID,
                   U.Start,
                   U.Type,
                   U.Minutes,
                   U.Percentage,
                   U.Proposal,
                   U.Usage,
                   U.Users,
                   U.Operator,
                   U.Comment,
                   U.Year,
                   U.Month,
                   U.Dataset_ID
             FROM Tmp_Fiscal_Year_Instrument_Usage U
             ORDER BY U.Start;
        End If;

        If _outputFormat = 'details' Then
            ---------------------------------------------------
            -- Return usage details
            ---------------------------------------------------

            RETURN QUERY
            SELECT U.Instrument,
                   U.EMSL_Inst_ID,
                   U.Start,
                   U.Type,
                   U.Minutes,
                   U.Percentage,
                   U.Proposal,
                   U.Usage,
                   U.Users,
                   U.Operator,
                   U.Comment,
                   U.Year,
                   U.Month,
                   U.Dataset_ID
             FROM Tmp_Fiscal_Year_Instrument_Usage U
             ORDER BY U.Start;
        End If;

        If _outputFormat = 'rollup' Or _outputFormat = '' Then
            ---------------------------------------------------
            -- Rollup by type (dataset or interval), proposal, and usage category
            ---------------------------------------------------

            RETURN QUERY
            SELECT SumQ.Instrument,
                   SumQ.EMSL_Inst_ID,
                   SumQ.Start,
                   SumQ.Type,
                   SumQ.Minutes,
                   Round(SumQ.Minutes::numeric / SumQ.Minutes_in_Fiscal_Year * 100.0, 1) AS Percentage,
                   SumQ.Proposal,
                   SumQ.Usage,
                   ''::citext AS Users,
                   ''::citext AS Operator,
                   ''::citext AS Comment,
                   _fiscalYear AS Year,
                   0 AS Month,
                   0 AS Dataset_ID
            FROM (SELECT U.Instrument,
                         U.EMSL_Inst_ID,
                         MIN(U.Start) AS Start,
                         U.Type,
                         SUM(U.Minutes)::int AS Minutes,
                         U.Proposal,
                         U.Usage,
                         SUM(U.minutes_in_month)::int AS Minutes_in_Fiscal_Year     -- This will only be part of the fiscal year if processing data for the current fiscal year
                  FROM Tmp_Fiscal_Year_Instrument_Usage U
                  GROUP BY U.Instrument, U.EMSL_Inst_ID, U.Type, U.Proposal, U.Usage
                 ) SumQ
            ORDER BY SumQ.Type, SumQ.Usage, SumQ.Proposal;
        End If;

        If _outputFormat = 'usage_rollup' Then
            ---------------------------------------------------
            -- Rollup by type (dataset or interval) and usage category
            ---------------------------------------------------

            RETURN QUERY
            SELECT SumQ.Instrument,
                   SumQ.EMSL_Inst_ID,
                   SumQ.Start,
                   SumQ.Type,
                   SumQ.Minutes,
                   Round(SumQ.Minutes::numeric / SumQ.Minutes_in_Fiscal_Year * 100.0, 1) AS Percentage,
                   ''::citext AS Proposal,
                   SumQ.Usage,
                   ''::citext AS Users,
                   ''::citext AS Operator,
                   ''::citext AS Comment,
                   _fiscalYear AS Year,
                   0 AS Month,
                   0 AS Dataset_ID
            FROM (SELECT U.Instrument,
                         U.EMSL_Inst_ID,
                         MIN(U.Start) AS Start,
                         U.Type,
                         SUM(U.Minutes)::int AS Minutes,
                         U.Usage,
                         SUM(U.minutes_in_month)::int AS Minutes_in_Fiscal_Year     -- This will only be part of the fiscal year if processing data for the current fiscal year
                  FROM Tmp_Fiscal_Year_Instrument_Usage U
                  GROUP BY U.Instrument, U.EMSL_Inst_ID, U.Type, U.Usage
                 ) SumQ
            ORDER BY SumQ.Type, SumQ.Usage;
        End If;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        RAISE WARNING '%', _message;
    END;

    DROP TABLE IF EXISTS Tmp_Fiscal_Year_Instrument_Usage;
END
$$;


ALTER FUNCTION public.get_fiscal_year_instrument_usage_report(_instrument text, _eusinstrumentid integer, _fiscalyear integer, _outputformat text) OWNER TO d3l243;

