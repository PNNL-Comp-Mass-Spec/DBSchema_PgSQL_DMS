--
CREATE OR REPLACE FUNCTION public.get_monthly_instrument_usage_report
(
    _instrument text,
    _eusInstrumentId int = 0,
    _year text,
    _month text,
    _outputFormat text = 'details'
)
RETURNS TABLE (
    Instrument text,
    EMSL_Inst_ID int,
    Start timestamp,
    Type citext,
    Minutes int,
    Percentage numeric,
    Usage citext,
    Proposal text,
    Users text,
    Operator text,
    Comment text,
    Year int,
    Month int,
    Dataset_ID int
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Create a monthly usage report for given instrument, year, and month
**
**  Arguments:
**    _eusInstrumentId   EMSL instrument ID to process; use this to process instruments like the 12T or the 15T where there are two instrument entries in DMS, yet they both map to the same EUS_Instrument_ID
**    _outputFormat      'report', 'details', 'rollup', 'check', 'debug1', 'debug2', 'debug3'
**
**  Auth:   grk
**  Date:   03/06/2012
**          03/06/2012 grk - Rename _mode to _outputFormat
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _logErrors boolean := false;
    _monthValue Int;
    _yearValue Int;
    _processByEUS boolean := false;
    _currentMonthStart timestamp;
    _nextMonth timestamp;
    _daysInMonth int;
    _minutesInMonth int;

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

    _instrument := Coalesce(_instrument, '');
    _eusInstrumentId := Coalesce(_eusInstrumentId, 0);
    _outputFormat := Lower(Coalesce(_outputFormat, ''));

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

        If Not _outputFormat In ('', 'report', 'details', 'rollup', 'check', 'debug1', 'debug2', 'debug3') Then
            RAISE EXCEPTION 'Invalid output format; should be report, details, rollup, or check';
        End If;

        If Not _processByEUS Then
            -- Auto switch to _eusInstrumentId if needed
            -- Look for EUS Instruments mapped to two or more DMS instruments

            SELECT InstMapping.eus_instrument_id
            INTO _eusInstrumentId
            FROM t_instrument_name InstName
                 INNER JOIN t_emsl_dms_instrument_mapping InstMapping
                   ON InstName.instrument_id = InstMapping.dms_instrument_id
                 INNER JOIN ( SELECT eus_instrument_id
                              FROM t_instrument_name InstName
                                   INNER JOIN t_emsl_dms_instrument_mapping InstMapping
                                     ON InstName.instrument_id = InstMapping.dms_instrument_id
                              GROUP BY eus_instrument_id
                              HAVING COUNT(InstMapping.dms_instrument_id) > 1 ) LookupQ
                   ON InstMapping.eus_instrument_id = LookupQ.eus_instrument_id
            WHERE InstName.instrument = _instrument;

            If FOUND Then
                _processByEUS := true;
            End If;

        End If;

        ---------------------------------------------------
        -- Get maximum time available in month
        ---------------------------------------------------

        _currentMonthStart := make_date(_year, _month, 1)::timestamp;
        _nextMonth := _currentMonthStart + Interval '1 month';  -- Beginning of the next month after _currentMonthStart

        _daysInMonth := Extract(day FROM _nextMonth - _currentMonthStart);
        _minutesInMonth := _daysInMonth * 1440;

        _logErrors := true;

        ---------------------------------------------------
        -- Create temporary table to contain report data
        -- and populate with datasets in for the specified
        -- instrument and reporting month
        -- (the UDF returns intervals adjusted to monthly boundaries)
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_InstrumentUsage (
            Dataset_ID int,
            Type citext,
            Start timestamp,
            Duration int,
            Interval int,
            Proposal text NULL,
            Usage citext NULL,
            UsageID int NULL,
            Normal int NULL,            -- 1 if a normal interval after a dataset (less than 180 minutes); 0 if a long interval after a dataset
            Comment text NULL,
            Users text NULL,
            Operator text NULL
        );

        If _instrument = '' AND _eusInstrumentId = 0 Then
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
            SELECT ''::citext As Instrument,
                   0 As EMSL_Inst_ID,
                   Start,
                   Type,
                   Duration As Minutes,
                   null::numeric As Percentage,
                   Usage,
                   Proposal,
                   Users,
                   Operator,
                   Comment,
                   _year As Year,
                   _month As Month ,
                   Dataset_ID
            FROM Tmp_InstrumentUsage;

            DROP TABLE Tmp_InstrumentUsage;

            RETURN;
        End If;

        If _processByEUS Then
            INSERT INTO Tmp_InstrumentUsage (
                dataset_id,
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
                   GRTMI.Time_Start AS Start,
                   GRTMI.Duration,
                   Coalesce(GRTMI.INTERVAL, 0) AS Interval,
                   Coalesce(RR.eus_proposal_id, '') AS Proposal,
                   RR.eus_usage_type_id AS UsageID,
                   EUT.eus_usage_type AS Usage,
                   1
            FROM get_run_tracking_monthly_info_by_id ( _eusInstrumentId, _year, _month, '' ) AS GRTMI
                 LEFT OUTER JOIN t_requested_run AS RR
                   ON GRTMI.id = RR.dataset_id
                 INNER JOIN t_eus_usage_type EUT
                   ON RR.eus_usage_type_id = EUT.eus_usage_type_id;

        Else

            INSERT INTO Tmp_InstrumentUsage (
                dataset_id,
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
                   GRTMI.Time_Start AS Start,
                   GRTMI.Duration,
                   Coalesce(GRTMI.INTERVAL, 0) AS Interval,
                   Coalesce(RR.eus_proposal_id, '') AS Proposal,
                   RR.eus_usage_type_id AS UsageID,
                   EUT.eus_usage_type AS Usage,
                   1
            FROM get_run_tracking_monthly_info ( 'Lumos03',2023, 1, '' ) AS GRTMI
                 LEFT OUTER JOIN t_requested_run AS RR
                   ON GRTMI.id = RR.dataset_id
                 INNER JOIN t_eus_usage_type EUT
                   ON RR.eus_usage_type_id = EUT.eus_usage_type_id;

        End If;

        ---------------------------------------------------
        -- Pull comments from datasets
        --
        -- The Common Table Expression (CTE) is used to create a cleaned up comment that removes
        -- text of the form Auto-switched dataset type from HMS-MSn to HMS-HCD-HMSn on 2012-01-01
        ---------------------------------------------------

        WITH DSCommentClean (dataset_id, comment)
        AS ( SELECT Dataset_ID, REPLACE(Comment, TextToRemove, '') AS Comment
             FROM ( SELECT dataset_id, comment,
                           SUBSTRING(comment, AutoSwitchIndex, AutoSwitchIndex + AutoSwitchIndexEnd) AS TextToRemove
                    FROM ( SELECT dataset_id, comment, AutoSwitchIndex,
                                  PATINDEX('%"0-9""0-9""0-9""0-9"-"0-9""0-9"-"0-9""0-9"%', AutoSwitchTextPortion) + 10 AS AutoSwitchIndexEnd
                            FROM ( SELECT dataset_id, comment, AutoSwitchIndex,
                                          SUBSTRING(comment, AutoSwitchIndex, 200) AS AutoSwitchTextPortion
                                    FROM ( SELECT DS.dataset_id, comment,
                                                  PATINDEX('%Auto-switched dataset type from%to%on "0-9""0-9""0-9""0-9"-"0-9""0-9"-"0-9""0-9"%', comment) AS AutoSwitchIndex
                                            FROM t_dataset DS INNER JOIN
                                                 Tmp_InstrumentUsage ON DS.dataset_id = Tmp_InstrumentUsage.dataset_id
                                          ) FilterQ
                                    WHERE AutoSwitchIndex > 0
                                  ) FilterQ2
                           ) FilterQ3
                    ) FilterQ4
          )
        UPDATE Tmp_InstrumentUsage
        SET comment = Coalesce(DSCommentClean.comment, Coalesce(DS.comment, ''))
        FROM t_dataset AS DS
             LEFT OUTER JOIN
               DSCommentClean ON DSCommentClean.dataset_id = Tmp_InstrumentUsage.dataset_id;
        WHERE DS.Dataset_ID = Tmp_InstrumentUsage.Dataset_ID;

        ---------------------------------------------------
        -- Make a temp table to work with long intervals
        -- and populate it with long intervals for the datasets
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
            Breakdown,  -- Holds usage description, from t_run_interval.comment
            Comment
        )
        SELECT TRI.interval_id,     -- interval_id is the dataset_id of the dataset that was acquired just before a given long interval
               TRI.start,
               TRI.usage,           -- Examples: '<u Maintenance="100" />' or '<u UserOnsite="100" Proposal="60594" PropUser="60420" />'  or '<u User="100" Proposal="51667" PropUser="48542" />'
               TRI.comment          -- Examples: 'Maintenance[100%]'       or 'UserOnsite[100%], Proposal[60594], PropUser[60420]'        or 'User[100%], Proposal[51667], PropUser[48542]'
        FROM t_run_interval TRI
             INNER JOIN Tmp_InstrumentUsage
               ON TRI.interval_id = Tmp_InstrumentUsage.Dataset_ID;

        ---------------------------------------------------
        -- Mark datasets in temp report table
        -- that have long intervals
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
        -- Extract long interval apportionments from XML
        -- and use to save apportioned intervals to the temp table
        -- Example XML in column Breakdown
        --   <u Maintenance="100" />
        --   <u User="100" Proposal="35092" />
        --   <u StaffNotAvailable="50" OtherNotAvailable="50" />
        --   <u CapDev="100" />
        --   <u Broken="100" />
        ---------------------------------------------------

        INSERT INTO Tmp_ApportionedIntervals (Dataset_ID, Start, Interval, Proposal, Usage, Comment)
        SELECT
            Tmp_LongIntervals.Dataset_ID,
            Tmp_LongIntervals.Start,
            public.try_cast((xpath('//u/@Broken', BreakDown))[1]::text, 0.0) * Tmp_InstrumentUsage.Interval / 100 AS Interval,
            '' AS Proposal,
            'BROKEN' AS USAGE,
            Tmp_LongIntervals.Comment
        FROM Tmp_LongIntervals
        INNER JOIN Tmp_InstrumentUsage ON Tmp_InstrumentUsage.Dataset_ID = Tmp_LongIntervals.Dataset_ID;

        INSERT INTO Tmp_ApportionedIntervals (Dataset_ID, Start, Interval, Proposal, Usage, Comment)
        SELECT
            Tmp_LongIntervals.Dataset_ID,
            Tmp_LongIntervals.Start,
            public.try_cast((xpath('//u/@Maintenance', BreakDown))[1]::text, 0.0) * Tmp_InstrumentUsage.Interval / 100 AS Interval,
            '' AS Proposal,
            'MAINTENANCE' AS Usage,            -- This is defined in t_emsl_instrument_usage_type
            Tmp_LongIntervals.Comment
        FROM Tmp_LongIntervals
        INNER JOIN Tmp_InstrumentUsage ON Tmp_InstrumentUsage.Dataset_ID = Tmp_LongIntervals.Dataset_ID;

        INSERT INTO Tmp_ApportionedIntervals (Dataset_ID, Start, Interval, Proposal, Usage, Comment)
        SELECT
            Tmp_LongIntervals.Dataset_ID,
            Tmp_LongIntervals.Start,
            public.try_cast((xpath('//u/@OtherNotAvailable', BreakDown))[1]::text, 0.0) * Tmp_InstrumentUsage.Interval / 100 AS Interval,
            '' AS Proposal,
            'UNAVAILABLE' AS Usage,                 -- This is defined in t_emsl_instrument_usage_type
            Tmp_LongIntervals.Comment
        FROM Tmp_LongIntervals
        INNER JOIN Tmp_InstrumentUsage ON Tmp_InstrumentUsage.Dataset_ID = Tmp_LongIntervals.Dataset_ID;

        INSERT INTO Tmp_ApportionedIntervals (Dataset_ID, Start, Interval, Proposal, Usage, Comment)
        SELECT
            Tmp_LongIntervals.Dataset_ID,
            Tmp_LongIntervals.Start,
            public.try_cast((xpath('//u/@StaffNotAvailable', BreakDown))[1]::text, 0.0) * Tmp_InstrumentUsage.Interval / 100 AS Interval,
            '' AS Proposal,
            'UNAVAIL_STAFF' AS Usage,               -- This is defined in t_emsl_instrument_usage_type
            Tmp_LongIntervals.Comment
        FROM Tmp_LongIntervals
        INNER JOIN Tmp_InstrumentUsage ON Tmp_InstrumentUsage.Dataset_ID = Tmp_LongIntervals.Dataset_ID;

        INSERT INTO Tmp_ApportionedIntervals (Dataset_ID, Start, Interval, Operator, Proposal, Usage, Comment)
        SELECT
            Tmp_LongIntervals.Dataset_ID,
            Tmp_LongIntervals.Start,
            public.try_cast((xpath('//u/@CapDev', BreakDown))[1]::text, 0.0) * Tmp_InstrumentUsage.Interval / 100 AS Interval,
            (xpath('//u/@Operator', BreakDown))[1]::text AS Operator,
            '' AS Proposal,
            'CAP_DEV' AS Usage,                     -- This is defined in t_emsl_instrument_usage_type
            Tmp_LongIntervals.Comment
        FROM Tmp_LongIntervals
        INNER JOIN Tmp_InstrumentUsage ON Tmp_InstrumentUsage.Dataset_ID = Tmp_LongIntervals.Dataset_ID;

        INSERT INTO Tmp_ApportionedIntervals (Dataset_ID, Start, Interval, Operator, Proposal, Usage, Comment)
        SELECT
            Tmp_LongIntervals.Dataset_ID,
            Tmp_LongIntervals.Start,
            public.try_cast((xpath('//u/@ResourceOwner', BreakDown))[1]::text, 0.0) * Tmp_InstrumentUsage.Interval / 100 AS Interval,
            (xpath('//u/@Operator', BreakDown))[1]::text AS Operator,
            '' AS Proposal,
            'RESOURCE_OWNER' AS Usage,              -- This is defined in t_emsl_instrument_usage_type
            Tmp_LongIntervals.Comment
        FROM Tmp_LongIntervals
        INNER JOIN Tmp_InstrumentUsage ON Tmp_InstrumentUsage.Dataset_ID = Tmp_LongIntervals.Dataset_ID;

        INSERT INTO Tmp_ApportionedIntervals (Dataset_ID, Start, Interval, Proposal, Usage, Comment)
        SELECT
            Tmp_LongIntervals.Dataset_ID,
            Tmp_LongIntervals.Start,
            public.try_cast((xpath('//u/@InstrumentAvailable', BreakDown))[1]::text, 0.0) * Tmp_InstrumentUsage.Interval / 100 AS Interval,
            '' AS Proposal,
            'AVAILABLE' AS Usage,                   -- This is defined in t_emsl_instrument_usage_type
            Tmp_LongIntervals.Comment
        FROM Tmp_LongIntervals
        INNER JOIN Tmp_InstrumentUsage ON Tmp_InstrumentUsage.Dataset_ID = Tmp_LongIntervals.Dataset_ID;

        INSERT INTO Tmp_ApportionedIntervals (Dataset_ID, Start, Interval, Proposal, Users, Usage, Comment)
        SELECT
            Tmp_LongIntervals.Dataset_ID,
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
        INNER JOIN Tmp_InstrumentUsage ON Tmp_InstrumentUsage.Dataset_ID = Tmp_LongIntervals.Dataset_ID;

        ---------------------------------------------------
        -- Get rid of meaningless apportioned long intervals
        ---------------------------------------------------

        DELETE FROM Tmp_ApportionedIntervals WHERE Interval = 0;

        If _outputFormat = 'debug1' Then

            RAISE INFO '';

            _formatSpecifier := '%-10s %-20s %-10s %-10s %-15s %-20s';

            _infoHead := format(_formatSpecifier,
                                'Dataset_ID',
                                'Start',
                                'Interval',
                                'Proposal',
                                'Usage',
                                'Comment'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '----------',
                                         '--------------------',
                                         '----------',
                                         '----------',
                                         '---------------',
                                         '--------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Dataset_ID,
                       public.timestamp_text(Start) AS Start,
                       Interval,
                       Proposal,
                       Usage,
                       Comment
                FROM Tmp_ApportionedIntervals
                ORDER BY Start
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Dataset_ID,
                                    _previewData.Start,
                                    _previewData.Interval,
                                    _previewData.Proposal,
                                    _previewData.Usage,
                                    _previewData.Comment
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

        ---------------------------------------------------
        -- Clean up unecessary comments
        ---------------------------------------------------

        UPDATE Tmp_ApportionedIntervals
        SET Comment = ''
        WHERE Usage In ('CAP_DEV', 'ONSITE', 'REMOTE');

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
        SELECT
            Dataset_ID,
            'Interval' AS Type,
            Start,
            0 AS Duration,
            Interval,
            Proposal,
            Usage,
            Comment,
            Users,
            Operator
        FROM Tmp_ApportionedIntervals

        If _outputFormat Like 'debug%' Then

            _formatSpecifierInstUsage := '%-10s %-8s %-20s %-8s %-8s %-8s %-11s %-25s %-15s %-8s';

            _infoHeadInstUsage := format(_formatSpecifierInstUsage,
                                         'Dataset_ID',
                                         'Type',
                                         'Start',
                                         'Duration',
                                         'Interval',
                                         'Proposal',
                                         'Usage',
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
                SELECT Dataset_ID,
                       Type,
                       public.timestamp_text(Start) As Start,
                       Duration,
                       Interval,
                       Proposal,
                       Usage,
                       Comment,
                       Users,
                       Operator
                FROM Tmp_InstrumentUsage
                ORDER BY Start
            LOOP
                _infoData := format(_formatSpecifierInstUsage,
                                    _previewData.Dataset_ID,
                                    _previewData.Type,
                                    _previewData.Start,
                                    _previewData.Duration,
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
        -- Zero interval values for datasets with long intervals
        ---------------------------------------------------

        UPDATE Tmp_InstrumentUsage
        SET Interval = 0
        WHERE Type = 'Dataset' AND Normal = 0;

        ---------------------------------------------------
        -- Translate remaining DMS usage categories
        -- to EMSL usage categories
        ---------------------------------------------------

        UPDATE Tmp_InstrumentUsage
        SET Usage = 'ONSITE'
        WHERE Usage In ('USER', 'USER_ONSITE');

        UPDATE Tmp_InstrumentUsage
        SET Usage = 'REMOTE'
        WHERE Usage = 'USER_REMOTE';

        -- Starting in FY 24, Usage can also be 'RESOURCE_OWNER'

        ---------------------------------------------------
        -- Remove artifacts
        ---------------------------------------------------

        DELETE FROM Tmp_InstrumentUsage WHERE Duration = 0 AND Interval = 0;

        ---------------------------------------------------
        -- Add interval to duration for normal datasets
        ---------------------------------------------------

        UPDATE Tmp_InstrumentUsage
        SET Duration = Duration + Interval,
            Interval = 0
        WHERE Type = 'Dataset' AND Normal > 0;

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
                SELECT Dataset_ID,
                       Type,
                       public.timestamp_text(Start) As Start,
                       Duration,
                       Interval,
                       Proposal,
                       Usage,
                       Comment,
                       Users,
                       Operator
                FROM Tmp_InstrumentUsage
                ORDER BY Start
            LOOP
                _infoData := format(_formatSpecifierInstUsage,
                                    _previewData.Dataset_ID,
                                    _previewData.Type,
                                    _previewData.Start,
                                    _previewData.Duration,
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
        -- Provide output report according to mode
        ---------------------------------------------------

        If _eusInstrumentId = 0 Then
            -- Look up EMSL instrument ID for this instrument (will be null if not an EMSL tracked instrument)
            SELECT InstMapping.eus_instrument_id
            INTO _eusInstrumentId
            FROM t_instrument_name AS InstName
                 LEFT OUTER JOIN t_emsl_dms_instrument_mapping AS InstMapping
                   ON InstName.instrument_id = InstMapping.dms_instrument_id
            WHERE InstName.instrument = _instrument
        Else
            -- Look up DMS Instrument Name for this EUSInstrumentID
            SELECT InstName.instrument
            INTO _instrument
            FROM t_instrument_name AS InstName
                 INNER JOIN t_emsl_dms_instrument_mapping AS InstMapping
                   ON InstName.instrument_id = InstMapping.dms_instrument_id
            WHERE InstMapping.eus_instrument_id = _eusInstrumentID
            ORDER BY InstName.instrument
            LIMIT 1;
        End If;

        If _outputFormat = 'report' Then
            ---------------------------------------------------
            -- Return results as a report
            ---------------------------------------------------

            -- Get user lists for datasets
            UPDATE Tmp_InstrumentUsage
            SET Users = '',
                Operator = ''
            WHERE Tmp_InstrumentUsage.Type = 'Dataset'

            UPDATE Tmp_InstrumentUsage
            SET Operator = TEU.PERSON_ID
            FROM t_dataset AS TD
                 INNER JOIN t_users AS TU
                   ON TD.operator_username = TU.username
                 INNER JOIN t_eus_users AS TEU
                   ON TU.hid = TEU.hid
            WHERE Tmp_InstrumentUsage.dataset_id = TD.dataset_id AND
                  Tmp_InstrumentUsage.Type = 'dataset';

            -- Get operator user ID for datasets
            UPDATE Tmp_InstrumentUsage
            SET Users = get_requested_run_eus_users_list(RR.request_id, 'I')
            FROM t_requested_run RR
            WHERE Tmp_InstrumentUsage.Type = 'Dataset' AND
                  Tmp_InstrumentUsage.dataset_id = RR.dataset_id;

            -- Get operator user ID for ONSITE, REMOTE, and RESOURCE_OWNER intervals
            UPDATE Tmp_InstrumentUsage
            SET Operator = TEU.PERSON_ID
            FROM t_run_interval TRI
                 INNER JOIN t_users AS TU
                   ON TRI.entered_by = TU.username
                 INNER JOIN t_eus_users AS TEU
                   ON TU.hid = TEU.hid
            WHERE TRI.interval_id = Tmp_InstrumentUsage.Dataset_ID AND
                  Tmp_InstrumentUsage.Type = 'interval' AND
                  Tmp_InstrumentUsage.Usage In ('ONSITE', 'REMOTE', 'RESOURCE_OWNER');

            -- Output report rows
            --
            RETURN QUERY
            SELECT
                _instrument::citext AS Instrument,
                _eusInstrumentId::citext AS EMSL_Inst_ID,
                -- Could use this to format timestamps in the form Dec 08 2022 06:07 PM
                -- to_char(Start, 'Mon dd yyyy hh12:mi AM') AS Start,
                Start,
                Type,
                CASE WHEN Type = 'Interval' THEN Interval ELSE Duration END AS Minutes,
                null::numeric As Percentage,
                Usage,
                Proposal,
                Users,
                Operator,
                Coalesce(Comment, '') AS Comment,
                _year AS Year,
                _month AS Month,
                Tmp_InstrumentUsage.Dataset_ID
             FROM Tmp_InstrumentUsage
             ORDER BY Start;
        End If;

        If _outputFormat = 'details' OR _outputFormat = '' -- default mode Then
            ---------------------------------------------------
            -- Return usage details
            ---------------------------------------------------

            RETURN QUERY
            SELECT _instrument::citext AS Instrument,
                   _eusInstrumentId AS EMSL_Inst_ID,
                   Start,
                   Type,
                   Duration As Minutes,
                   null::numeric As Percentage,
                   Usage,
                   Proposal,
                   Users,
                   Operator,
                   Coalesce(Comment, '') AS Comment,
                   _year As Year,
                   _month As Month ,
                   Dataset_ID
            FROM Tmp_InstrumentUsage;
            ORDER BY Start
        End If;

        If _outputFormat = 'rollup' Then
            ---------------------------------------------------
            -- Rollup by type, category, and proposal
            ---------------------------------------------------

            RETURN QUERY
            SELECT _instrument::citext AS Instrument,
                   _eusInstrumentId AS EMSL_Inst_ID,
                   Start,
                   Type,
                   Minutes,
                   null::numeric AS Percentage,
                   Usage,
                   Proposal,
                   ''::citext As Users,
                   ''::citext As Operator,
                   ''::citext As Comment,
                   _year As Year,
                   _month As Month ,
                   0 As Dataset_ID
            FROM ( SELECT MIN(Start) AS Start,
                          Type,
                          SUM(CASE
                                  WHEN Type = 'Interval' THEN Interval
                                  ELSE Duration
                              END) AS Minutes,
                          Proposal,
                          Usage
                   FROM Tmp_InstrumentUsage
                   GROUP BY Type, Usage, Proposal ) TQZ
            ORDER BY Type, Usage, Proposal;

        End If;

        If _outputFormat = 'check' Then
            ---------------------------------------------------
            -- Check grand totals against available
            ---------------------------------------------------

            SELECT
                MIN(Start) As Start,
                SUM(Duration),
                SUM(Interval),
                (SUM(Duration + Interval))::numeric / _minutesInMonth * 100.0
            INTO _startMin, _durationSum, _intervalSum, _percentInUse
            FROM Tmp_InstrumentUsage;

            RAISE INFO '';
            RAISE INFO 'Available minutes in month: %', _minutesInMonth;
            RAISE INFO 'Minutes in use (duration):  %', _durationSum;
            RAISE INFO 'Interval sum:               %', _intervalSum;
            RAISE INFO 'Duration plus interval sum: %', _durationSum + _intervalSum;
            RAISE INFO '(Duration + Interval) / minutes_in_month: %%%', _percentInUse;

            RETURN QUERY
            SELECT
                _instrument AS Instrument,
                _eusInstrumentId AS EMSL_Inst_ID,
                _startMin As Start,
                'Check'::citext AS Type,
                _durationSum + _intervalSum As Minutes,
                Round(_percentInUse, 1) As Percentage,
                format('Duration: %s, Interval: %s, total: %s',
                            _durationSum,
                            _intervalSum,
                            _durationSum + _intervalSum)::citext As Usage,
                '' As Proposal text,
                '' As Users text,
                '' As Operator text,
                '' As Comment text,
                _year As Year,
                _month As Month,
                0 As Dataset_ID;

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

COMMENT ON PROCEDURE public.get_monthly_instrument_usage_report IS 'GetMonthlyInstrumentUsageReport';
