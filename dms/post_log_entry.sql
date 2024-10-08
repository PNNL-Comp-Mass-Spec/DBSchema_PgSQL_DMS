--
-- Name: post_log_entry(text, text, text, text, integer, boolean, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.post_log_entry(IN _type text, IN _message text, IN _postedby text DEFAULT 'na'::text, IN _targetschema text DEFAULT 'public'::text, IN _duplicateentryholdoffhours integer DEFAULT 0, IN _ignoreerrors boolean DEFAULT false, IN _logerrorstopubliclogtable boolean DEFAULT true)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Append a log entry to t_log_entries, either in the public schema or in the specified schema
**
**  Arguments:
**    _type                         Message type, typically Normal, Warning, Error, or Progress, but can be any text value
**    _message                      Log message
**    _postedBy                     Name of the calling procedure
**    _targetSchema                 If blank or 'public', log to public.t_log_entries; otherwise, log to t_log_entries for the given schema (if the table does not exist, uses public.t_log_entries)
**    _duplicateEntryHoldoffHours   Set this to a value greater than 0 to prevent duplicate entries being posted within the given number of hours
**    _ignoreErrors                 Set this to true to show a warning if an exception occus (typically due to the calling user not having write access to t_log_entries)
**    _logErrorsToPublicLogTable    When true, if _type is 'Error' and _targetSchema is not public (or an empty string), also log the error message to public.t_log_entries
**
**  Auth:   grk
**  Date:   01/26/2001
**          06/08/2006 grk - Added logic to put data extraction manager stuff in analysis log
**          03/30/2009 mem - Added parameter _duplicateEntryHoldoffHours
**                         - Expanded the size of _type, _message, and _postedBy
**          07/20/2009 grk - Eliminate health log (http://prismtrac.pnl.gov/trac/ticket/742)
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
**          05/30/2023 mem - Use format() for string concatenation
**                         - Add back implicit string concatenation
**          07/11/2023 mem - Use COUNT(entry_id) instead of COUNT(*)
**          09/07/2023 mem - Align assignment statements
**          09/11/2023 mem - Adjust capitalization of keywords
**          09/14/2023 mem - Trim leading and trailing whitespace from procedure arguments
**          01/04/2024 mem - Check for empty strings instead of using char_length()
**          02/27/2024 mem - Log messages to t_log_entries_local when the target schema is 'logdms', 'logcap', or 'logsw'
**          05/25/2024 mem - If _targetSchema is not public (or an empty string), but _type is 'Error', also log the error message to public.t_log_entries
**          08/14/2024 mem - Add argument _logErrorsToPublicLogTable
**
*****************************************************/
DECLARE
    _targetTable text;
    _targetTableWithSchema text;
    _publicSchemaTargetTable text;
    _logTableFound boolean;
    _minimumPostingTime timestamp;
    _duplicateRowCount int := 0;
    _s text;
    _insertCount int;
    _msg text;
    _sqlState text;
    _exceptionMessage text;
    _exceptionContext text;
BEGIN

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _targetSchema := Trim(Lower(Coalesce(_targetSchema, '')));
    _targetTable  := 't_log_entries';

    If _targetSchema = '' Then
        _targetSchema := 'public';
    ElsIf _targetSchema IN ('logdms', 'logcap', 'logsw') Then
        -- Post log entries to logsw.t_log_entries_local, logdms.t_log_entries_local, or logcap.t_log_entries_local
        _targetTable := 't_log_entries_local';
    End If;

    _targetTableWithSchema   := format('%I.%I', _targetSchema, _targetTable);
    _publicSchemaTargetTable := 'public.t_log_entries';

    SELECT table_exists
    INTO _logTableFound
    FROM public.resolve_table_name(_targetTableWithSchema);

    If Not _logTableFound Then
        _targetTableWithSchema := _publicSchemaTargetTable;
    End If;

    _type                       := Trim(Coalesce(_type, 'Normal'));
    _message                    := Trim(Coalesce(_message, ''));
    _postedBy                   := Trim(Coalesce(_postedBy, 'na'));
    _duplicateEntryHoldoffHours := Coalesce(_duplicateEntryHoldoffHours, 0);
    _ignoreErrors               := Coalesce(_ignoreErrors, false);
    _logErrorsToPublicLogTable  := Coalesce(_logErrorsToPublicLogTable, true);

    If _postedBy ILike 'Space%' And _type::citext In ('Health', 'Normal') Then
        -- Auto-update _duplicateEntryHoldoffHours to be 24 if it is zero
        -- Otherwise we get way too many health/status log entries

        If _duplicateEntryHoldoffHours = 0 Then
            _duplicateEntryHoldoffHours := 24;
        End If;
    End If;

    _minimumPostingTime = CURRENT_TIMESTAMP - format('%s hours', _duplicateEntryHoldoffHours)::INTERVAL;

    If Coalesce(_duplicateEntryHoldoffHours, 0) > 0 Then
        _s := format(
                'SELECT COUNT(entry_id) '
                'FROM %s '
                'WHERE message = $1 AND '
                     ' type = $2 AND '
                     ' entered >= $3',
                _targetTableWithSchema);

        EXECUTE _s
        INTO _duplicateRowCount
        USING _message, _type, _minimumPostingTime;
    End If;

    If _duplicateRowCount > 0 THEN
        RAISE INFO 'Skipping recently logged message; duplicate count: %', _duplicateRowCount;
        RETURN;
    End If;

    _s := format('INSERT INTO %s (posted_by, entered, type, message) '
                 'VALUES ($1, CURRENT_TIMESTAMP, $2, $3)',
                 _targetTableWithSchema);

    EXECUTE _s
    USING _postedBy, _type, _message;
    --
    GET DIAGNOSTICS _insertCount = ROW_COUNT;

    If _insertCount = 0 Then
        _msg := format('Warning: log message not added to %s', _targetTableWithSchema);
        RAISE WARNING '%', _msg;
    End If;

    If _type::citext = 'Error' And _targetSchema <> 'public' And _logErrorsToPublicLogTable Then
        -- Also log the error in public.t_log_entries so that we can query a single table to check for errors

        _s := format('INSERT INTO %s (posted_by, entered, type, message) '
                     'VALUES ($1, CURRENT_TIMESTAMP, $2, $3)',
                     _publicSchemaTargetTable);

        _message := format('%s schema: %s', _targetSchema, _message);

        EXECUTE _s
        USING _postedBy, _type, _message;
        --
        GET DIAGNOSTICS _insertCount = ROW_COUNT;

        If _insertCount = 0 Then
            _msg := format('Warning: log message not added to %s', _publicSchemaTargetTable);
            RAISE WARNING '%', _msg;
        End If;
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


ALTER PROCEDURE public.post_log_entry(IN _type text, IN _message text, IN _postedby text, IN _targetschema text, IN _duplicateentryholdoffhours integer, IN _ignoreerrors boolean, IN _logerrorstopubliclogtable boolean) OWNER TO d3l243;

