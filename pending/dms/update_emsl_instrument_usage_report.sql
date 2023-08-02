--
CREATE OR REPLACE PROCEDURE public.update_emsl_instrument_usage_report
(
    _instrument text,
    _eusInstrumentId int,
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
**      Add entries to permanent EMSL monthly usage report (T_EMSL_Instrument_Usage_Report)
**      for given Instrument and month (as dictated via the _endDate parameter)
**
**  Arguments:
**    _instrument       Instrument name to process; leave this blank if processing by EMSL instrument ID
**    _eusInstrumentId  EMSL instrument ID to process; use this to process instruments like the 12T or the 15T where there are two instrument entries in DMS, yet they both map to the same EUS_Instrument_ID
**    _endDate          This is used to determine the target year and month; the day of the month does not really matter
**    _message          Optionally specify debug reports to show, for example '1' or '1,2,3'
**    _infoOnly         When true, preview updates
**
**  Auth:   grk
**  Date:   03/21/2012
**          03/26/2012 grk - Added code to clean up comments and pin trans-month interval starting time
**          04/09/2012 grk - Modified algorithm
**          06/08/2012 grk - Added lookup for _maxNormalInterval
**          08/30/2012 grk - Don't overwrite existing non-blank items, do auto-comment non-onsite datasets
**          10/02/2012 grk - Added debug output
**          10/06/2012 grk - Adding 'updated by' date and user
**          01/31/2013 mem - Now using Coalesce(_message, '') when copying _message to _debug
**          03/12/2014 grk - Allow null EMSL_Inst_ID in Tmp_Staging (OMCDA-1058)
**          02/23/2016 mem - Add set XACT_ABORT on
**          11/08/2016 mem - Use GetUserLoginWithoutDomain to obtain the user's network login
**          11/10/2016 mem - Pass '' to GetUserLoginWithoutDomain
**          04/10/2017 mem - Remove _day and _hour since not used
**          04/11/2017 mem - Populate columns DMS_Inst_ID and Usage_Type instead of Instrument and Usage
**                         - Add parameter _infoOnly
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**                         - Set _validateTotal to 0 when calling Parse_Usage_Text
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/02/2017 mem - Trim whitespace from the cleaned comment returned by Parse_Usage_Text
**          01/05/2017 mem - Remove LF and CR from dataset comments
**          05/03/2019 mem - Add parameter _eusInstrumentId
**          04/17/2020 mem - Use Dataset_ID instead of ID
**          01/28/2022 mem - If a long interval has 'Broken' in the comment, store 'Broken' as the comment in T_EMSL_Instrument_Usage_Report
**                         - Replace SQL server specific syntax with more generic syntax for assigning sequential values to the seq column
**          02/15/2022 mem - Define column names when previewing updates
**          03/17/2022 mem - After populating the staging table, update _instrument if required
**                         - Call procedure Update_EMSL_Instrument_Acq_Overlap_Data
**          07/15/2022 mem - Instrument operator ID is now tracked as an actual integer
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _outputFormat text := 'report';
    _maxNormalInterval int;
    _callingUser text;
    _year int;
    _month int;
    _bom timestamp              -- Beginning of the month;
    _actualInstrument text;
    _seq int;
    _cleanedComment text;
    _xml xml;
    _previewCount int;
    _deleteCount int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

    _formatSpecifierStaging text;
    _infoHeadStaging text;
    _infoHeadSeparatorStaging text;

    _formatSpecifierInstUsage text;
    _infoHeadInstUsage text;
    _infoHeadSeparatorInstUsage text;

    _formatSpecifierUpdateComment text;
    _infoHeadUpdateComment text;
    _infoHeadSeparatorUpdateComment text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;

BEGIN
    _message := Trim(Coalesce(_message, ''));
    _returnCode := '';

    _instrument := Coalesce(_instrument, '');
    _eusInstrumentId := Coalesce(_eusInstrumentId, 0);

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

    ------------------------------------------------------
    -- Create a table for tracking debug reports to show
    ------------------------------------------------------

    CREATE TEMP TABLE Tmp_DebugReports (
        Debug_ID int
    )

    If _message <> '' Then
        ------------------------------------------------------
        -- Parse which debug reports should be shown
        ------------------------------------------------------

        INSERT INTO Tmp_DebugReports (Debug_ID)
        SELECT Value
        FROM public.parse_delimited_integer_list(_message, ',')
        ORDER BY Value;

        If Not Exists (Select * from Tmp_DebugReports) Then
            _message := 'To see debug reports, _message must have a comma-separated list of integers';
            RAISE WARNING '%', _message;
        End If;
    End If;

    _message := '';
    _returnCode := '';

    BEGIN
        _maxNormalInterval := get_long_interval_threshold();

        _callingUser := get_user_login_without_domain('');

        ---------------------------------------------------
        -- Figure out our time context
        ---------------------------------------------------

        _year  := date_part('year',  _endDate);
        _month := date_part('month', _endDate);

        _bom := make_date(_year, _month, 1)::timestamp;

        ---------------------------------------------------
        -- Temporary table for staging report rows
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_Staging (
            Staging_ID int PRIMARY KEY IDENTITY not null,
            emsl_inst_id int NULL,
            instrument text,
            dms_inst_id int NULL,
            type citext,
            start timestamp,
            minutes int,
            usage citext NULL,
            proposal text NULL,
            users text,
            operator text,              -- Could be an empty string or an operator ID
            comment text NULL,
            year int,
            month int,
            dataset_id int,
            usage_type_id int NULL,     -- Usage type ID, from t_emsl_instrument_usage_type
            Operator_ID int NULL,       -- Value of 'operator' if an integer, otherwise null
            Mark int NULL,              -- 0 if adding a new row to t_emsl_instrument_usage_report, 1 if matches an existing row that will be updated
            seq int NULL
        );

        CREATE INDEX IX_STAGING On Tmp_Staging (Seq);

        ---------------------------------------------------
        -- Populate staging table with report rows for the instrument
        -- (specified by _instrument or _eusInstrumentId)
        -- for the target month (based on _endDate)
        ---------------------------------------------------

        INSERT INTO Tmp_Staging
                ( Instrument,
                  EMSL_Inst_ID,
                  Start,
                  Type,
                  Minutes,
                  Usage,
                  Proposal,
                  Users,
                  Operator,
                  Comment,
                  Year,
                  Month,
                  Dataset_ID
                )
        SELECT  Instrument,
                EMSL_Inst_ID,
                Start,
                Type,
                Minutes,
                -- Skip: Percentage,
                Usage,
                Proposal,
                Users,
                Operator,
                Comment,
                Year,
                Month,
                Dataset_ID
        FROM get_monthly_instrument_usage_report (
                        _instrument,
                        _eusInstrumentId,
                        _year,
                        _month,
                        _outputFormat);

        -- Assure that _instrument matches the data in Tmp_Staging
        -- It could be an empty string if this procedure was called with _eusInstrumentId
        -- It may also have been changed if it corresponds to a DMS instrument that shares and EUS instrument ID with another DMS instrument

        SELECT Instrument
        INTO _actualInstrument
        FROM Tmp_Staging
        WHERE Instrument <> ''
        LIMIT 1;

        _actualInstrument := Coalesce(_actualInstrument, '');

        If _actualInstrument <> '' Then
            If _instrument <> _actualInstrument And
               (_infoOnly Or Exists (Select * from Tmp_DebugReports)) Then

                RAISE INFO '%', 'Setting _instrument to _actualInstrument';

            End If;

            _instrument := _actualInstrument;
        End If;

        -- Populate the Operator_ID field and assure that the comment field does not have LF or CR
        UPDATE Tmp_Staging
        SET Operator_ID = public.try_cast(Operator, null::int),
            Comment = Replace(Replace(Comment, chr(10), ' '), chr(13), ' ');

        ---------------------------------------------------
        -- Populate columns DMS_Inst_ID and Usage_Type
        ---------------------------------------------------

        UPDATE Tmp_Staging
        SET DMS_Inst_ID = InstName.Instrument_ID
        FROM t_instrument_name InstName
        WHERE Tmp_Staging.instrument = InstName.instrument;

        UPDATE Tmp_Staging
        SET usage_type_id = InstUsageType.usage_type_id
        FROM t_emsl_instrument_usage_type InstUsageType
        WHERE Tmp_Staging.Usage = InstUsageType.usage_type;

        _formatSpecifierStaging := '%-10s %-12s %-25s %-11s %-10s %-20s %-7s %-15s %-10s %-10s %-10s %-20s %-4s %-5s %-10s %-13s %-11s %-4s %-8s';

        _infoHeadStaging := format(_formatSpecifierStaging,
                                   'Staging_ID',
                                   'EMSL_Inst_ID',
                                   'Instrument',
                                   'DMS_Inst_ID',
                                   'Type',
                                   'Start',
                                   'Minutes',
                                   'Usage',
                                   'Proposal',
                                   'Users',
                                   'Operator',
                                   'Comment',
                                   'Year',
                                   'Month',
                                   'Dataset_ID',
                                   'Usage_type_ID',
                                   'Operator_ID',
                                   'Mark',
                                   'Seq'
                                  );

        _infoHeadSeparatorStaging := format(_formatSpecifierStaging,
                                     '----------',
                                     '------------',
                                     '-------------------------',
                                     '-----------',
                                     '----------',
                                     '--------------------',
                                     '-------',
                                     '---------------',
                                     '----------',
                                     '----------',
                                     '----------',
                                     '--------------------',
                                     '----',
                                     '-----',
                                     '----------',
                                     '-------------',
                                     '-----------',
                                     '----',
                                     '--------'
                                    );

        If Exists (Select * from Tmp_DebugReports Where Debug_ID = 1) Then

            RAISE INFO '';
            RAISE INFO '%', _infoHeadStaging;
            RAISE INFO '%', _infoHeadSeparatorStaging;

            FOR _previewData IN
                SELECT 'Initial data' As State,
                       Staging_ID, EMSL_Inst_ID, Instrument, DMS_Inst_ID, Type,
                       public.timestamp_text(Start) As Start,
                       Minutes, Usage, Proposal, Users, Operator, Comment,
                       Year, Month, Dataset_ID, Usage_type_ID, Operator_ID, Mark, Seq
                FROM Tmp_Staging
                ORDER BY Staging_ID
            LOOP
                _infoData := format(_formatSpecifierStaging,
                                    _previewData.Staging_ID,
                                    _previewData.EMSL_Inst_ID,
                                    _previewData.Instrument,
                                    _previewData.DMS_Inst_ID,
                                    _previewData.Type,
                                    _previewData.Start,
                                    _previewData.Minutes,
                                    _previewData.Usage,
                                    _previewData.Proposal,
                                    _previewData.Users,
                                    _previewData.Operator,
                                    _previewData.Comment,
                                    _previewData.Year,
                                    _previewData.Month,
                                    _previewData.Dataset_ID,
                                    _previewData.Usage_type_ID,
                                    _previewData.Operator_ID,
                                    _previewData.Mark,
                                    _previewData.Seq

                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

        ---------------------------------------------------
        -- Mark items that are already in report
        ---------------------------------------------------

        UPDATE Tmp_Staging
        SET Mark = 1
        FROM t_emsl_instrument_usage_report TR
        WHERE Tmp_Staging.dataset_id = TR.dataset_id AND
              Tmp_Staging.type = TR.type;

        If Exists (Select * from Tmp_DebugReports Where Debug_ID = 2) Then

            RAISE INFO '';
            RAISE INFO '%', _infoHeadStaging;
            RAISE INFO '%', _infoHeadSeparatorStaging;

            FOR _previewData IN
                SELECT 'Mark set to 1' As State,
                       Staging_ID, EMSL_Inst_ID, Instrument, DMS_Inst_ID, Type,
                       public.timestamp_text(Start) As Start,
                       Minutes, Usage, Proposal, Users, Operator, Comment,
                       Year, Month, Dataset_ID, Usage_type_ID, Operator_ID, Mark, Seq
                FROM Tmp_Staging
                WHERE Mark = 1
                ORDER BY Staging_ID
            LOOP
                _infoData := format(_formatSpecifierStaging,
                                    _previewData.Staging_ID,
                                    _previewData.EMSL_Inst_ID,
                                    _previewData.Instrument,
                                    _previewData.DMS_Inst_ID,
                                    _previewData.Type,
                                    _previewData.Start,
                                    _previewData.Minutes,
                                    _previewData.Usage,
                                    _previewData.Proposal,
                                    _previewData.Users,
                                    _previewData.Operator,
                                    _previewData.Comment,
                                    _previewData.Year,
                                    _previewData.Month,
                                    _previewData.Dataset_ID,
                                    _previewData.Usage_type_ID,
                                    _previewData.Operator_ID,
                                    _previewData.Mark,
                                    _previewData.Seq

                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

        ---------------------------------------------------
        -- Add unique sequence value to new report rows
        -- In addition, set Mark to 0
        ---------------------------------------------------

        _seq := 0;

        SELECT Coalesce(MAX(seq), 0)
        INTO _seq
        FROM t_emsl_instrument_usage_report;

        -- The following update query increments _seq after updating each row
        -- This is a SQL server specific syntax
        --
        /* UPDATE Tmp_Staging
        _seq := Seq = _seq + 1,;
        Mark = 0
        FROM Tmp_Staging
        WHERE Mark IS NULL
        */

        UPDATE Tmp_Staging
        SET Seq = SourceQ.New_Seq,
            Mark = 0
        FROM (SELECT Staging_ID,
                     _seq + row_number() OVER (ORDER BY Dataset_ID, Type) AS New_Seq
              FROM Tmp_Staging
              WHERE Mark Is Null) SourceQ
        WHERE Tmp_Staging.Staging_ID = SourceQ.Staging_ID

        If Exists (Select * from Tmp_DebugReports Where Debug_ID = 3) Then


            RAISE INFO '';
            RAISE INFO '%', _infoHeadStaging;
            RAISE INFO '%', _infoHeadSeparatorStaging;

            FOR _previewData IN
                SELECT 'Mark set to 0' As State,
                       Staging_ID, EMSL_Inst_ID, Instrument, DMS_Inst_ID, Type,
                       public.timestamp_text(Start) As Start,
                       Minutes, Usage, Proposal, Users, Operator, Comment,
                       Year, Month, Dataset_ID, Usage_type_ID, Operator_ID, Mark, Seq
                FROM Tmp_Staging
                WHERE Mark = 0
                ORDER BY Staging_ID
            LOOP
                _infoData := format(_formatSpecifierStaging,
                                    _previewData.Staging_ID,
                                    _previewData.EMSL_Inst_ID,
                                    _previewData.Instrument,
                                    _previewData.DMS_Inst_ID,
                                    _previewData.Type,
                                    _previewData.Start,
                                    _previewData.Minutes,
                                    _previewData.Usage,
                                    _previewData.Proposal,
                                    _previewData.Users,
                                    _previewData.Operator,
                                    _previewData.Comment,
                                    _previewData.Year,
                                    _previewData.Month,
                                    _previewData.Dataset_ID,
                                    _previewData.Usage_type_ID,
                                    _previewData.Operator_ID,
                                    _previewData.Mark,
                                    _previewData.Seq

                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

        ---------------------------------------------------
        -- Cleanup:
        --
        -- Remove usage text from comments
        -- However, if the comment starts with 'Broken', keep that word
        ---------------------------------------------------

        FOR _seq, _cleanedComment IN
            SELECT Seq,
                   Comment
            FROM Tmp_Staging
            ORDER BY Seq
        LOOP

            If Coalesce(_cleanedComment, '') = '' Then
                CONTINUE;
            End If;

            If LTrim(_cleanedComment) Like 'Broken%' Then
                _cleanedComment := 'Broken';
            Else
                ---------------------------------------------------
                -- Parse_Usage_Text looks for special usage tags in the comment and extracts that information, returning it as XML
                --
                -- If _cleanedComment is initially 'User[100%], Proposal[49361], PropUser[50082] Extra information about interval'
                -- after calling Parse_Usage_Text, _cleanedComment will be ' Extra information about interval''
                -- and _xml will be <u User="100" Proposal="49361" PropUser="50082" />
                --
                -- If _cleanedComment only has 'User[100%], Proposal[49361], PropUser[50082]', _cleanedComment will be empty after the call to Parse_Usage_Text
                ---------------------------------------------------

                CALL public.parse_usage_text (
                                _cleanedComment => _cleanedComment,     -- Input / Output
                                _xml => _xml,                           -- Output
                                _message => _message,                   -- Output
                                _returnCode => _returnCode,             -- Output
                                _seq => _seq,
                                _showDebug => false,
                                _infoOnly => _infoOnly,
                                _validateTotal => false);
            End If;

            UPDATE Tmp_Staging
            SET Comment = Trim(_cleanedComment)
            WHERE Seq = _seq;

        END LOOP;

        If Exists (Select * from Tmp_DebugReports Where Debug_ID = 4) Then

            RAISE INFO '';
            RAISE INFO '%', _infoHeadStaging;
            RAISE INFO '%', _infoHeadSeparatorStaging;

            FOR _previewData IN
                SELECT 'Comments cleaned' As State,
                       Staging_ID, EMSL_Inst_ID, Instrument, DMS_Inst_ID, Type,
                       public.timestamp_text(Start) As Start,
                       Minutes, Usage, Proposal, Users, Operator, Comment,
                       Year, Month, Dataset_ID, Usage_type_ID, Operator_ID, Mark, Seq
                FROM Tmp_Staging
                WHERE Mark = 0
                ORDER BY Staging_ID
            LOOP
                _infoData := format(_formatSpecifierStaging,
                                    _previewData.Staging_ID,
                                    _previewData.EMSL_Inst_ID,
                                    _previewData.Instrument,
                                    _previewData.DMS_Inst_ID,
                                    _previewData.Type,
                                    _previewData.Start,
                                    _previewData.Minutes,
                                    _previewData.Usage,
                                    _previewData.Proposal,
                                    _previewData.Users,
                                    _previewData.Operator,
                                    _previewData.Comment,
                                    _previewData.Year,
                                    _previewData.Month,
                                    _previewData.Dataset_ID,
                                    _previewData.Usage_type_ID,
                                    _previewData.Operator_ID,
                                    _previewData.Mark,
                                    _previewData.Seq

                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

        ---------------------------------------------------
        -- Pin start time for month-spanning intervals
        ---------------------------------------------------

        UPDATE Tmp_Staging
        SET Start = _bom
        WHERE Type = 'Interval' AND Start < _bom

        If Exists (Select * from Tmp_DebugReports Where Debug_ID = 5) Then

            RAISE INFO '';
            RAISE INFO '%', _infoHeadStaging;
            RAISE INFO '%', _infoHeadSeparatorStaging;

            FOR _previewData IN
                SELECT 'Intervals' As State,
                       Staging_ID, EMSL_Inst_ID, Instrument, DMS_Inst_ID, Type,
                       public.timestamp_text(Start) As Start,
                       Minutes, Usage, Proposal, Users, Operator, Comment,
                       Year, Month, Dataset_ID, Usage_type_ID, Operator_ID, Mark, Seq
                FROM Tmp_Staging
                WHERE Type = 'Interval';
                ORDER BY Staging_ID
            LOOP
                _infoData := format(_formatSpecifierStaging,
                                    _previewData.Staging_ID,
                                    _previewData.EMSL_Inst_ID,
                                    _previewData.Instrument,
                                    _previewData.DMS_Inst_ID,
                                    _previewData.Type,
                                    _previewData.Start,
                                    _previewData.Minutes,
                                    _previewData.Usage,
                                    _previewData.Proposal,
                                    _previewData.Users,
                                    _previewData.Operator,
                                    _previewData.Comment,
                                    _previewData.Year,
                                    _previewData.Month,
                                    _previewData.Dataset_ID,
                                    _previewData.Usage_type_ID,
                                    _previewData.Operator_ID,
                                    _previewData.Mark,
                                    _previewData.Seq

                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

        If Exists (Select * from Tmp_DebugReports Where Debug_ID = 6) Then

            RAISE INFO '';

            _formatSpecifier := '%-20s %-10s %-15s %-13s %-15s %-8s %-4s %-5s %-50s';

            _infoHead := format(_formatSpecifier,
                                'Start',
                                'Proposal',
                                'Usage',
                                'Usage_Type_ID',
                                'Users',
                                'Operator',
                                'Year',
                                'Month',
                                'Comment'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '--------------------',
                                         '----------',
                                         '---------------',
                                         '-------------',
                                         '---------------',
                                         '--------',
                                         '----',
                                         '-----',
                                         '--------------------------------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT public.timestamp_text(Tmp_Staging.start) AS Start,
                       CASE WHEN Coalesce(InstUsage.proposal, '') = '' THEN Tmp_Staging.proposal ELSE InstUsage.proposal END AS Proposal,
                       -- Remove or update since skipped column: CASE WHEN Coalesce(InstUsage.usage_type, 0) = 0 THEN Tmp_Staging.Usage ELSE InstUsageType.usage_type END AS Usage,
                       CASE WHEN Coalesce(InstUsage.usage_type_id, 0) = 0 THEN Tmp_Staging.usage_type_id ELSE InstUsage.usage_type_id END AS Usage_Type_ID,
                       CASE WHEN Coalesce(InstUsage.users, '') = ''    THEN Tmp_Staging.users ELSE InstUsage.users END AS Users,
                       CASE WHEN InstUsage.operator Is Null            THEN Tmp_Staging.Operator_ID ELSE InstUsage.operator END AS Operator,
                       Tmp_Staging.Year,
                       Tmp_Staging.Month,
                       CASE WHEN Coalesce(InstUsage.comment, '') = '' THEN Tmp_Staging.comment ELSE InstUsage.comment END AS Comment
                FROM t_emsl_instrument_usage_report InstUsage
                     INNER JOIN Tmp_Staging
                       ON InstUsage.dataset_id = Tmp_Staging.dataset_id AND
                          InstUsage.type = Tmp_Staging.type
                     LEFT OUTER JOIN t_emsl_instrument_usage_type InstUsageType
                       ON InstUsage.usage_type_id = InstUsageType.usage_type_id
                WHERE Tmp_Staging.Mark = 1
                ORDER BY Tmp_Staging.start
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Start,
                                    _previewData.Proposal,
                                    _previewData.Usage,
                                    _previewData.Usage_Type_ID,
                                    _previewData.Users,
                                    _previewData.Operator,
                                    _previewData.Year,
                                    _previewData.Month,
                                    _previewData.Comment
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            RAISE INFO '';

            _formatSpecifier := '%-12s %-11s %-10s %-20s %-7s %-10s %-15s %-10s %-15s %-8s %-50s %-4s %-5s %-10s %-11s %-5s';

            _infoHead := format(_formatSpecifier,
                                'EMSL_Inst_ID',
                                'DMS_Inst_ID',
                                'Type',
                                'Start',
                                'Minutes',
                                'Proposal',
                                'Usage',
                                'Usage_Type',
                                'Users',
                                'Operator',
                                'Comment',
                                'Year',
                                'Month',
                                'Dataset_ID',
                                'Operator_ID',
                                'Seq'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '------------',
                                         '-----------',
                                         '----------',
                                         '--------------------',
                                         '-------',
                                         '----------',
                                         '---------------',
                                         '----------',
                                         '---------------',
                                         '--------',
                                         '--------------------------------------------------',
                                         '----',
                                         '-----',
                                         '----------',
                                         '-----------',
                                         '-----'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT EMSL_Inst_ID,
                       DMS_Inst_ID,
                       Type,
                       public.timestamp_text(Start) AS Start,
                       Minutes,
                       Proposal,
                       Usage,
                       Usage_Type,
                       Users,
                       Operator,
                       Comment,
                       Year,
                       Month,
                       Dataset_ID,
                       Operator_ID,
                       Seq
                FROM Tmp_Staging
                WHERE Mark = 0
                ORDER BY Start, Dataset_ID
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.EMSL_Inst_ID,
                                    _previewData.DMS_Inst_ID,
                                    _previewData.Type,
                                    _previewData.Start,
                                    _previewData.Minutes,
                                    _previewData.Proposal,
                                    _previewData.Usage,
                                    _previewData.Usage_Type,
                                    _previewData.Users,
                                    _previewData.Operator,
                                    _previewData.Comment,
                                    _previewData.Year,
                                    _previewData.Month,
                                    _previewData.Dataset_ID,
                                    _previewData.Operator_ID,
                                    _previewData.Seq
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

            ---------------------------------------------------
            -- Clean out any 'long intervals' that don't appear
            -- in the main interval table
            ---------------------------------------------------

            RAISE INFO '';

            _formatSpecifier := '%-12s %-10s %-10s %-20s %-7s %-10s %-13s %-15s %-8s %-50s %-4s %-5s %-10s %-5s';

            _infoHead := format(_formatSpecifier,
                                'EMSL_Inst_ID',
                                'Instrument',
                                'Type',
                                'Start',
                                'Minutes',
                                'Proposal',
                                'Usage_Type_ID',
                                'Users',
                                'Operator',
                                'Comment',
                                'Year',
                                'Month',
                                'Dataset_ID',
                                'Seq'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '------------',
                                         '----------',
                                         '----------',
                                         '--------------------',
                                         '-------',
                                         '----------',
                                         '-------------',
                                         '---------------',
                                         '--------',
                                         '--------------------------------------------------',
                                         '----',
                                         '-----',
                                         '----------',
                                         '-----'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
            SELECT InstUsage.EMSL_Inst_ID,
                   InstName.Instrument,
                   InstUsage.Type,
                   public.timestamp_text(InstUsage.Start) AS Start,
                   InstUsage.Minutes,
                   InstUsage.Proposal,
                   InstUsage.Usage_Type_ID,
                   InstUsage.Users,
                   InstUsage.Operator,
                   InstUsage.Comment,
                   InstUsage.Year,
                   InstUsage.Month,
                   InstUsage.Dataset_ID,
                   InstUsage.Seq
            FROM t_emsl_instrument_usage_report InstUsage
                 INNER JOIN t_instrument_name InstName
                   ON InstUsage.dms_inst_id = InstName.instrument_id
            WHERE type = 'interval' AND
                  InstUsage.year = _year AND
                  InstUsage.month = _month AND
                  InstName.instrument = _instrument AND
                  NOT InstUsage.dataset_id IN ( SELECT interval_id FROM t_run_interval )
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.EMSL_Inst_ID,
                                    _previewData.Instrument,
                                    _previewData.Type,
                                    _previewData.Start,
                                    _previewData.Minutes,
                                    _previewData.Proposal,
                                    _previewData.Usage_Type_ID,
                                    _previewData.Users,
                                    _previewData.Operator,
                                    _previewData.Comment,
                                    _previewData.Year,
                                    _previewData.Month,
                                    _previewData.Dataset_ID,
                                    _previewData.Seq
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

        ---------------------------------------------------
        -- Update existing values in report table from staging table
        ---------------------------------------------------

        If Not Exists (Select * from Tmp_DebugReports) Then
        -- <a>

            If Not _infoOnly Then
                UPDATE InstUsage
                SET minutes = Tmp_Staging.minutes,
                    start = Tmp_Staging.start,
                    proposal = CASE WHEN Coalesce(InstUsage.proposal, '') = '' THEN Tmp_Staging.proposal ELSE InstUsage.proposal END,
                    usage_type_id = CASE WHEN Coalesce(InstUsage.usage_type_id, 0) = 0 THEN Tmp_Staging.usage_type_id ELSE InstUsage.usage_type_id END,
                    users = CASE WHEN Coalesce(InstUsage.users, '') = ''       THEN Tmp_Staging.users ELSE InstUsage.users END,
                    operator = CASE WHEN InstUsage.operator Is Null            THEN Tmp_Staging.operator ELSE InstUsage.operator END,
                    year = Tmp_Staging.year,
                    month = Tmp_Staging.month,
                    comment = CASE WHEN Coalesce(InstUsage.comment, '') = '' THEN Tmp_Staging.comment ELSE InstUsage.comment END,
                    updated = CURRENT_TIMESTAMP,
                    updated_by = _callingUser
                FROM t_emsl_instrument_usage_report InstUsage
                     INNER JOIN Tmp_Staging
                       ON InstUsage.dataset_id = Tmp_Staging.dataset_id AND
                          InstUsage.type = Tmp_Staging.type
                WHERE Tmp_Staging.MARK = 1;

            Else

                RAISE INFO '';

                _formatSpecifier := '%-10s %-7s %-20s %-10s %-13s %-15s %-8s %-15s %-8s %-50s %-20s %-12s';

                _infoHead := format(_formatSpecifier,
                                    'Action',
                                    'Minutes',
                                    'Start',
                                    'Proposal',
                                    'Usage_Type_ID',
                                    'Users',
                                    'Operator',
                                    'Year',
                                    'Month',
                                    'Comment',
                                    'Updated',
                                    'Calling_User'
                                   );

                _infoHeadSeparator := format(_formatSpecifier,
                                             '----------',
                                             '-------',
                                             '--------------------',
                                             '----------',
                                             '-------------',
                                             '---------------',
                                             '--------',
                                             '---------------',
                                             '--------',
                                             '--------------------------------------------------',
                                             '--------------------',
                                             '------------'
                                            );

                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                _previewCount := 0;

                FOR _previewData IN
                    SELECT 'Update Row' As Action,
                            Tmp_Staging.Minutes,
                            public.timestamp_text(Tmp_Staging.Start) AS STart,
                            CASE WHEN Coalesce(InstUsage.proposal, '') = ''    THEN Tmp_Staging.proposal ELSE InstUsage.proposal END As Proposal,
                            CASE WHEN Coalesce(InstUsage.usage_type_id, 0) = 0 THEN Tmp_Staging.usage_type_id ELSE InstUsage.usage_type_id END As Usage_Type_ID,
                            CASE WHEN Coalesce(InstUsage.users, '') = ''       THEN Tmp_Staging.users ELSE InstUsage.users END As Users,
                            CASE WHEN InstUsage.operator Is Null               THEN Tmp_Staging.operator ELSE InstUsage.operator END As Operator,
                            Tmp_Staging.Year,
                            Tmp_Staging.Month,
                            CASE WHEN Coalesce(InstUsage.comment, '') = '' THEN Tmp_Staging.comment ELSE InstUsage.comment End As Comment,
                            public.timestamp_text(CURRENT_TIMESTAMP) As Updated,
                            _callingUser As Calling_User
                    FROM t_emsl_instrument_usage_report InstUsage
                            INNER JOIN Tmp_Staging
                            ON InstUsage.dataset_id = Tmp_Staging.dataset_id AND
                                InstUsage.type = Tmp_Staging.type
                    WHERE Tmp_Staging.mark = 1
                    ORDER BY Tmp_Staging.start
                LOOP
                    _infoData := format(_formatSpecifier,
                                        _previewData.Action,
                                        _previewData.Minutes,
                                        _previewData.Start,
                                        _previewData.Proposal,
                                        _previewData.Usage_Type_ID,
                                        _previewData.Users,
                                        _previewData.Operator,
                                        _previewData.Year,
                                        _previewData.Month,
                                        _previewData.Comment,
                                        _previewData.Updated,
                                        _previewData.Calling_User
                                       );

                    RAISE INFO '%', _infoData;

                    _previewCount := _previewCount + 1;
                END LOOP;

                If _previewCount > 0 Then
                    RAISE INFO 'Would update % rows in t_emsl_instrument_usage_report', _previewCount;
                End If;
            End If;

            ---------------------------------------------------
            -- Clean out any short 'long intervals'
            ---------------------------------------------------

            DELETE FROM Tmp_Staging
            WHERE Type = 'Interval' AND
                  Minutes < _maxNormalInterval;
            --
            GET DIAGNOSTICS _deleteCount = ROW_COUNT;

            If _infoOnly And _deleteCount > 0 Then
                RAISE INFO 'Deleted % short "long intervals" from Tmp_Staging', _deleteCount;
            End If;

            ---------------------------------------------------
            -- Add new values from staging table to database
            ---------------------------------------------------

            If Not _infoOnly Then
                INSERT INTO t_emsl_instrument_usage_report( emsl_inst_id, dms_inst_id, type,
                                                            start, minutes, proposal, usage_type_id,
                                                            users, operator, comment, Year, Month,
                                                            dataset_id, updated_by, seq )
                SELECT emsl_inst_id, dms_inst_id, type,
                       start, minutes, proposal, usage_type_id,
                       users, Operator_ID, comment, year, Month,
                       dataset_id, _callingUser, seq
                FROM Tmp_Staging
                WHERE Mark = 0
                ORDER BY start

            Else

                RAISE INFO '';
                RAISE INFO '%', _infoHeadStaging;
                RAISE INFO '%', _infoHeadSeparatorStaging;

                _previewCount := 0;

                FOR _previewData IN
                    SELECT 'Insert Row' As State,
                           Staging_ID, EMSL_Inst_ID, Instrument, DMS_Inst_ID, Type,
                           public.timestamp_text(Start) As Start,
                           Minutes, Usage, Proposal, Users, Operator, Comment,
                           Year, Month, Dataset_ID, Usage_type_ID, Operator_ID, Mark, Seq
                    FROM Tmp_Staging
                    WHERE Type = 'Interval';
                    ORDER BY Staging_ID
                LOOP
                    _infoData := format(_formatSpecifierStaging,
                                        _previewData.Staging_ID,
                                        _previewData.EMSL_Inst_ID,
                                        _previewData.Instrument,
                                        _previewData.DMS_Inst_ID,
                                        _previewData.Type,
                                        _previewData.Start,
                                        _previewData.Minutes,
                                        _previewData.Usage,
                                        _previewData.Proposal,
                                        _previewData.Users,
                                        _previewData.Operator,
                                        _previewData.Comment,
                                        _previewData.Year,
                                        _previewData.Month,
                                        _previewData.Dataset_ID,
                                        _previewData.Usage_type_ID,
                                        _previewData.Operator_ID,
                                        _previewData.Mark,
                                        _previewData.Seq

                                       );

                    RAISE INFO '%', _infoData;

                    _previewCount := _previewCount + 1;
                END LOOP;

                If _previewCount > 0 Then
                    RAISE INFO 'Would insert % rows into t_emsl_instrument_usage_report', _previewCount;
                End If;
            End If;

            ---------------------------------------------------
            -- Clean out short 'long intervals'
            ---------------------------------------------------

            _formatSpecifierInstUsage := '%-30s %-5s %-12s %-11s %-15s %-20s %-7s %-10s %-13s %-15s %-8s %-50s %-4s %-5s %-10s';

            _infoHeadInstUsage := format(_formatSpecifierInstUsage,
                                'Action',
                                'Seq',
                                'EMSL_Inst_ID',
                                'DMS_Inst_ID',
                                'Type',
                                'Start',
                                'Minutes',
                                'Proposal',
                                'Usage_Type_ID',
                                'Users',
                                'Operator',
                                'Comment',
                                'Year',
                                'Month',
                                'Dataset_ID'
                               );

            _infoHeadSeparatorInstUsage := format(_formatSpecifierInstUsage,
                                                  '------------------------------',
                                                  '-----',
                                                  '------------',
                                                  '-----------',
                                                  '---------------',
                                                  '--------------------',
                                                  '-------',
                                                  '----------',
                                                  '-------------',
                                                  '---------------',
                                                  '--------',
                                                  '--------------------------------------------------',
                                                  '----',
                                                  '-----',
                                                  '----------'
                                                 );

            If Not _infoOnly Then
                DELETE FROM t_emsl_instrument_usage_report
                WHERE dataset_id IN ( SELECT dataset_id
                                      FROM Tmp_Staging ) AND
                      type = 'Interval' AND
                      minutes < _maxNormalInterval;

            Else

                RAISE INFO '';
                RAISE INFO '%', _infoHeadInstUsage;
                RAISE INFO '%', _infoHeadSeparatorInstUsage;

                _previewCount := 0;

                FOR _previewData IN
                    SELECT 'Delete short "long interval"' AS Action,
                           InstUsage.Seq,
                           InstUsage.EMSL_Inst_ID,
                           InstUsage.DMS_Inst_ID,
                           InstUsage.Type,
                           public.timestamp_text(InstUsage.start) As Start,
                           InstUsage.Minutes,
                           InstUsage.Proposal,
                           InstUsage.Usage_Type_ID,
                           InstUsage.Users,
                           InstUsage.Operator,
                           InstUsage.Comment,
                           InstUsage.Year,
                           InstUsage.Month,
                           InstUsage.Dataset_ID
                    FROM t_emsl_instrument_usage_report InstUsage
                    WHERE InstUsage.dataset_id IN ( SELECT dataset_id
                                                    FROM Tmp_Staging ) AND
                          InstUsage.type = 'Interval' AND
                          InstUsage.minutes < _maxNormalInterval
                LOOP
                    _infoData := format(_formatSpecifierInstUsage,
                                        _previewData.Action,
                                        _previewData.Seq,
                                        _previewData.EMSL_Inst_ID,
                                        _previewData.DMS_Inst_ID,
                                        _previewData.Type,
                                        _previewData.Start,
                                        _previewData.Minutes,
                                        _previewData.Proposal,
                                        _previewData.Usage_Type_ID,
                                        _previewData.Users,
                                        _previewData.Operator,
                                        _previewData.Comment,
                                        _previewData.Year,
                                        _previewData.Month,
                                        _previewData.Dataset_ID
                                       );

                    RAISE INFO '%', _infoData;

                    _previewCount := _previewCount + 1;
                END LOOP;

                If _previewCount > 0 Then
                    RAISE INFO 'Would delete % shorter "long intervals" from t_emsl_instrument_usage_report', _previewCount;
                End If;
            End If;

            ---------------------------------------------------
            -- Clean out any 'long intervals' that don't appear
            -- in the main interval table
            ---------------------------------------------------

            If Not _infoOnly Then
                DELETE FROM t_emsl_instrument_usage_report InstUsage
                WHERE InstUsage.DMS_Inst_ID = InstName.instrument_id AND
                      InstUsage.Type = 'interval' AND
                      InstUsage.Year = _year AND
                      InstUsage.Month = _month AND
                      InstName.instrument = _instrument AND
                      NOT InstUsage.Dataset_ID IN ( SELECT interval_id FROM t_run_interval );

            Else

                RAISE INFO '';
                RAISE INFO '%', _infoHeadInstUsage;
                RAISE INFO '%', _infoHeadSeparatorInstUsage;

                _previewCount := 0;

                FOR _previewData IN
                    SELECT 'Delete long "long interval"' AS Action,
                           InstUsage.Seq,
                           InstUsage.EMSL_Inst_ID,
                           InstUsage.DMS_Inst_ID,
                           InstUsage.Type,
                           public.timestamp_text(InstUsage.start) As Start,
                           InstUsage.Minutes,
                           InstUsage.Proposal,
                           InstUsage.Usage_Type_ID,
                           InstUsage.Users,
                           InstUsage.Operator,
                           InstUsage.Comment,
                           InstUsage.Year,
                           InstUsage.Month,
                           InstUsage.Dataset_ID
                    FROM t_emsl_instrument_usage_report InstUsage
                         INNER JOIN t_instrument_name InstName
                           ON InstUsage.DMS_Inst_ID = InstName.instrument_id
                    WHERE InstUsage.Type = 'interval' AND
                          InstUsage.Year = _year AND
                          InstUsage.Month = _month AND
                          InstName.instrument = _instrument AND
                          NOT InstUsage.Dataset_ID IN ( SELECT interval_id FROM t_run_interval )
                LOOP
                    _infoData := format(_formatSpecifierInstUsage,
                                        _previewData.Action,
                                        _previewData.Seq,
                                        _previewData.EMSL_Inst_ID,
                                        _previewData.DMS_Inst_ID,
                                        _previewData.Type,
                                        _previewData.Public.timestamp_text(start) As Start,
                                        _previewData.Minutes,
                                        _previewData.Proposal,
                                        _previewData.Usage_Type_ID,
                                        _previewData.Users,
                                        _previewData.Operator,
                                        _previewData.Comment,
                                        _previewData.Year,
                                        _previewData.Month,
                                        _previewData.Dataset_ID
                                       );

                    RAISE INFO '%', _infoData;

                    _previewCount := _previewCount + 1;
                END LOOP;

                If _previewCount > 0 Then
                    RAISE INFO 'Would delete % longer "long intervals" from t_emsl_instrument_usage_report', _previewCount;
                End If;
            End If;

            ---------------------------------------------------
            -- Add automatic log references for missing comments
            -- (ignoring MAINTENANCE and ONSITE entries)
            ---------------------------------------------------


            _formatSpecifierUpdateComment := '%-40s %-5s %-25s %-50s %-50s';

            _infoHeadUpdateComment := format(_formatSpecifierUpdateComment,
                                            'Action',
                                            'Seq',
                                            'Instrument',
                                            'Old_Comment',
                                            'New_Comment'
                                            );

            _infoHeadSeparatorUpdateComment := format(_formatSpecifierUpdateComment,
                                                      '----------------------------------------',
                                                      '-----',
                                                      '-------------------------',
                                                      '--------------------------------------------------',
                                                      '--------------------------------------------------'
                                                     );

            If Not _infoOnly Then

                UPDATE t_emsl_instrument_usage_report InstUsage
                SET comment = get_nearest_preceding_log_entry(InstUsage.seq, false)
                FROM t_emsl_instrument_usage_type InstUsageType
                WHERE InstUsage.Year = _year AND
                      InstUsage.Month = _month AND
                      InstUsage.Type= 'Dataset' AND
                      (InstUsage.usage_type_id = InstUsageType.usage_type_id AND NOT InstUsageType.usage_type IN ('MAINTENANCE', 'ONSITE') OR
                       InstUsage.usage_type_id IS NULL
                      ) AND
                      Coalesce(InstUsage.Comment, '') = '';

            Else

                RAISE INFO '';
                RAISE INFO '%', _infoHead;
                RAISE INFO '%', _infoHeadSeparator;

                FOR _previewData IN
                    SELECT 'Add log reference to comment' As Action,
                           InstUsage.Seq,
                           InstName.Instrument,
                           comment AS Old_Comment,
                           get_nearest_preceding_log_entry(InstUsage.seq, false) AS New_Comment
                    FROM t_emsl_instrument_usage_report InstUsage
                         INNER JOIN t_instrument_name InstName
                           ON InstUsage.DMS_Inst_ID = InstName.instrument_id
                         LEFT OUTER JOIN t_emsl_instrument_usage_type InstUsageType
                           ON InstUsage.usage_type_id = InstUsageType.usage_type_id
                    WHERE InstUsage.Year = _year AND
                          InstUsage.Month = _month AND
                          InstUsage.Type = 'Dataset' AND
                          NOT Coalesce(InstUsageType.usage_type, '') IN ('MAINTENANCE', 'ONSITE') AND
                          Coalesce(InstUsage.Comment, '') = ''
                LOOP
                    _infoData := format(_formatSpecifierUpdateComment,
                                        _previewData.Action,
                                        _previewData.Seq,
                                        _previewData.Instrument,
                                        _previewData.Old_Comment,
                                        _previewData.New_Comment
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

            End If;

            ---------------------------------------------------
            -- Remove 'ONSITE' comments
            ---------------------------------------------------

            If Not _infoOnly Then

                UPDATE t_emsl_instrument_usage_report InstUsage
                SET comment = ''
                FROM t_emsl_instrument_usage_type InstUsageType
                     INNER JOIN t_instrument_name InstName
                       ON InstUsage.DMS_Inst_ID = InstName.instrument_id
                WHERE InstUsage.usage_type_id = InstUsageType.usage_type_id AND
                      InstUsageType.usage_type IN ('ONSITE') AND
                      InstName.instrument = _instrument AND
                      InstUsage.Year = _year AND
                      InstUsage.Month = _month AND
                      (Comment IS NULL OR Coalesce(Comment, '') <> '')

            Else

                RAISE INFO '';
                RAISE INFO '%', _infoHeadUpdateComment;
                RAISE INFO '%', _infoHeadSeparatorUpdateComment;

                FOR _previewData IN
                    SELECT 'Clear maintenance and onsite comments' AS Action,
                           InstUsage.Seq,
                           InstName.Instrument,
                           comment AS Old_Comment,
                           '' AS New_Comment
                    FROM t_emsl_instrument_usage_report InstUsage
                         INNER JOIN t_emsl_instrument_usage_type InstUsageType
                           ON InstUsage.usage_type_id = InstUsageType.usage_type_id
                         INNER JOIN t_instrument_name InstName
                           ON InstUsage.DMS_Inst_ID = InstName.instrument_id
                    WHERE InstUsageType.usage_type IN ('ONSITE') AND
                          InstName.instrument = _instrument AND
                          InstUsage.Year = _year AND
                          InstUsage.Month = _month AND
                          (Comment IS NULL OR Coalesce(Comment, '') <> '')
                LOOP
                    _infoData := format(_formatSpecifierUpdateComment,
                                        _previewData.Action,
                                        _previewData.Seq,
                                        _previewData.Instrument,
                                        _previewData.Old_Comment,
                                        _previewData.New_Comment
                                       );

                    RAISE INFO '%', _infoData;
                END LOOP;

            End If;

            ---------------------------------------------------
            -- Populate field Dataset_ID_Acq_Overlap, which is used to track datasets with identical acquisition start times
            ---------------------------------------------------

            CALL update_emsl_instrument_acq_overlap_data (_instrument, _year, _month, _message => _message, _infoOnly => _infoOnly);

        End If; -- </a>

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

    DROP TABLE IF EXISTS Tmp_DebugReports;
    DROP TABLE IF EXISTS Tmp_Staging;
END
$$;

COMMENT ON PROCEDURE public.update_emsl_instrument_usage_report IS 'UpdateEMSLInstrumentUsageReport';
