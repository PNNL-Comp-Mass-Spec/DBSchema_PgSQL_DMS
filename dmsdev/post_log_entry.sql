CREATE OR REPLACE PROCEDURE public.post_log_entry(IN _type text, IN _message text, IN _postedby text DEFAULT 'na'::text, IN _targetschema text DEFAULT 'public'::text, IN _duplicateentryholdoffhours integer DEFAULT 0)
 LANGUAGE plpgsql
AS $procedure$
/****************************************************
**
**  Desc:
**      Append a log entry to T_Log_Entries, either in the public schema or the specified schema
**
**  Arguments:
**    _type                         Message type, typically Normal, Warning, Error, or Progress, but can be any text value
**    _message                      Log message
**    _postedBy                     Name of the calling procedure
**    _targetSchema                 If blank or 'public', log to public.T_Log_Entries; otherwise, log to T_Log_Entries for the given schema (assumes the table exists)
**    _duplicateEntryHoldoffHours   Set this to a value greater than 0 to prevent duplicate entries being posted within the given number of hours
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
**
*****************************************************/
DECLARE
    _targetTableWithSchema text;
    _minimumPostingTime timestamp;
    _duplicateRowCount int := 0;
    _s text;
    _myRowCount int;
    _warningMessage text;
BEGIN

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _targetSchema := COALESCE(_targetSchema, '');
    If (char_length(_targetSchema) = 0) Then
        _targetSchema := 'public';
    End If;

    _targetTableWithSchema := format('%I.%I', _targetSchema, 't_log_entries');

    _type := Coalesce(_type, 'Normal');
    _message := Coalesce(_message, '');
    _postedBy := Coalesce(_postedBy, 'na');

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
                'SELECT COUNT(*) '
                'FROM %s '
                'WHERE message = $1 AND '
                     ' type = $2 AND '
                     ' posting_time >= $3',
                _targetTableWithSchema);

        EXECUTE _s INTO _duplicateRowCount USING _message, _type, _minimumPostingTime;

    End If;

    If _duplicateRowCount > 0 THEN
        RAISE Info 'Skipping recently logged message; duplicate count: %', _duplicateRowCount;
        RETURN;
    End If;

    _s := format(
            'INSERT INTO %s (posted_by, posting_time, type, message)'
            'VALUES ( $1, CURRENT_TIMESTAMP, $2, $3)',
            _targetTableWithSchema);

    EXECUTE _s USING _postedBy, _type, _message;
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _myRowCount = 0 Then
        _warningMessage := 'Warning: log message not added to ' || _targetTableWithSchema;
        RAISE WARNING '%', _warningMessage;
    End If;

END
$procedure$
;
