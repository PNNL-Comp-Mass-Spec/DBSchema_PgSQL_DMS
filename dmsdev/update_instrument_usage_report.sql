--
-- Name: update_instrument_usage_report(text, text, text, text, text, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_instrument_usage_report(IN _factorlist text, IN _operation text, IN _year text, IN _month text, IN _instrument text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update table t_emsl_instrument_usage_report (which tracks actual instrument usage) using an XML list
**
**      When _operation is 'update':
**        Update one or more existing rows in t_emsl_instrument_usage_report, using the info in _factorList
**
**      When _operation is 'reload':
**        Clear all of the instrument usage data for the given year and month (optionally filtering on instrument)
**        Next, call update_dataset_interval() and update_emsl_instrument_usage_report()
**
**      When _operation is 'refresh':
**        Call update_emsl_instrument_usage_report() for the given year and month (optionally filtering on instrument)
**
**      Example XML in _factorList:
**        <id type="Seq" />
**        <r i="1939" f="Comment" v="..." />
**        <r i="1941" f="Comment" v="..." />
**        <r i="2058" f="Proposal" v="..." />
**        <r i="1941" f="Proposal" v="..." />
**
**      In the XML:
**        "i" specifies the sequence ID in table t_emsl_instrument_usage_report
**        "f" is the field to update: 'Proposal', 'Operator', 'Comment', 'Users', or 'Usage' (operator is EUS user ID of the instrument operator)
**        "v" is the value to store
**
**  Arguments:
**    _factorList       When _operation is 'update', XML specifying 'Proposal', 'Operator', 'Comment', 'Users', or 'Usage' items to update
**    _operation        Operation: 'update', 'refresh', 'reload'
**    _year             Year to filter t_emsl_instrument_usage_report on when operation is 'refresh' or 'reload'
**    _month            Month to filter t_emsl_instrument_usage_report on when operation is 'refresh' or 'reload'
**    _instrument       Instrument to filter t_emsl_instrument_usage_report on when operation is 'refresh' or 'reload'; process all instruments if an empty string
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   grk
**  Date:   10/07/2012
**          10/09/2012 grk - Enabled 10 day edit cutoff and Update_Dataset_Interval for 'reload'
**          11/21/2012 mem - Extended cutoff for 'reload' to be 45 days instead of 10 days
**          01/09/2013 mem - Extended cutoff for 'reload' to be 90 days instead of 45 days
**          04/03/2013 grk - Made Usage editable
**          04/04/2013 grk - Clearing Usage on reload
**          02/23/2016 mem - Add set XACT_ABORT on
**          11/08/2016 mem - Use GetUserLoginWithoutDomain to obtain the user's network login
**          11/10/2016 mem - Pass '' to GetUserLoginWithoutDomain
**          04/11/2017 mem - Now using fields DMS_Inst_ID and Usage_Type in T_EMSL_Instrument_Usage_Report
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/03/2019 mem - Pass 0 to Update_EMSL_Instrument_Usage_Report for _eusInstrumentID
**          09/10/2019 mem - Extended cutoff for 'update' to be 365 days instead of 90 days
**                         - Changed the cutoff for reload to 60 days
**          07/15/2022 mem - Instrument operator ID is now tracked as an actual integer
**          03/02/2024 mem - Trim leading and trailing whitespace from Field and Value text parsed from the XML
**                         - Allow _year and _month to be undefined if _operation is 'update'
**                         - Ported to PostgreSQL
**          03/03/2024 mem - Trim whitespace when extracting values from XML
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _reloadThresholdDays int = 60;      -- Defaults to 60
    _updateThresholdDays int = 365;     -- Defaults to 365
    _startOfMonth timestamp;
    _startOfNextMonth timestamp;
    _endOfMonth timestamp;
    _lockDateReload timestamp;
    _lockDateUpdate timestamp;
    _xml xml;
    _instrumentID int := 0;
    _yearValue int;
    _monthValue int;
    _badFields text;
    _msg text;
    _currentInstrument text;

    _dropFactorsTable boolean := false;
    _dropInstrumentsTable boolean := false;
    _logErrors boolean := true;

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

    SELECT authorized, message
    INTO _authorized, _message
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _factorList  := Trim(Coalesce(_factorList, ''));
    _operation   := Trim(Lower(Coalesce(_operation, '')));
    _year        := Trim(Coalesce(_year, ''));
    _month       := Trim(Coalesce(_month, ''));
    _instrument  := Trim(Coalesce(_instrument, ''));
    _callingUser := Trim(Coalesce(_callingUser, ''));

    If _callingUser = '' Then
        _callingUser := public.get_user_login_without_domain('');
    End If;

    If _instrument <> '' Then
        SELECT instrument_id
        INTO _instrumentID
        FROM t_instrument_name
        WHERE instrument = _instrument::citext;

        If Not FOUND Then
            RAISE EXCEPTION 'Invalid instrument: "%"', _instrument;
        End If;
    End If;

    If _operation = '' Then
        RAISE EXCEPTION 'Operation must be specified';
    End If;

    If _operation = 'update' Then
        -- _year and _month  are effectively ignored when _operation is 'update'
        -- However, make sure that they are defined so that _startOfMonth can be initialized (even though it also is not used when _operation is 'update')

        If _year = '' Then
            _year := Extract(year from current_timestamp)::text;
        End If;

        If _month = '' Then
            _month := Extract(month from current_timestamp)::text;
        End If;
    Else
        If _year = '' Then
            RAISE EXCEPTION 'Year must be specified';
        End If;

        If _month = '' Then
            RAISE EXCEPTION 'Month must be specified';
        End If;
    End If;

    _yearValue  := public.try_cast(_year, null::int);
    _monthValue := public.try_cast(_month, null::int);

    If _yearValue Is Null Then
        RAISE EXCEPTION 'Year must be an integer, not "%"', _year;
    End If;

    If _monthValue Is Null Then
        RAISE EXCEPTION 'Month must be an integer, not "%"', _month;
    End If;

    -- Uncomment to debug
    -- _debugMessage := format('Operation: %s; Instrument: %s; %s-%s; %s', _operation, _instrument, _year, _month, _factorList);
    -- CALL post_log_entry ('Debug', _debugMessage, 'Update_Instrument_Usage_Report');

    -----------------------------------------------------------
    -- Convert _factorList to rooted XML
    -----------------------------------------------------------

    _xml := public.try_cast('<root>' || _factorList || '</root>', null::xml);

    If _xml Is Null Then
        _message := 'Factor list is not valid XML';
        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        ---------------------------------------------------
        -- Define boundary dates
        ---------------------------------------------------

        _startOfMonth     := make_date(_yearValue, _monthValue, 1)                          ; -- Beginning of the month that we are updating
        _startOfNextMonth := _startOfMonth     + INTERVAL '1 month'                         ; -- Beginning of the next month after _startOfMonth
        _endOfMonth       := _startOfNextMonth - INTERVAL '1 msec'                          ; -- End of the month that we are editing
        _lockDateReload   := _startOfNextMonth + make_interval(days => _reloadThresholdDays); -- Date threshold, afterwhich users can no longer reload this month's data
        _lockDateUpdate   := _startOfNextMonth + make_interval(days => _updateThresholdDays); -- Date threshold, afterwhich users can no longer update this month's data

        If _operation = 'update' And CURRENT_TIMESTAMP > _lockDateUpdate Then
            _logErrors := false;
            RAISE EXCEPTION 'Changes are not allowed to instrument usage data over % days old', _updateThresholdDays;
        End If;

        If _operation <> 'update' And CURRENT_TIMESTAMP > _lockDateReload Then
            _logErrors := false;
            RAISE EXCEPTION 'Instrument usage data over % days old cannot be reloaded or refreshed', _reloadThresholdDays;
        End If;

        -----------------------------------------------------------
        -- Foundational actions for various operations
        -----------------------------------------------------------

        If _operation = 'update' Then

            -----------------------------------------------------------
            -- Temp table to hold update items
            -----------------------------------------------------------

            CREATE TEMP TABLE Tmp_Factors (
                Identifier int NULL,
                Field citext NULL,
                Value text NULL
            );

            _dropFactorsTable := true;

            -----------------------------------------------------------
            -- Populate temp table with new parameters
            -----------------------------------------------------------

            INSERT INTO Tmp_Factors (Identifier, Field, Value)
            SELECT XmlQ.Identifier, Trim(XmlQ.Field), Trim(XmlQ.Value)
            FROM (
                SELECT xmltable.*
                FROM ( SELECT _xml AS rooted_xml
                     ) Src,
                     XMLTABLE('//root/r'
                              PASSING Src.rooted_xml
                              COLUMNS Identifier int  PATH '@i',
                                      Field      text PATH '@f',
                                      Value      text PATH '@v')
                 ) XmlQ;

            -----------------------------------------------------------
            -- Make sure changed fields are allowed
            -----------------------------------------------------------

            SELECT string_agg(Field, ',' ORDER BY Field)
            INTO _badFields
            FROM Tmp_Factors
            WHERE NOT Field IN ('Proposal', 'Operator', 'Comment', 'Users', 'Usage');

            If _badFields <> '' Then
                _logErrors := false;
                RAISE EXCEPTION 'The following field(s) are not editable: %', _badFields;
            End If;

        End If;

        If _operation In ('reload', 'refresh') Then

            -----------------------------------------------------------
            -- Validation
            -----------------------------------------------------------

            If _operation = 'reload' And _instrument = '' Then
                _logErrors := false;
                RAISE EXCEPTION 'An instrument must be specified for the reload operation';
            End If;

            If _instrument = '' Then
                ---------------------------------------------------
                -- Get list of EMSL instruments
                ---------------------------------------------------

                CREATE TEMP TABLE Tmp_Instruments (
                    Seq int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
                    Instrument text
                );

                _dropInstrumentsTable := true;

                INSERT INTO Tmp_Instruments (Instrument)
                SELECT Name
                FROM V_Instrument_Tracked
                WHERE Upper(Coalesce(EUS_Primary_Instrument, '')) IN ('Y', '1');
            End If;

        End If;

        If _operation = 'update' Then

            -- Comment
            UPDATE t_emsl_instrument_usage_report
            SET comment = Tmp_Factors.Value
            FROM Tmp_Factors
            WHERE t_emsl_instrument_usage_report.Seq = Tmp_Factors.Identifier AND
                  Field = 'Comment';

            -- EUS Proposal ID (which is typically an integer, but is tracked as text)
            UPDATE t_emsl_instrument_usage_report
            SET proposal = Tmp_Factors.Value
            FROM Tmp_Factors
            WHERE t_emsl_instrument_usage_report.Seq = Tmp_Factors.Identifier AND
                  Field = 'Proposal';

            -- EUS Operator ID
            UPDATE t_emsl_instrument_usage_report
            SET operator = public.try_cast(Tmp_Factors.Value, null::int)
            FROM Tmp_Factors
            WHERE t_emsl_instrument_usage_report.Seq = Tmp_Factors.Identifier AND
                  Field = 'Operator';

            -- EUS User IDs
            UPDATE t_emsl_instrument_usage_report
            SET users = Tmp_Factors.Value
            FROM Tmp_Factors
            WHERE t_emsl_instrument_usage_report.Seq = Tmp_Factors.Identifier AND
                  Field = 'Users';

            -- EUS Usage Type ID
            UPDATE t_emsl_instrument_usage_report
            SET usage_type_id = InstUsageType.usage_type_id
            FROM Tmp_Factors
                 INNER JOIN t_emsl_instrument_usage_type InstUsageType
                   ON Tmp_Factors.Value = InstUsageType.usage_type
            WHERE t_emsl_instrument_usage_report.Seq = Tmp_Factors.Identifier AND
                  Field = 'Usage';

            UPDATE t_emsl_instrument_usage_report
            SET updated = CURRENT_TIMESTAMP,
                updated_by = _callingUser
            FROM Tmp_Factors
                 WHERE Seq = Identifier;

        End If;

        If _operation = 'reload' Then
            UPDATE t_emsl_instrument_usage_report
            SET usage_type_id = Null,
                proposal = '',
                users = '',
                operator = Null,
                comment = ''
            WHERE year = _yearValue AND
                  month = _monthValue AND
                  (_instrument = '' OR dms_inst_id = _instrumentID);

            CALL public.update_dataset_interval (
                            _instrumentName => _instrument,
                            _startDate      => _startOfMonth,
                            _endDate        => _endOfMonth,
                            _infoOnly       => false,
                            _message        => _message,        -- Output
                            _returnCode     => _returnCode);    -- Output

            _operation := 'refresh';
        End If;

        If _operation = 'refresh' Then
            If _instrument <> '' Then
                CALL public.update_emsl_instrument_usage_report (
                                _instrument      => _instrument,
                                _eusInstrumentId => 0,
                                _endDate         => _endOfMonth,
                                _infoOnly        => false,
                                _debugReports    => '',
                                _message         => _msg,
                                _returnCode      => _returnCode);

                If _returnCode <> '' Then
                    RAISE EXCEPTION '%', _msg;
                End If;
            Else
                FOR _currentInstrument IN
                    SELECT Instrument
                    FROM Tmp_Instruments
                    ORDER BY Seq
                LOOP
                    CALL public.update_emsl_instrument_usage_report (
                                    _instrument      => _currentInstrument,
                                    _eusInstrumentId => 0,
                                    _endDate         => _endOfMonth,
                                    _infoOnly        => false,
                                    _debugReports    => '',
                                    _message         => _msg,
                                    _returnCode      => _returnCode);

                    If _returnCode <> '' Then
                        RAISE EXCEPTION '%', _msg;
                    End If;

                END LOOP;
            End If;
        End If;

        If _dropFactorsTable Then
            DROP TABLE Tmp_Factors;
        End If;

        If _dropInstrumentsTable Then
            DROP TABLE Tmp_Instruments;
        End If;

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
                        _callingProcLocation => '', _logError => _logErrors);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    If _dropFactorsTable Then
        DROP TABLE IF EXISTS Tmp_Factors;
    End If;

    If _dropInstrumentsTable Then
        DROP TABLE IF EXISTS Tmp_Instruments;
    End If;

END
$$;


ALTER PROCEDURE public.update_instrument_usage_report(IN _factorlist text, IN _operation text, IN _year text, IN _month text, IN _instrument text, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_instrument_usage_report(IN _factorlist text, IN _operation text, IN _year text, IN _month text, IN _instrument text, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_instrument_usage_report(IN _factorlist text, IN _operation text, IN _year text, IN _month text, IN _instrument text, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateInstrumentUsageReport';

