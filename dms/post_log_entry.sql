--
-- Name: post_log_entry(text, text, text, text, integer, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.post_log_entry(IN _type text, IN _message text, IN _postedby text DEFAULT 'na'::text, IN _targetschema text DEFAULT 'public'::text, IN _duplicateentryholdoffhours integer DEFAULT 0, IN _ignoreerrors boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Append a log entry to t_log_entries, either in the public schema or the specified schema
**
**  Arguments:
**    _type                         Message type, typically Normal, Warning, Error, or Progress, but can be any text value
**    _message                      Log message
**    _postedBy                     Name of the calling procedure
**    _targetSchema                 If blank or 'public', log to public.t_log_entries; otherwise, log to t_log_entries for the given schema (if the table does not exist, uses public.t_log_entries)
**    _duplicateEntryHoldoffHours   Set this to a value greater than 0 to prevent duplicate entries being posted within the given number of hours
**    _ignoreErrors                 Set this to true to show a warning if an exception occus (typically due to the calling user not having write access to t_log_entries)
**
**  Auth:   grk
**  Date:   01/26/2001
**          06/08/2006 grk - added logic to put data extraction manager stuff in analysis log
**          03/30/2009 mem - Added parameter _duplicateEntryHoldoffHours
**                         - Expanded the size of _type, _message, and _postedBy
**          07/20/2009 grk - eliminate health log (http://prismtrac.pnl.gov/trac/ticket/742)
**          09/13/2010 mem - Eliminate analysis log
**                         - Auto-update _duplicateEntryHoldoffHours to be 24 when the log type is Health or Normal and the source is the space manager
**          02/27/2017 mem - Although _message is varchar(4096), the Message column in T_Log_Entries may be shorter (512 characters in DMS); disable ANSI Warnings before inserting into the table
**          01/28/2020 mem - Ported to PostgreSQL
**          08/18/2022 mem - Add argment _ignoreErrors
**          08/19/2022 mem - Remove local variable _message that was masking the _message argument
**          08/24/2022 mem - Log to public.t_log_entries if the specified schema does not have a t_log_entries table
**          08/26/2022 mem - Use new column name in t_log_entries
**          12/12/2022 mem - Whitespace update
**          04/27/2023 mem - Use boolean for data type name
**          05/12/2023 mem - Rename variables
**          05/18/2023 mem - Remove implicit string concatenation
**          05/22/2023 mem - Capitalize reserved words
**
*****************************************************/
DECLARE
    _targetTableWithSchema text;
    _logTableFound boolean;
    _minimumPostingTime timestamp;
    _duplicateRowCount int := 0;
    _s text;
    _insertCount int;
    _sqlState text;
    _exceptionMessage text;
    _exceptionContext text;
BEGIN

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _targetSchema := COALESCE(_targetSchema, '');

    If (char_length(_targetSchema) = 0) Then
        _targetSchema := 'public';
    End If;

    _targetTableWithSchema := format('%I.%I', _targetSchema, 't_log_entries');

    SELECT table_exists
    INTO _logTableFound
    FROM public.resolve_table_name(_targetTableWithSchema);

    If Not _logTableFound Then
        _targetTableWithSchema := 'public.t_log_entries';
    End If;

    _type := Coalesce(_type, 'Normal');
    _message := Coalesce(_message, '');
    _postedBy := Coalesce(_postedBy, 'na');
    _duplicateEntryHoldoffHours := Coalesce(_duplicateEntryHoldoffHours, 0);
    _ignoreErrors := Coalesce(_ignoreErrors, false);

    If _postedBy ILike 'Space%' And _type::citext In ('Health', 'Normal') Then
        -- Auto-update _duplicateEntryHoldoffHours to be 24 if it is zero
        -- Otherwise we get way too many health/status log entries

        If _duplicateEntryHoldoffHours = 0 Then
            _duplicateEntryHoldoffHours := 24;
        End If;
    End If;

    _minimumPostingTime = CURRENT_TIMESTAMP - (_duplicateEntryHoldoffHours || ' hours')::INTERVAL;

    If Coalesce(_duplicateEntryHoldoffHours, 0) > 0 Then
        _s := format(
                'SELECT COUNT(*) '         ||
                'FROM %s '                 ||
                'WHERE message = $1 AND '  ||
                     ' type = $2 AND '     ||
                     ' entered >= $3',
                _targetTableWithSchema);

        EXECUTE _s
        INTO _duplicateRowCount
        USING _message, _type, _minimumPostingTime;

    End If;

    If _duplicateRowCount > 0 THEN
        RAISE Info 'Skipping recently logged message; duplicate count: %', _duplicateRowCount;
        RETURN;
    End If;

    _s := format(
            'INSERT INTO %s (posted_by, entered, type, message) ' ||
            'VALUES ( $1, CURRENT_TIMESTAMP, $2, $3)',
            _targetTableWithSchema);

    EXECUTE _s
    USING _postedBy, _type, _message;
    --
    GET DIAGNOSTICS _insertCount = ROW_COUNT;

    If _insertCount = 0 Then
        _message := format('Warning: log message not added to %s', _targetTableWithSchema);
        RAISE WARNING '%', _message;
    End If;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _sqlState = returned_sqlstate,
            _exceptionMessage = message_text,
            _exceptionContext = pg_exception_context;

    _message := format('Warning: log message not added to %s (%s); %s',
                _targetTableWithSchema, _message, _exceptionMessage);

    RAISE WARNING '%', _message;

    If _ignoreErrors Then
        RETURN;
    End If;

    RAISE WARNING 'Context: %', _exceptionContext;

    -- Re-throw the original exception
    RAISE;
END
$_$;


ALTER PROCEDURE public.post_log_entry(IN _type text, IN _message text, IN _postedby text, IN _targetschema text, IN _duplicateentryholdoffhours integer, IN _ignoreerrors boolean) OWNER TO d3l243;

