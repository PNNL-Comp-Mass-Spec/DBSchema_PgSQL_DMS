--
-- Name: get_monthly_instrument_usage_report(text, integer, text, text, text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_monthly_instrument_usage_report(_instrument text, _eusinstrumentid integer DEFAULT 0, _year text DEFAULT ''::text, _month text DEFAULT ''::text, _outputformat text DEFAULT 'details'::text) RETURNS TABLE(instrument public.citext, emsl_inst_id integer, start timestamp without time zone, type public.citext, minutes integer, percentage numeric, proposal public.citext, usage public.citext, users public.citext, operator public.citext, comment public.citext, year integer, month integer, dataset_id integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Create a monthly usage report for given instrument, year, and month
**
**  Arguments:
**    _instrument           Instrument name
**    _eusInstrumentId      EMSL instrument ID to process; use this to process instruments like the 12T or the 15T where there are two instrument entries in DMS, yet they both map to the same EUS_Instrument_ID
**    _year                 Year (as text, for compatibility with the website)
**    _month                Month (as text)
**    _outputFormat         Output format: 'report', 'details', 'rollup', 'check', 'debug1', 'debug2', 'debug3'
**
**  Auth:   grk
**  Date:   03/06/2012 grk - Rename _mode to _outputFormat
**          03/06/2012 grk - Add long interval comment to 'detail' output format
**          03/10/2012 grk - Add '_otherNotAvailable'
**          03/15/2012 grk - Add 'report' _outputFormat
**          03/20/2012 grk - Add users to 'report' _outputFormat
**          03/21/2012 grk - Add operator ID for ONSITE interval to 'report' _outputFormat
**          08/21/2012 grk - Add code to pull comment from dataset
**          08/28/2012 grk - Add code to clear comment from ONSITE capability type
**          08/31/2012 grk - Remove 'Auto-switched dataset type ...' text from dataset comments
**          09/11/2012 grk - Add percent column to 'rollup' mode
**          09/18/2012 grk - Handle 'Operator' and 'PropUser' prorata comment fields
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/03/2019 mem - Add parameter _eusInstrumentId, which is sent to GetRunTrackingMonthlyInfoByID if non-zero
**          04/17/2020 mem - Add defaults for parameters _eusInstrumentId and _message
**                           Use Dataset_ID instead of ID
**          04/27/2020 mem - Update data validation checks
**                         - Make several columns in the output table nullable
**          05/26/2021 mem - Add support for usage types UserRemote and UserOnsite
**                         - Use REMOTE when the usage has UserRemote
**          03/17/2022 mem - Update comments and whitespace
**          05/27/2022 mem - Do not log year or month conversion errors to the database
**                         - Validate _year, _month, and _outputFormat
**          06/15/2023 mem - Add support for usage type 'RESOURCE_OWNER'
**          08/29/2023 mem - Ported to PostgreSQL
**          08/30/2023 mem - Exclude null values when parsing XML in column Breakdown
**          08/31/2023 mem - Swap columns usage and proposal and change to citext
**                         - Round start times to the nearest minute
**                         - Fix bug that changed _eusInstrumentId to null
**                         - Compute percentage values when _outputFormat is 'rollup'
**                         - Add missing columns to debug reports
**          09/08/2023 mem - Adjust capitalization of keywords
**                         - Include schema name when calling function verify_sp_authorized()
**          10/09/2024 mem - When determining the instrument name for the Instrument ID specified by _eusInstrumentId, preferably choose the first active instrument, sorted alphabetically by name
**
*****************************************************/
DECLARE
    _logErrors boolean := false;
    _monthValue int;
    _yearValue int;
    _processByEUS boolean := false;
    _currentMonthStart timestamp;
    _nextMonth timestamp;
    _daysInMonth int;
    _minutesInMonth int;

    _eusInstrumentIdAlt int;
    _actualInstrument text;

    _startMin timestamp;
    _durationSum int;
    _intervalSum int;
    _percentInUse numeric;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

    _formatSpecifierInstUsage text;
    _infoHeadInstUsage text;
    _infoHeadSeparatorInstUsage text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
    _message text;
BEGIN

    _instrument      := Trim(Coalesce(_instrument, ''));
    _eusInstrumentId := Coalesce(_eusInstrumentId, 0);
    _outputFormat    := Trim(Lower(Coalesce(_outputFormat, '')));

    If _eusInstrumentId > 0 Then
        _processByEUS := true;
    End If;

    BEGIN

        _monthValue := public.try_cast(_month, null::int);

        If _monthValue Is Null Or Not _monthValue Between 1 And 12 Then
            RAISE EXCEPTION 'Invalid month, must be an integer between 1 and 12';
        End If;

        _yearValue := public.try_cast(_year, null::int);

        If _yearValue Is Null Or _yearValue < 1970 Then
            RAISE EXCEPTION 'Invalid year, must be an integer';
        End If;

        -- If _outputFormat is an empty string, change it to 'details'
        If _outputFormat = '' Then
            _outputFormat := 'details';
        End If;

        If Not _outputFormat In ('report', 'details', 'rollup', 'check', 'debug1', 'debug2', 'debug3') Then
            RAISE EXCEPTION 'Invalid output format; should be report, details, rollup, or check';
        End If;

        If Not _processByEUS Then
            -- Auto switch to EUS Instrument ID if needed
            -- Look for EUS Instruments mapped to two or more DMS instruments

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
        -- Get maximum time available in month
        ---------------------------------------------------

        _currentMonthStart := make_date(_yearValue, _monthValue, 1)::timestamp;
        _nextMonth := _currentMonthStart + INTERVAL '1 month';  -- Beginning of the next month after _currentMonthStart

        _daysInMonth := Extract(day from _nextMonth - _currentMonthStart);
        _minutesInMonth := _daysInMonth * 1440;

        _logErrors := true;

        ---------------------------------------------------
        -- Create temporary table to hold report data and
        -- populate with datasets for the specified instrument and reporting month
        -- (function get_run_tracking_monthly_info_by_id returns intervals adjusted to monthly boundaries)
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_InstrumentUsage (
            Dataset_ID int,
            Type citext,
            Start timestamp,
            Duration int,
            Interval int,
            Proposal citext NULL,
            Usage citext NULL,
            UsageID int NULL,
            Normal int NULL,            -- 1 if a normal interval after a dataset (less than 180 minutes); 0 if a long interval after a dataset
            Comment citext NULL,
            Users citext NULL,
            Operator citext NULL
        );

        If _instrument = '' And _eusInstrumentId = 0 Then
            INSERT INTO Tmp_InstrumentUsage (
                Dataset_ID,
                Type,
                Start,
                Duration,
                Interval,
                Proposal,
                UsageID,
                Usage,
                Normal,
                Comment
            )
            VALUES (1, 'Error', NULL, 0, 0, '', 0, '', 0, 'Must define _instrument or _eusInstrumentId');

            RETURN QUERY
            SELECT ''::citext AS Instrument,
                   0 AS EMSL_Inst_ID,
                   U.Start,
                   U.Type,
                   U.Duration AS Minutes,
                   null::numeric AS Percentage,
                   U.Proposal,
                   U.Usage,
                   U.Users,
                   U.Operator,
                   U.Comment,
                   _yearValue AS Year,
                   _monthValue AS Month,
                   U.Dataset_ID
            FROM Tmp_InstrumentUsage U;

            DROP TABLE Tmp_InstrumentUsage;

            RETURN;
        End If;

        If _processByEUS Then
            INSERT INTO Tmp_InstrumentUsage (
                Dataset_ID,
                Type,
                Start,
                Duration,
                Interval,
                Proposal,
                UsageID,
                Usage,
                Normal
            )
            SELECT GRTMI.id,                -- Dataset_ID
                   'Dataset' AS Type,
                   date_trunc('minute', GRTMI.Time_Start) AS Start,     -- Round start time to the nearest minute
                   GRTMI.Duration,
                   Coalesce(GRTMI.INTERVAL, 0) AS Interval,
                   Coalesce(RR.eus_proposal_id, '') AS Proposal,
                   RR.eus_usage_type_id AS UsageID,
                   EUT.eus_usage_type AS Usage,
                   1
            FROM public.get_run_tracking_monthly_info_by_id(_eusInstrumentId, _yearValue, _monthValue, _options => '') AS GRTMI
                 LEFT OUTER JOIN t_requested_run AS RR
                   ON GRTMI.id = RR.dataset_id
                 INNER JOIN t_eus_usage_type EUT
                   ON RR.eus_usage_type_id = EUT.eus_usage_type_id;

        Else

            INSERT INTO Tmp_InstrumentUsage (
                Dataset_ID,
                Type,
                Start,
                Duration,
                Interval,
                Proposal,
                UsageID,
                Usage,
                Normal
            )
            SELECT GRTMI.id AS Dataset_ID,
                   'Dataset' AS Type,
                   date_trunc('minute', GRTMI.Time_Start) AS Start,     -- Round start time to the nearest minute
                   GRTMI.Duration,
                   Coalesce(GRTMI.INTERVAL, 0) AS Interval,
                   Coalesce(RR.eus_proposal_id, '') AS Proposal,
                   RR.eus_usage_type_id AS UsageID,
                   EUT.eus_usage_type AS Usage,
                   1
            FROM public.get_run_tracking_monthly_info(_instrument, _yearValue, _monthValue, _options => '') AS GRTMI
                 LEFT OUTER JOIN t_requested_run AS RR
                   ON GRTMI.id = RR.dataset_id
                 INNER JOIN t_eus_usage_type EUT
                   ON RR.eus_usage_type_id = EUT.eus_usage_type_id;

        End If;

        ---------------------------------------------------
        -- Get dataset comments
        --
        -- Use RegEx to remove text of the form:
        -- 'Auto-switched dataset type from HMS-MSn to HMS-HCD-HMSn on 2012-01-01'
        ---------------------------------------------------

        UPDATE Tmp_InstrumentUsage
        SET Comment = regexp_replace(Coalesce(DS.comment, ''), 'Auto-switched dataset type from.+to.+on \d{4,4}-\d{1,2}-\d{1,2}[;, ]*', '', 'g')
        FROM t_dataset AS DS
        WHERE DS.Dataset_ID = Tmp_InstrumentUsage.Dataset_ID;

        ---------------------------------------------------
        -- Make a temp table to work with long intervals and
        -- populate it with long intervals for the datasets
        -- that were added to the temp report table
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_LongIntervals (
              Dataset_ID int,
              Start timestamp,
              Breakdown XML NULL,
              Comment text NULL
        );

        INSERT INTO Tmp_LongIntervals (
            Dataset_ID,
            Start,
            Breakdown,          -- Holds usage description, from t_run_interval.comment
            Comment
        )
        SELECT I.dataset_id,    -- Dataset ID of the dataset that was acquired just before a given long interval
               I.start,
               I.usage,         -- Examples: '<u Maintenance="100" />' or '<u UserOnsite="100" Proposal="60594" PropUser="60420" />'  or '<u User="100" Proposal="51667" PropUser="48542" />'
               I.comment        -- Examples: 'Maintenance[100%]'       or 'UserOnsite[100%], Proposal[60594], PropUser[60420]'        or 'User[100%], Proposal[51667], PropUser[48542]'
        FROM t_run_interval I
             INNER JOIN Tmp_InstrumentUsage
               ON I.dataset_id = Tmp_InstrumentUsage.Dataset_ID;

        ---------------------------------------------------
        -- Mark datasets in temp report table that have long intervals
        ---------------------------------------------------

        UPDATE Tmp_InstrumentUsage
        SET Normal = 0
        FROM Tmp_LongIntervals
        WHERE Tmp_InstrumentUsage.Dataset_ID = Tmp_LongIntervals.Dataset_id;

        ---------------------------------------------------
        -- Make temp table to hold apportioned long interval values
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_ApportionedIntervals (
            Dataset_ID int,
            Start timestamp,
            Interval int,
            Proposal citext NULL,
            Usage citext NULL,
            Comment citext NULL,
            Users citext NULL,
            Operator citext NULL
        );

        ---------------------------------------------------
        -- Extract long interval apportionments from XML and
        -- use to save apportioned intervals to the temp table
        --
        -- Example XML in column Breakdown
        --   <u Maintenance="100" />
        --   <u User="100" Proposal="35092" />
        --   <u StaffNotAvailable="50" OtherNotAvailable="50" />
        --   <u CapDev="100" />
        --   <u Broken="100" />
        ---------------------------------------------------

        INSERT INTO Tmp_ApportionedIntervals (Dataset_ID, Start, Interval, Proposal, Usage, Comment)
        SELECT Tmp_LongIntervals.Dataset_ID,
               Tmp_LongIntervals.Start,
               public.try_cast((xpath('//u/@Broken', BreakDown))[1]::text, 0.0) * Tmp_InstrumentUsage.Interval / 100 AS Interval,
               '' AS Proposal,
               'BROKEN' AS Usage,
               Tmp_LongIntervals.Comment
        FROM Tmp_LongIntervals
        INNER JOIN Tmp_InstrumentUsage ON Tmp_InstrumentUsage.Dataset_ID = Tmp_LongIntervals.Dataset_ID
        WHERE NOT Breakdown IS NULL;

        INSERT INTO Tmp_ApportionedIntervals (Dataset_ID, Start, Interval, Proposal, Usage, Comment)
        SELECT Tmp_LongIntervals.Dataset_ID,
               Tmp_LongIntervals.Start,
               public.try_cast((xpath('//u/@Maintenance', BreakDown))[1]::text, 0.0) * Tmp_InstrumentUsage.Interval / 100 AS Interval,
               '' AS Proposal,
               'MAINTENANCE' AS Usage,            -- This is defined in t_emsl_instrument_usage_type
               Tmp_LongIntervals.Comment
        FROM Tmp_LongIntervals
        INNER JOIN Tmp_InstrumentUsage ON Tmp_InstrumentUsage.Dataset_ID = Tmp_LongIntervals.Dataset_ID
        WHERE NOT Breakdown IS NULL;

        INSERT INTO Tmp_ApportionedIntervals (Dataset_ID, Start, Interval, Proposal, Usage, Comment)
        SELECT Tmp_LongIntervals.Dataset_ID,
               Tmp_LongIntervals.Start,
               public.try_cast((xpath('//u/@OtherNotAvailable', BreakDown))[1]::text, 0.0) * Tmp_InstrumentUsage.Interval / 100 AS Interval,
               '' AS Proposal,
               'UNAVAILABLE' AS Usage,                 -- This is defined in t_emsl_instrument_usage_type
               Tmp_LongIntervals.Comment
        FROM Tmp_LongIntervals
        INNER JOIN Tmp_InstrumentUsage ON Tmp_InstrumentUsage.Dataset_ID = Tmp_LongIntervals.Dataset_ID
        WHERE NOT Breakdown IS NULL;

        INSERT INTO Tmp_ApportionedIntervals (Dataset_ID, Start, Interval, Proposal, Usage, Comment)
        SELECT Tmp_LongIntervals.Dataset_ID,
               Tmp_LongIntervals.Start,
               public.try_cast((xpath('//u/@StaffNotAvailable', BreakDown))[1]::text, 0.0) * Tmp_InstrumentUsage.Interval / 100 AS Interval,
               '' AS Proposal,
               'UNAVAIL_STAFF' AS Usage,               -- This is defined in t_emsl_instrument_usage_type
               Tmp_LongIntervals.Comment
        FROM Tmp_LongIntervals
        INNER JOIN Tmp_InstrumentUsage ON Tmp_InstrumentUsage.Dataset_ID = Tmp_LongIntervals.Dataset_ID
        WHERE NOT Breakdown IS NULL;

        INSERT INTO Tmp_ApportionedIntervals (Dataset_ID, Start, Interval, Operator, Proposal, Usage, Comment)
        SELECT Tmp_LongIntervals.Dataset_ID,
               Tmp_LongIntervals.Start,
               public.try_cast((xpath('//u/@CapDev', BreakDown))[1]::text, 0.0) * Tmp_InstrumentUsage.Interval / 100 AS Interval,
               (xpath('//u/@Operator', BreakDown))[1]::text AS Operator,
               '' AS Proposal,
               'CAP_DEV' AS Usage,                     -- This is defined in t_emsl_instrument_usage_type
               Tmp_LongIntervals.Comment
        FROM Tmp_LongIntervals
        INNER JOIN Tmp_InstrumentUsage ON Tmp_InstrumentUsage.Dataset_ID = Tmp_LongIntervals.Dataset_ID
        WHERE NOT Breakdown IS NULL;

        INSERT INTO Tmp_ApportionedIntervals (Dataset_ID, Start, Interval, Operator, Proposal, Usage, Comment)
        SELECT Tmp_LongIntervals.Dataset_ID,
               Tmp_LongIntervals.Start,
               public.try_cast((xpath('//u/@ResourceOwner', BreakDown))[1]::text, 0.0) * Tmp_InstrumentUsage.Interval / 100 AS Interval,
               (xpath('//u/@Operator', BreakDown))[1]::text AS Operator,
               '' AS Proposal,
               'RESOURCE_OWNER' AS Usage,              -- This is defined in t_emsl_instrument_usage_type
               Tmp_LongIntervals.Comment
        FROM Tmp_LongIntervals
        INNER JOIN Tmp_InstrumentUsage ON Tmp_InstrumentUsage.Dataset_ID = Tmp_LongIntervals.Dataset_ID
        WHERE NOT Breakdown IS NULL;

        INSERT INTO Tmp_ApportionedIntervals (Dataset_ID, Start, Interval, Proposal, Usage, Comment)
        SELECT Tmp_LongIntervals.Dataset_ID,
               Tmp_LongIntervals.Start,
               public.try_cast((xpath('//u/@InstrumentAvailable', BreakDown))[1]::text, 0.0) * Tmp_InstrumentUsage.Interval / 100 AS Interval,
               '' AS Proposal,
               'AVAILABLE' AS Usage,                   -- This is defined in t_emsl_instrument_usage_type
               Tmp_LongIntervals.Comment
        FROM Tmp_LongIntervals
        INNER JOIN Tmp_InstrumentUsage ON Tmp_InstrumentUsage.Dataset_ID = Tmp_LongIntervals.Dataset_ID
        WHERE NOT Breakdown IS NULL;

        INSERT INTO Tmp_ApportionedIntervals (Dataset_ID, Start, Interval, Proposal, Users, Usage, Comment)
        SELECT Tmp_LongIntervals.Dataset_ID,
               Tmp_LongIntervals.Start,
               (
                 public.try_cast((xpath('//u/@User', BreakDown))[1]::text, 0.0) +
                 public.try_cast((xpath('//u/@UserRemote', BreakDown))[1]::text, 0.0) +
                 public.try_cast((xpath('//u/@UserOnsite', BreakDown))[1]::text, 0.0)
               ) * Tmp_InstrumentUsage.Interval / 100 AS Interval,
               (xpath('//u/@Proposal', BreakDown))[1]::text AS Proposal,
               (xpath('//u/@PropUser', BreakDown))[1]::text AS Users,
               CASE WHEN public.try_cast((xpath('//u/@UserRemote', BreakDown))[1]::text, 0.0) > 0
                    THEN 'REMOTE'       -- Defined in t_emsl_instrument_usage_type; means we analyzed a sample for a person outside PNNL, typically as part of an EMSL User Project
                    ELSE 'ONSITE'       -- Defined in t_emsl_instrument_usage_type; means we analyzed a sample for a PNNL staff member, or for an external collaborator who was actually onsite overseeing the data acquisition
               END AS Usage,
               Tmp_LongIntervals.Comment
        FROM Tmp_LongIntervals
        INNER JOIN Tmp_InstrumentUsage ON Tmp_InstrumentUsage.Dataset_ID = Tmp_LongIntervals.Dataset_ID
        WHERE NOT Breakdown IS NULL;

        ---------------------------------------------------
        -- Get rid of meaningless apportioned long intervals
        ---------------------------------------------------

        DELETE FROM Tmp_ApportionedIntervals WHERE Interval = 0;

        If _outputFormat = 'debug1' Then

            RAISE INFO '';

            _formatSpecifier := '%-10s %-20s %-10s %-10s %-15s %-20s %-20s %-20s';

            _infoHead := format(_formatSpecifier,
                                'Dataset_ID',
                                'Start',
                                'Interval',
                                'Proposal',
                                'Usage',
                                'Comment',
                                'Users',
                                'Operator'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '----------',
                                         '--------------------',
                                         '----------',
                                         '----------',
                                         '---------------',
                                         '--------------------',
                                         '--------------------',
                                         '--------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT I.Dataset_ID,
                       public.timestamp_text(I.Start) AS Start,
                       I.Interval,
                       I.Proposal,
                       I.Usage,
                       I.Comment,
                       I.Users,
                       I.Operator
                FROM Tmp_ApportionedIntervals I
                ORDER BY I.Start
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Dataset_ID,
                                    _previewData.Start,
                                    _previewData.Interval,
                                    _previewData.Proposal,
                                    _previewData.Usage,
                                    _previewData.Comment,
                                    _previewData.Users,
                                    _previewData.Operator
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

        ---------------------------------------------------
        -- Clean up unecessary comments
        ---------------------------------------------------

        UPDATE Tmp_ApportionedIntervals I
        SET Comment = ''
        WHERE I.Usage IN ('CAP_DEV', 'ONSITE', 'REMOTE');

        ---------------------------------------------------
        -- Add apportioned long intervals to report table
        ---------------------------------------------------

        INSERT INTO Tmp_InstrumentUsage (
            Dataset_ID,
            Type,
            Start,
            Duration,
            Interval,
            Proposal,
            Usage,
            Comment,
            Users,
            Operator
        )
        SELECT I.Dataset_ID,
               'Interval' AS Type,
               I.Start,
               0 AS Duration,
               I.Interval,
               I.Proposal,
               I.Usage,
               I.Comment,
               I.Users,
               I.Operator
        FROM Tmp_ApportionedIntervals I;

        If _outputFormat Like 'debug%' Then

            _formatSpecifierInstUsage := '%-10s %-8s %-20s %-8s %-8s %-8s %-11s %-7s %-6s %-25s %-15s %-8s';

            _infoHeadInstUsage := format(_formatSpecifierInstUsage,
                                         'Dataset_ID',
                                         'Type',
                                         'Start',
                                         'Duration',
                                         'Interval',
                                         'Proposal',
                                         'Usage',
                                         'UsageID',
                                         'Normal',
                                         'Comment',
                                         'Users',
                                         'Operator'
                                        );

            _infoHeadSeparatorInstUsage := format(_formatSpecifierInstUsage,
                                                  '----------',
                                                  '--------',
                                                  '--------------------',
                                                  '--------',
                                                  '--------',
                                                  '--------',
                                                  '-----------',
                                                  '-------',
                                                  '------',
                                                  '-------------------------',
                                                  '---------------',
                                                  '--------'
                                                 );

        End If;

        If _outputFormat = 'debug2' Then

            RAISE INFO '';
            RAISE INFO '%', _infoHeadInstUsage;
            RAISE INFO '%', _infoHeadSeparatorInstUsage;

            FOR _previewData IN
                SELECT U.Dataset_ID,
                       U.Type,
                       public.timestamp_text(U.Start) AS Start,
                       U.Duration,
                       U.Interval,
                       U.Proposal,
                       U.Usage,
                       U.UsageID,
                       U.Normal,
                       U.Comment,
                       U.Users,
                       U.Operator
                FROM Tmp_InstrumentUsage U
                ORDER BY U.Start
            LOOP
                _infoData := format(_formatSpecifierInstUsage,
                                    _previewData.Dataset_ID,
                                    _previewData.Type,
                                    _previewData.Start,
                                    _previewData.Duration,
                                    _previewData.Interval,
                                    _previewData.Proposal,
                                    _previewData.Usage,
                                    _previewData.UsageID,
                                    _previewData.Normal,
                                    _previewData.Comment,
                                    _previewData.Users,
                                    _previewData.Operator
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

        ---------------------------------------------------
        -- Zero interval values for datasets with long intervals
        ---------------------------------------------------

        UPDATE Tmp_InstrumentUsage U
        SET Interval = 0
        WHERE U.Type = 'Dataset' AND U.Normal = 0;

        ---------------------------------------------------
        -- Translate remaining DMS usage categories
        -- to EMSL usage categories
        ---------------------------------------------------

        UPDATE Tmp_InstrumentUsage U
        SET Usage = 'ONSITE'
        WHERE U.Usage IN ('USER', 'USER_ONSITE');

        UPDATE Tmp_InstrumentUsage U
        SET Usage = 'REMOTE'
        WHERE U.Usage = 'USER_REMOTE';

        -- Starting in FY 24, Usage can also be 'RESOURCE_OWNER'

        ---------------------------------------------------
        -- Remove artifacts
        ---------------------------------------------------

        DELETE FROM Tmp_InstrumentUsage WHERE Duration = 0 AND Interval = 0;

        ---------------------------------------------------
        -- Add interval to duration for normal datasets
        ---------------------------------------------------

        UPDATE Tmp_InstrumentUsage U
        SET Duration = U.Duration + U.Interval,
            Interval = 0
        WHERE U.Type = 'Dataset' AND U.Normal > 0;

        ---------------------------------------------------
        -- Uncomment to debug
        --
        -- SELECT * FROM Tmp_InstrumentUsage ORDER BY Start
        -- SELECT * FROM Tmp_ApportionedIntervals ORDER BY Start
        -- SELECT * FROM Tmp_LongIntervals
        ---------------------------------------------------

        If _outputFormat = 'debug3' Then

            RAISE INFO '';
            RAISE INFO '%', _infoHeadInstUsage;
            RAISE INFO '%', _infoHeadSeparatorInstUsage;

            FOR _previewData IN
                SELECT U.Dataset_ID,
                       U.Type,
                       public.timestamp_text(U.Start) AS Start,
                       U.Duration,
                       U.Interval,
                       U.Proposal,
                       U.Usage,
                       U.UsageID,
                       U.Normal,
                       U.Comment,
                       U.Users,
                       U.Operator
                FROM Tmp_InstrumentUsage U
                ORDER BY U.Start
            LOOP
                _infoData := format(_formatSpecifierInstUsage,
                                    _previewData.Dataset_ID,
                                    _previewData.Type,
                                    _previewData.Start,
                                    _previewData.Duration,
                                    _previewData.Interval,
                                    _previewData.Proposal,
                                    _previewData.Usage,
                                    _previewData.UsageID,
                                    _previewData.Normal,
                                    _previewData.Comment,
                                    _previewData.Users,
                                    _previewData.Operator
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

        ---------------------------------------------------
        -- Provide output report according to mode
        ---------------------------------------------------

        If _eusInstrumentId = 0 Then
            -- Determine the EMSL instrument ID for this instrument (will be null if not an EMSL tracked instrument)
            -- Make sure instrument name is properly capitalized

            SELECT InstName.instrument, InstMapping.eus_instrument_id
            INTO _actualInstrument, _eusInstrumentId
            FROM t_instrument_name AS InstName
                 LEFT OUTER JOIN t_emsl_dms_instrument_mapping AS InstMapping
                   ON InstName.instrument_id = InstMapping.dms_instrument_id
            WHERE InstName.instrument = _instrument::citext;

            If Not FOUND Then
                RAISE WARNING 'Instrument % not found in t_instrument_name; this is unexpected', _instrument;
            Else
                _instrument := _actualInstrument;
            End If;

        Else
            -- Determine the DMS instrument name for this EUSInstrumentID
            -- Preferably choose the first active instrument, sorted alphabetically by name (e.g., so that '12T_FTICR_P' is selected instead of '12T_FTICR_P_Imaging'

            SELECT InstName.instrument
            INTO _instrument
            FROM t_instrument_name AS InstName
                 INNER JOIN t_emsl_dms_instrument_mapping AS InstMapping
                   ON InstName.instrument_id = InstMapping.dms_instrument_id
            WHERE InstMapping.eus_instrument_id = _eusInstrumentID
            ORDER BY CASE WHEN InstName.status = 'Active' THEN 0
                          WHEN InstName.status = 'Offline' THEN 1
                          ELSE 2
                     END,
                 InstName.instrument
            LIMIT 1;

            If Not FOUND Then
                RAISE WARNING 'EUS Instrument ID % not found in t_instrument_name and t_emsl_dms_instrument_mapping; this is unexpected', _eusInstrumentID;
            End If;

        End If;

        If _outputFormat = 'report' Then
            ---------------------------------------------------
            -- Return results as a report
            ---------------------------------------------------

            -- Get user lists for datasets
            UPDATE Tmp_InstrumentUsage IU
            SET Users = '',
                Operator = ''
            WHERE IU.Type = 'Dataset';

            UPDATE Tmp_InstrumentUsage IU
            SET Operator = EU.person_id
            FROM t_dataset AS DS
                 INNER JOIN t_users AS U
                   ON DS.operator_username = U.username
                 INNER JOIN t_eus_users AS EU
                   ON U.hid = EU.hid
            WHERE IU.dataset_id = DS.dataset_id AND
                  IU.Type = 'dataset';

            -- Get operator user ID for datasets
            UPDATE Tmp_InstrumentUsage IU
            SET Users = public.get_requested_run_eus_users_list(RR.request_id, 'I')
            FROM t_requested_run RR
            WHERE IU.Type = 'Dataset' AND
                  IU.dataset_id = RR.dataset_id;

            -- Get operator user ID for ONSITE, REMOTE, and RESOURCE_OWNER intervals
            UPDATE Tmp_InstrumentUsage IU
            SET Operator = EU.person_id
            FROM t_run_interval I
                 INNER JOIN t_users AS U
                   ON I.entered_by = U.username
                 INNER JOIN t_eus_users AS EU
                   ON U.hid = EU.hid
            WHERE I.dataset_id = IU.Dataset_ID AND
                  IU.Type = 'interval' AND
                  IU.Usage In ('ONSITE', 'REMOTE', 'RESOURCE_OWNER');

            -- Output report rows

            RETURN QUERY
            SELECT _instrument::citext AS Instrument,
                   _eusInstrumentId AS EMSL_Inst_ID,
                   -- Could use this to format timestamps in the form Dec 08 2022 06:07 PM
                   -- to_char(Start, 'Mon dd yyyy hh12:mi AM') AS Start,
                   U.Start,
                   U.Type,
                   CASE WHEN U.Type = 'Interval' THEN U.Interval ELSE U.Duration END AS Minutes,
                   null::numeric AS Percentage,
                   U.Proposal,
                   U.Usage,
                   U.Users,
                   U.Operator,
                   Coalesce(U.Comment, '')::citext AS Comment,
                   _yearValue AS Year,
                   _monthValue AS Month,
                   U.Dataset_ID
             FROM Tmp_InstrumentUsage U
             ORDER BY U.Start;
        End If;

        If _outputFormat = 'details' Or _outputFormat = '' Then
            ---------------------------------------------------
            -- Return usage details
            --
            -- To match the column order returned by SQL Server procedure get_monthly_instrument_usage_report for the 'details' output format, use:
            --
            -- SELECT start, type, minutes, proposal, usage, comment, dataset_id
            -- FROM get_monthly_instrument_usage_report('lumos01', 0, '2023', '1', 'details')
            -- ORDER BY start;
            ---------------------------------------------------

            RETURN QUERY
            SELECT _instrument::citext AS Instrument,
                   _eusInstrumentId AS EMSL_Inst_ID,
                   U.Start,
                   U.Type,
                   U.Duration AS Minutes,
                   null::numeric AS Percentage,
                   U.Proposal,
                   U.Usage,
                   U.Users,
                   U.Operator,
                   Coalesce(U.Comment, '')::citext AS Comment,
                   _yearValue AS Year,
                   _monthValue AS Month ,
                   U.Dataset_ID
            FROM Tmp_InstrumentUsage U
            ORDER BY U.Start;
        End If;

        If _outputFormat = 'rollup' Then
            ---------------------------------------------------
            -- Rollup by type, category, and proposal
            --
            -- To match the column order returned by SQL Server procedure get_monthly_instrument_usage_report for the 'rollup' output format, use:
            --
            -- SELECT type, minutes, percentage, usage, proposal
            -- FROM get_monthly_instrument_usage_report('lumos01', 0, '2023', '1', 'rollup')
            -- ORDER BY usage, proposal;
            ---------------------------------------------------

            -- Compute percentage values:

            RETURN QUERY
            SELECT _instrument::citext AS Instrument,
                   _eusInstrumentId AS EMSL_Inst_ID,
                   SumQ.Start,
                   SumQ.Type,
                   SumQ.Minutes::int,
                   Round(SumQ.Minutes::numeric / _minutesInMonth * 100.0, 1) AS Percentage,
                   SumQ.Proposal,
                   SumQ.Usage,
                   ''::citext AS Users,
                   ''::citext AS Operator,
                   ''::citext AS Comment,
                   _yearValue AS Year,
                   _monthValue AS Month ,
                   0 AS Dataset_ID
            FROM (SELECT MIN(U.Start) AS Start,
                         U.Type,
                         SUM(CASE
                                 WHEN U.Type = 'Interval' THEN U.Interval
                                 ELSE U.Duration
                             END) AS Minutes,
                         U.Proposal,
                         U.Usage
                  FROM Tmp_InstrumentUsage U
                  GROUP BY U.Type, U.Usage, U.Proposal
                 ) SumQ
            ORDER BY SumQ.Type, SumQ.Usage, SumQ.Proposal;

        End If;

        If _outputFormat = 'check' Then
            ---------------------------------------------------
            -- Check grand totals against available
            ---------------------------------------------------

            SELECT MIN(U.Start) AS Start,
                   SUM(U.Duration),
                   SUM(U.Interval),
                   (SUM(U.Duration + U.Interval))::numeric / _minutesInMonth * 100.0
            INTO _startMin, _durationSum, _intervalSum, _percentInUse
            FROM Tmp_InstrumentUsage U;

            RAISE INFO '';
            RAISE INFO 'Available minutes in month: %', _minutesInMonth;
            RAISE INFO 'Minutes in use (duration):  %', _durationSum;
            RAISE INFO 'Interval sum:               %', _intervalSum;
            RAISE INFO 'Duration plus interval sum: %', _durationSum + _intervalSum;
            RAISE INFO '(Duration + Interval) / minutes_in_month: %', format('%s%%', Round(_percentInUse, 1));

            RETURN QUERY
            SELECT _instrument::citext AS Instrument,
                   _eusInstrumentId AS EMSL_Inst_ID,
                   _startMin AS Start,
                   'Check'::citext AS Type,
                   _durationSum + _intervalSum AS Minutes,
                   Round(_percentInUse, 1) AS Percentage,
                   ''::citext AS Proposal,
                   format('Duration: %s, Interval: %s, total: %s',
                               _durationSum,
                               _intervalSum,
                               _durationSum + _intervalSum)::citext AS Usage,
                   ''::citext AS Users,
                   ''::citext AS Operator,
                   ''::citext AS Comment,
                   _yearValue AS Year,
                   _monthValue AS Month,
                   0 AS Dataset_ID;

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

    DROP TABLE IF EXISTS Tmp_InstrumentUsage;
    DROP TABLE IF EXISTS Tmp_LongIntervals;
    DROP TABLE IF EXISTS Tmp_ApportionedIntervals;
END
$$;


ALTER FUNCTION public.get_monthly_instrument_usage_report(_instrument text, _eusinstrumentid integer, _year text, _month text, _outputformat text) OWNER TO d3l243;

