--
CREATE OR REPLACE PROCEDURE public.update_instrument_usage_report
(
    _factorList text,
    _operation text,
    _year text,
    _month text,
    _instrument text,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Update requested EMSL instument usage table from input XML list
**
**      Example value for _factorList:
**
**        <id type="Seq" />
**        <r i="1939" f="Comment" v="..." />
**        <r i="1941" f="Comment" v="..." />
**        <r i="2058" f="Proposal" v="..." />
**        <r i="1941" f="Proposal" v="..." />
**
**  Arguments:
**    _operation   'update', 'refresh', 'reload'
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
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _msg text;
    _startOfMonth timestamp;
    _startOfNextMonth timestamp;
    _endOfMonth timestamp;
    _lockDateReload timestamp;
    _lockDateUpdate timestamp;
    _xml AS xml;
    _instrumentID int := 0;
    _monthValue int;
    _yearValue int;
    _badFields text := '';
    _currentInstrument text;

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
    -- Validate inputs
    ---------------------------------------------------

    If Coalesce(_callingUser, '') = '' Then
        _callingUser := get_user_login_without_domain('');
    End If;

    _instrument := Coalesce(_instrument, '');

    If _instrument <> '' Then
        SELECT instrument_id
        INTO _instrumentID
        FROM t_instrument_name
        WHERE instrument = _instrument;

        If Not FOUND Then
            RAISE EXCEPTION 'Instrument not found: "%"', _instrument;
        End If;
    End If;

    _operation := Trim(Coalesce(_operation, ''));
    If char_length(_operation) = 0 Then
        RAISE EXCEPTION 'Operation must be defined';
    End If;

    _month := Trim(Coalesce(_month, ''));
    _year := Trim(Coalesce(_year, ''));

    If char_length(_month) = 0 Then
        RAISE EXCEPTION 'Month must be defined';
    End If;

    If char_length(_year) = 0 Then
        RAISE EXCEPTION 'Year must be defined';
    End If;

    _monthValue := public.try_cast(_month, null::int);
    _yearValue  := public.try_cast(_year, null::int);

    If _monthValue Is Null Then
        RAISE EXCEPTION 'Month must be an integer, not: "%"', _month;
    End If;

    If _yearValue Is Null Then
        RAISE EXCEPTION 'Year must be an integer, not: "%"', _year;
    End If;

    -- Uncomment to debug
    -- _debugMessage := format('Operation: %s; Instrument: %s; %s-%s; %s', _operation, _instrument, _year, _month, _factorList);
    -- call post_log_entry ('Debug', _debugMessage, 'Update_Instrument_Usage_Report');

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
        -- Get boundary dates
        ---------------------------------------------------
        _startOfMonth     := make_date(_year, _month, 1)              ; -- Beginning of the month that we are updating
        _startOfNextMonth := _startOfMonth     + INTERVAL '1 month'   ; -- Beginning of the next month after _startOfMonth
        _endOfMonth       := _startOfNextMonth - INTERVAL '1 msec'    ; -- End of the month that we are editing
        _lockDateReload   := _startOfNextMonth + INTERVAL '60 days'   ; -- Date threshold, afterwhich users can no longer reload this month's data
        _lockDateUpdate   := _startOfNextMonth + INTERVAL '365 days'  ; -- Date threshold, afterwhich users can no longer update this month's data

        If _operation::citext In ('update') And CURRENT_TIMESTAMP > _lockDateUpdate Then
            RAISE EXCEPTION 'Changes are not allowed to instrument usage data over 365 days old';
        End If;

        If Not _operation::citext In ('update') And CURRENT_TIMESTAMP > _lockDateReload Then
            RAISE EXCEPTION 'Instrument usage data over 60 days old cannot be reloaded or refreshed';
        End If;

        -----------------------------------------------------------
        -- Foundational actions for various operations
        -----------------------------------------------------------

        If _operation::citext In ('update') Then
        --<a>

            -----------------------------------------------------------
            -- Temp table to hold update items
            -----------------------------------------------------------

            CREATE TEMP TABLE Tmp_Factors (
                Identifier int null,
                Field citext null,
                Value text null,
            )

            -----------------------------------------------------------
            -- Populate temp table with new parameters
            -----------------------------------------------------------

            INSERT INTO Tmp_Factors (Identifier, Field, Value)
            SELECT XmlQ.Identifier, XmlQ.Field, XmlQ.Value
            FROM (
                SELECT xmltable.*
                FROM ( SELECT _xml As rooted_xml
                     ) Src,
                     XMLTABLE('//root/r'
                              PASSING Src.rooted_xml
                              COLUMNS Identifier int PATH '@i',
                                      Field text PATH '@f',
                                      Value text PATH '@v')
                 ) XmlQ;

            -----------------------------------------------------------
            -- Make sure changed fields are allowed
            -----------------------------------------------------------

            SELECT string_agg(Field, ',' ORDER BY Field)
            INTO _badFields
            FROM Tmp_Factors
            WHERE NOT Field IN ('Proposal', 'Operator', 'Comment', 'Users', 'Usage');
            --
            If _badFields <> '' Then
                RAISE EXCEPTION 'The following field(s) are not editable: %', _badFields;
            End If;

        End If; --<a>

        If _operation::citext In ('reload', 'refresh') Then
        --<b>
            -----------------------------------------------------------
            -- Validation
            -----------------------------------------------------------

            If _operation::citext = 'reload' AND Coalesce(_instrument, '') = '' Then
                RAISE EXCEPTION 'An instrument must be specified for the reload operation';
            End If;

            If Coalesce(_year, '') = '' OR Coalesce(_month, '') = '' Then
                RAISE EXCEPTION 'A year and month must be specified for this operation';
            End If;

            If Coalesce(_instrument, '') = '' Then
                ---------------------------------------------------
                -- Get list of EMSL instruments
                ---------------------------------------------------

                CREATE TEMP TABLE Tmp_Instruments (
                    Seq int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
                    Instrument text
                )
                INSERT INTO Tmp_Instruments (Instrument)
                SELECT Name
                FROM V_Instrument_Tracked
                WHERE Upper(Coalesce(EUS_Primary_Instrument, '')) IN ('Y', '1')
            End If;

        End If; --<b>

        If _operation::citext = 'update' Then
            UPDATE t_emsl_instrument_usage_report
            SET comment = Tmp_Factors.Value
            FROM Tmp_Factors
            WHERE t_emsl_instrument_usage_report.Seq = Tmp_Factors.Identifier AND
                  Field = 'Comment';
3
            UPDATE t_emsl_instrument_usage_report
            SET proposal = Tmp_Factors.Value
            FROM Tmp_Factors
            WHERE t_emsl_instrument_usage_report.Seq = Tmp_Factors.Identifier AND
                 Field = 'Proposal';

            UPDATE t_emsl_instrument_usage_report
            SET operator = public.try_cast(Tmp_Factors.Value, null::0)
            FROM Tmp_Factors
            WHERE t_emsl_instrument_usage_report.Seq = Tmp_Factors.Identifier AND
                Field = 'Operator';

            UPDATE t_emsl_instrument_usage_report
            SET users = Tmp_Factors.Value
            FROM Tmp_Factors
            WHERE t_emsl_instrument_usage_report.Seq = Tmp_Factors.Identifier AND
                  Field = 'Users';

            UPDATE t_emsl_instrument_usage_report
            SET usage_type_id = InstUsageType.ID
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

        If _operation::citext = 'reload' Then
            UPDATE t_emsl_instrument_usage_report
            SET usage_type_id = Null,
                proposal = '',
                users = '',
                operator = Null,
                comment = ''
            WHERE _year = year AND
                  _month = month AND
                  (_instrument = '' OR dms_inst_id = _instrumentID);

            CALL update_dataset_interval _instrument, _startOfMonth, _endOfMonth, _message => _message

            _operation := 'refresh';
        End If;

        If _operation::citext = 'refresh' Then
            If char_length(Coalesce(_instrument, '')) > 0 Then
                CALL update_emsl_instrument_usage_report (
                                        _instrument => _instrument,
                                        _eusInstrumentId => 0,
                                        _endDate => _endOfMonth,
                                        _infoOnly => false,
                                        _message => _msg,
                                        _returnCode => _returnCode);

                If _returnCode <> '' Then
                    RAISE EXCEPTION '%', _msg;
                End If;
            Else
                FOR _currentInstrument IN
                    SELECT Instrument
                    FROM Tmp_Instruments
                    ORDER BY Seq
                LOOP
                    CALL update_emsl_instrument_usage_report (
                                        _instrument => _currentInstrument,
                                        _eusInstrumentId => 0,
                                        _endDate => _endOfMonth,
                                        _infoOnly => false,
                                        _message => _msg,
                                        _returnCode => _returnCode);

                    If _returnCode <> '' Then
                        RAISE EXCEPTION '%', _msg;
                    End If;

                END LOOP;
            End If; --<m>
        End If;

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

    DROP TABLE IF EXISTS Tmp_Factors;
    DROP TABLE IF EXISTS Tmp_Instruments;
END
$$;

COMMENT ON PROCEDURE public.update_instrument_usage_report IS 'UpdateInstrumentUsageReport';
