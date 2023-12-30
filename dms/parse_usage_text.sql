--
-- Name: parse_usage_text(text, xml, text, text, integer, boolean, boolean, integer); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.parse_usage_text(INOUT _comment text, INOUT _usagexml xml, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _seq integer DEFAULT '-1'::integer, IN _showdebug boolean DEFAULT false, IN _validatetotal boolean DEFAULT true, INOUT _invalidusage integer DEFAULT 0)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Parse EMSL usage text in a comment to extract usage values and generate XML
**
**      Example usage values that can appear in _comment (note that each key can only be present once, so you cannot specify multiple proposals in a single _comment)
**        'UserRemote[100%], Proposal[49361], PropUser[50082]'
**        'UserOnsite[100%], Proposal[49361], PropUser[50082] Extra info about the interval'
**        'Remote[100%], Proposal[49361], PropUser[50082]'
**        'Onsite[100%], Proposal[49361], PropUser[50082]'
**        'CapDev[10%], UserOnsite[90%], Proposal[49361], PropUser[50082]'
**
**      Legacy examples:
**        'User[100%], Proposal[49361], PropUser[50082]'
**        'CapDev[10%], User[90%], Proposal[49361], PropUser[50082]'
**
**  Arguments:
**    _comment          Input/Output: usage comment; see above for examples (usage keys and values will be removed from this string)
**    _usageXML         Output: usage information, as XML; will be Null if _validateTotal is true and the percentages do not sum to 100%
**    _message          Status messgae
**    _returnCode       Return code
**    _seq              Row ID in table t_emsl_instrument_usage_report or table t_run_interval; used for status messages
**    _showDebug        When true, show debug messages
**    _validateTotal    When true, raise an error (and do not update _comment or _usageXML) if the sum of the percentages is not 100
**    _invalidUsage     Output: 1 if the usage text in _comment cannot be parsed; Update_Run_Op_Log uses this to skip invalid entries (value passed back via add_update_run_interval)
**
**  Auth:   grk
**  Date:   03/02/2012
**          03/11/2012 grk - Added OtherNotAvailable
**          03/11/2012 grk - Return commment without usage text
**          09/18/2012 grk - Added 'Operator' and 'PropUser' keywords
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**                         - Add parameters _seq, _showDebug, and _validateTotal
**          04/28/2017 mem - Disable logging to T_Log_Entries for RAISERROR messages
**          08/02/2017 mem - Add output parameter _invalidUsage
**                         - Use Try_Convert when parsing UsageValue
**                         - Rename temp tables
**                         - Additional comment cleanup logic
**          08/29/2017 mem - Direct users to http://prismwiki.pnl.gov/wiki/Long_Interval_Notes
**          05/25/2021 mem - Add support for usage types 'UserOnsite' and 'UserRemote'
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          06/15/2023 mem - Add support for usage type 'ResourceOwner'
**          08/30/2023 mem - Only validate that values are numeric for percentage based usage types
**                         - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**          09/08/2023 mem - Adjust capitalization of keywords
**          09/11/2023 mem - Adjust capitalization of keywords
**          10/12/2023 mem - Change from http:// to https://
**          12/02/2023 mem - Rename variable
**
*****************************************************/
DECLARE
    _logErrors boolean := true;
    _commentToSearch citext;
    _keywordPos int;
    _startOfValue int := 0;
    _endOfValue Int;
    _val text;
    _curVal text;
    _keywordStartPos int := 0;
    _uniqueID int := 0;
    _usageKey text;
    _keyword text;
    _total int := 0;
    _hasUser int := 0;
    _hasProposal int := 0;
    _xmlAttributes text := '';
    _usageText text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    _comment       := Trim(Coalesce(_comment, ''));
    _seq           := Coalesce(_seq, -1);
    _showDebug     := Coalesce(_showDebug, false);
    _validateTotal := Coalesce(_validateTotal, true);
    _invalidUsage  := 0;

    If _showDebug Then
        RAISE INFO 'Initial comment for ID %: %', _seq, _comment;
    End If;

    ---------------------------------------------------
    -- Temp table to hold usage key-values
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_UsageInfo (
        UniqueID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        UsageKey citext,
        UsageValue text NULL
    );

    CREATE TEMP TABLE Tmp_NonPercentageKeys (
        UsageKey citext
    );

    ---------------------------------------------------
    -- Temp table to hold location of usage text
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_UsageText (
        UsageText text
    );

    BEGIN
        ---------------------------------------------------
        -- Normalize punctuation to remove spaces around commas
        -- Furthermore, start _comment with a comma to allow for exact keyword matches
        ---------------------------------------------------

        _comment := Replace(_comment, ', ', ',');
        _comment := Replace(_comment, ' ,', ',');
        _commentToSearch := format(',%s', _comment);

        ---------------------------------------------------
        -- Set up temp table with keywords
        ---------------------------------------------------

        -- Store the non-percentage based keys
        --
        INSERT INTO Tmp_NonPercentageKeys (UsageKey)
        SELECT Trim(Value)
        FROM public.parse_delimited_list('Operator, Proposal, PropUser');

        -- Add the percentage-based keys to Tmp_UsageInfo
        --
        INSERT INTO Tmp_UsageInfo (UsageKey)
        SELECT Trim(Value)
        FROM public.parse_delimited_list('CapDev, Broken, Maintenance, StaffNotAvailable, OtherNotAvailable, InstrumentAvailable, UserOnsite, UserRemote, ResourceOwner, Onsite, Remote, User');

        -- Add the non-percentage-based keys to Tmp_UsageInfo
        --
        INSERT INTO Tmp_UsageInfo (UsageKey)
        SELECT UsageKey
        FROM Tmp_NonPercentageKeys;

        ---------------------------------------------------
        -- Look for keywords in text and update table with
        -- corresponding values
        ---------------------------------------------------

        FOR _usageKey, _keyword, _curVal, _uniqueID IN
            SELECT UsageKey,
                   format(',%s[', UsageKey) As KeyWord,
                   UsageValue,
                   UniqueID
            FROM Tmp_UsageInfo
            ORDER BY UniqueID
        LOOP
            ---------------------------------------------------
            -- Look for the keyword in _commentToSearch
            ---------------------------------------------------

            _keywordPos := Position(_keyword In _commentToSearch);

            ---------------------------------------------------
            -- If we found a keyword in the text
            -- parse out its values and save that in the usage table
            ---------------------------------------------------

            If _keywordPos = 0 Then
                If _showDebug Then
                    RAISE INFO '  keyword not found: %', _keyword;
                End If;

                CONTINUE;
            End If;

            If _showDebug Then
                RAISE INFO 'Parse keyword % at char %', _keyword, _keywordPos;
            End If;

            _keywordStartPos := _keywordPos;

            _startOfValue := _keywordPos + char_length(_keyword);
            _endOfValue   := Position(']' In Substring(_commentToSearch, _startOfValue)) + _startOfValue - 1;

            If _endOfValue = 0 Then
                _logErrors := false;
                _invalidUsage := 1;
                RAISE EXCEPTION 'Could not find closing bracket for "%"', _keyword;
            End If;

            _usageText := Substring(_commentToSearch, _keywordStartPos + 1, (_endOfValue - _keywordStartPos) + 1);
            _val       := Substring(_commentToSearch, _startOfValue, _endOfValue - _startOfValue);

            -- Uncomment to debug
            -- If _showDebug Then
            --     RAISE INFO 'Matched usage "%" with value "%" between positions % and % in "%"',
            --                 _usageText, _val, _startOfValue, _endOfValue, _commentToSearch;
            -- End If;

            INSERT INTO Tmp_UsageText ( UsageText )
            VALUES (_usageText);

            _val := Replace(_val, '%', '');
            _val := Replace(_val, ',', '');

            If Not Exists (SELECT * FROM Tmp_NonPercentageKeys WHERE UsageKey = _usageKey) Then
                If public.try_cast(_val, null::int) Is Null Then
                    _logErrors := false;
                    _invalidUsage := 1;
                    RAISE EXCEPTION 'Percentage value for usage "%" is not a valid integer; see ID %', _keyword, _seq;
                End If;
            End If;

            UPDATE Tmp_UsageInfo
            SET UsageValue = _val
            WHERE UniqueID = _uniqueID;

        END LOOP;

        ---------------------------------------------------
        -- Clear keywords not found from table
        ---------------------------------------------------

        DELETE FROM Tmp_UsageInfo
        WHERE UsageValue IS null;

        ---------------------------------------------------
        -- Updated abbreviated keywords
        ---------------------------------------------------

        UPDATE Tmp_UsageInfo
        SET UsageKey = 'UserOnsite'
        WHERE UsageKey = 'Onsite';

        UPDATE Tmp_UsageInfo
        SET UsageKey = 'UserRemote'
        WHERE UsageKey = 'Remote';

        ---------------------------------------------------
        -- Verify percentage total
        -- Skip keys in Tmp_NonPercentageKeys ('Operator, Proposal, PropUser')
        ---------------------------------------------------

        SELECT SUM(public.try_cast(UsageValue, 0))
        INTO _total
        FROM Tmp_UsageInfo
        WHERE Not UsageKey IN (SELECT UsageKey FROM Tmp_NonPercentageKeys);

        If _validateTotal And _total <> 100 Then
            _logErrors := false;
            _invalidUsage := 1;
            RAISE EXCEPTION 'Total percentage (%) does not add up to 100 for ID %; see %', _total, _seq, 'https://prismwiki.pnl.gov/wiki/Long_Interval_Notes';
        End If;

        ---------------------------------------------------
        -- Verify proposal (if user present)
        ---------------------------------------------------

        SELECT COUNT(*)
        INTO _hasUser
        FROM Tmp_UsageInfo
        WHERE UsageKey IN ('User', 'UserOnsite', 'UserRemote');

        SELECT COUNT(*)
        INTO _hasProposal
        FROM Tmp_UsageInfo
        WHERE UsageKey = 'Proposal';

        If _hasUser > 0 And _hasProposal = 0 Then
            _logErrors := false;
            _invalidUsage := 1;
            RAISE EXCEPTION 'Proposal is needed if user allocation is specified; see ID %', _seq;
        End If;

        ---------------------------------------------------
        -- Make XML
        --
        -- Convert keys and values into XML attributes of the form:
        -- <u KeyA="Value" KeyB="Value" />
        ---------------------------------------------------

        SELECT string_agg(format('%s="%s"', UsageKey, UsageValue), ' ' ORDER BY UniqueID)
        INTO _xmlAttributes
        FROM Tmp_UsageInfo;

        _usageXML := public.try_cast(format('<u %s />', _xmlAttributes), null::xml);

        ---------------------------------------------------
        -- Remove usage text from comment
        ---------------------------------------------------

        FOR _usageText IN
            SELECT DISTINCT UsageText
            FROM Tmp_UsageText
        LOOP
            _comment := Trim(Replace(_comment, _usageText, ''));
        END LOOP;

        _comment := Trim(_comment);

        If _comment Like ',%' Then
            _comment := LTrim(Substring(_comment, 2, char_length(_comment) - 1));
        End If;

        If _comment Like '%,' Then
            _comment := RTrim(Substring(_comment, 1, char_length(_comment) - 1));
        End If;

        _comment := Replace(_comment, ',,', '');
        _comment := Replace(_comment, ', ,', '');
        _comment := Replace(_comment, '. ,', '. ');
        _comment := Replace(_comment, '.,', '. ');
        _comment := Trim(_comment);

        If _comment = ',' Then
            _comment := '';
        End If;

        If _showDebug Then
            RAISE INFO 'Final comment for _seq %: "%"; _total = %', _seq, Coalesce(_comment, '<Empty>'), _total;
        End If;

        DROP TABLE Tmp_UsageInfo;
        DROP TABLE Tmp_NonPercentageKeys;
        DROP TABLE Tmp_UsageText;

        RETURN;

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

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

    DROP TABLE IF EXISTS Tmp_UsageInfo;
    DROP TABLE IF EXISTS Tmp_NonPercentageKeys;
    DROP TABLE IF EXISTS Tmp_UsageText;
END
$$;


ALTER PROCEDURE public.parse_usage_text(INOUT _comment text, INOUT _usagexml xml, INOUT _message text, INOUT _returncode text, IN _seq integer, IN _showdebug boolean, IN _validatetotal boolean, INOUT _invalidusage integer) OWNER TO d3l243;

--
-- Name: PROCEDURE parse_usage_text(INOUT _comment text, INOUT _usagexml xml, INOUT _message text, INOUT _returncode text, IN _seq integer, IN _showdebug boolean, IN _validatetotal boolean, INOUT _invalidusage integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.parse_usage_text(INOUT _comment text, INOUT _usagexml xml, INOUT _message text, INOUT _returncode text, IN _seq integer, IN _showdebug boolean, IN _validatetotal boolean, INOUT _invalidusage integer) IS 'ParseUsageText';

