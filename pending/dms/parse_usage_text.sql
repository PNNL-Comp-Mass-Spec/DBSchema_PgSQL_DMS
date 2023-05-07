--
CREATE OR REPLACE PROCEDURE public.parse_usage_text
(
    INOUT _comment text,
    INOUT _usageXML XML,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _seq int default -1,
    _showDebug boolean default false,
    _validateTotal boolean default true,
    INOUT _invalidUsage int default 0             -- Leave as an integer since add_update_run_interval tracks this using an integer
)
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
**    _comment         Usage (input / output); see above for examples.  Usage keys and values will be removed from this string
**    _usageXML        Usage information, as XML.  Will be Null if _validateTotal is true and the percentages do not sum to 100%
**    _validateTotal   When true, raise an error (and do not update _comment or _usageXML) if the sum of the percentages is not 100
**    _invalidUsage    Output: 1 if the usage text in _comment cannot be parsed; UpdateRunOpLog uses this to skip invalid entries (value passed back via AddUpdateRunInterval)
**
**  Auth:   grk
**  Date:   03/02/2012
**          03/11/2012 grk - added OtherNotAvailable
**          03/11/2012 grk - return commment without usage text
**          09/18/2012 grk - added 'Operator' and 'PropUser' keywords
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
**          05/25/2021 mem - Add support for usage types UserOnsite and UserRemote
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _logErrors boolean := true;
    _commentToSearch text;
    _index int;
    _startOfValue int := 0;
    _endOfValue Int;
    _val text;
    _curVal text;
    _keywordStartIndex int := 0;
    _uniqueID int := 0
    _nextID int := 0;
    _kw text;
    _continue boolean;
    _total int := 0;
    _hasUser int := 0;
    _hasProposal int := 0;
    _s text := '';

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

    _comment := Trim(Coalesce(_comment, ''));
    _message := '';
    _returnCode := '';

    _seq := Coalesce(_seq, -1);
    _showDebug := Coalesce(_showDebug, false);
    _validateTotal := Coalesce(_validateTotal, true);
    _invalidUsage := 0;

    If _showDebug Then
        RAISE INFO 'Initial comment for ID %: %', _seq, _comment;
    End If;

    ---------------------------------------------------
    -- Temp table to hold usage key-values
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_UsageInfo (
        UsageKey citext,
        UsageValue text NULL,
        UniqueID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY
    )

    CREATE TEMP TABLE Tmp_NonPercentageKeys (
        UsageKey text
    )

    ---------------------------------------------------
    -- Temp table to hold location of usage text
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_UsageText (
        UsageText text
    )

    ---------------------------------------------------
    -- Usage keywords
    ---------------------------------------------------

    BEGIN
        ---------------------------------------------------
        -- Normalize punctuation to remove spaces around commas
        -- Furthermore, start _comment with a comma to allow for exact keyword matches
        ---------------------------------------------------

        _comment := REPLACE(_comment, ', ', ',');
        _comment := REPLACE(_comment, ' ,', ',');
        _commentToSearch := ',' || _comment;

        ---------------------------------------------------
        -- Set up temp table with keywords
        ---------------------------------------------------

        -- Store the non-percentage based keys
        --
        INSERT INTO Tmp_NonPercentageKeys (UsageKey)
        SELECT Trim(Item)
        FROM public.parse_delimited_list('Operator, Proposal, PropUser');

        -- Add the percentage-based keys to Tmp_UsageInfo
        --
        INSERT INTO Tmp_UsageInfo (UsageKey)
        SELECT Trim(Item)
        FROM public.parse_delimited_list('CapDev, Broken, Maintenance, StaffNotAvailable, OtherNotAvailable, InstrumentAvailable, UserOnsite, UserRemote, Onsite, Remote, User');

        -- Add the non-percentage-based keys to Tmp_UsageInfo
        --
        INSERT INTO Tmp_UsageInfo (UsageKey)
        SELECT UsageKey
        FROM Tmp_NonPercentageKeys;

        ---------------------------------------------------
        -- Look for keywords in text and update table with
        -- corresponding values
        ---------------------------------------------------

        _continue := true;

        WHILE _continue
        LOOP
            ---------------------------------------------------
            -- Get next keyword to look for
            ---------------------------------------------------

            _kw := '';

            SELECT ',' || UsageKey || '[' As KeyWord
                UsageValue,
                UniqueID
            INTO _kw, _curVal, _uniqueID
            FROM Tmp_UsageInfo
            WHERE UniqueID > _nextID
            LIMIT 1;

            _nextID := _uniqueID;

            ---------------------------------------------------
            -- Done if no more keywords,
            -- otherwise look for it in text
            ---------------------------------------------------

            If _kw = '' Then
                _continue := false;
            Else
            -- <b>
                _index := Position(_kw In _commentToSearch);

                ---------------------------------------------------
                -- If we found a keyword in the text
                -- parse out its values and save that in the usage table
                ---------------------------------------------------

                If _index = 0 Then
                    If _showDebug Then
                        RAISE INFO '  keyword not found: %', _kw;
                    End If;
                Else
                -- <c>
                    If _showDebug Then
                        RAISE INFO 'Parse keyword % at index %', _kw, _index;
                    End If;

                    _keywordStartIndex := _index;
                    _startOfValue := _index + char_length(_kw);
                    _endOfValue := Position(']', _commentToSearch In _startOfValue);

                    If _endOfValue = 0 Then
                        _logErrors := false;
                        _invalidUsage := 1;
                        RAISE EXCEPTION 'Could not find closing bracket for "%"', _kw;
                    End If;

                    INSERT INTO Tmp_UsageText ( UsageText )
                    VALUES (SUBSTRING(_commentToSearch, _keywordStartIndex + 1, (_endOfValue - _keywordStartIndex) + 1))

                    _val := '';
                    _val := SUBSTRING(_commentToSearch, _startOfValue, _endOfValue - _startOfValue);

                    _val := REPLACE(_val, '%', '');
                    _val := REPLACE(_val, ',', '');

                    If public.try_cast(_val, null::int) Is Null Then
                        _logErrors := false;
                        _invalidUsage := 1;
                        RAISE EXCEPTION 'Percentage value for usage "%" is not a valid integer; see ID %', _kw, _seq;
                    End If;

                    UPDATE Tmp_UsageInfo
                    SET UsageValue = _val
                    WHERE UniqueID = _uniqueID

                End If; -- </c>
            End If; -- </b>
        END LOOP; -- </a>

        ---------------------------------------------------
        -- Clear keywords not found from table
        ---------------------------------------------------

        DELETE FROM Tmp_UsageInfo WHERE UsageValue IS null

        ---------------------------------------------------
        -- Updated abbreviated keywords
        ---------------------------------------------------

        UPDATE Tmp_UsageInfo
        SET UsageKey = 'UserOnsite'
        WHERE UsageKey = 'Onsite'

        UPDATE Tmp_UsageInfo
        SET UsageKey = 'UserRemote'
        WHERE UsageKey = 'Remote'

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
            RAISE EXCEPTION 'Total percentage (%) does not add up to 100 for ID %; see %', _total, _seq, 'http://prismwiki.pnl.gov/wiki/Long_Interval_Notes';
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

        If (_hasUser > 0 ) AND (_hasProposal = 0) Then
            _logErrors := false;
            _invalidUsage := 1;
            RAISE EXCEPTION 'Proposal is needed if user allocation is specified; see ID %', _seq;
        End If;

        ---------------------------------------------------
        -- Make XML
        --
        -- Convert keys and values into XML attributes of the form:
        -- Key="Value"
        ---------------------------------------------------

        SELECT string_agg(format('%s="%s"', UsageKey, UsageValue, ' ')
        INTO _s
        FROM Tmp_UsageInfo;

        _usageXML := '<u ' || _s || ' />';

        ---------------------------------------------------
        -- Remove usage text from comment
        ---------------------------------------------------

        SELECT REPLACE(_comment, UsageText, '')
        INTO _comment
        FROM Tmp_UsageText;

        _comment := Trim(_comment);

        If _comment LIKE ',%' Then
            _comment := LTRIM(Substring(_comment, 2, char_length(_comment) - 1));
        End If;

        If _comment LIKE '%,' Then
            _comment := RTRIM(Substring(_comment, 1, char_length(_comment) - 1));
        End If;

        _comment := REPLACE(_comment, ',,', '');
        _comment := REPLACE(_comment, ', ,', '');
        _comment := REPLACE(_comment, '. ,', '. ');
        _comment := REPLACE(_comment, '.,', '. ');
        _comment := Trim(_comment);

        If _comment = ',' Then
            _comment := '';
        End If;

        If _showDebug Then
            RAISE INFO 'Final comment for _seq %: %; _total = %', _seq, Coalesce(_comment, '<Empty>'), _total;
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

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;

    DROP TABLE IF EXISTS Tmp_UsageInfo;
    DROP TABLE IF EXISTS Tmp_NonPercentageKeys;
    DROP TABLE IF EXISTS Tmp_UsageText;
END
$$;

COMMENT ON PROCEDURE public.parse_usage_text IS 'ParseUsageText';
