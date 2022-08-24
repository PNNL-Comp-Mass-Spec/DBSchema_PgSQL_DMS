--
-- Name: local_error_handler(text, text, text, text, text, text, text, boolean, boolean, integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.local_error_handler(_sqlstate text, _exceptionmessage text, _exceptiondetail text, _exceptioncontext text, _callingproclocation text DEFAULT ''::text, _callingprocname text DEFAULT '<AutoDetermine>'::text, _callingprocschema text DEFAULT '<AutoDetermine>'::text, _logerror boolean DEFAULT false, _displayerror boolean DEFAULT false, _duplicateentryholdoffhours integer DEFAULT 0) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      This function should be called after using GET STACKED DIAGNOSTICS
**      It will generate an error description and optionally log the error
**
**  Arguments:
**    _sqlState                     SQL State
**    _exceptionMessage             Exception message
**    _exceptionDetail              Exception detail
**    _exceptionContext             Exception context, e.g. PL/pgSQL function test.test_exception_handler(text,boolean) line 35 at RAISE
**    _callingProcLocation          Most recent location in the calling procedure (optional)
**    _callingProcName              Calling procedure name; will auto-determine using _exceptionContext if '<AutoDetermine>' or ''
**    _callingProcSchema            Calling procedure schema; will auto-determine using resolve_table_name if '<AutoDetermine>' or ''
**    _logError                     If true, log the error in the t_log_entries table that corresponds to the calling procedure's schema (or public.t_log_entries if the given schema does not have table t_log_entries)
**    _displayError                 If true, show the formatted error message using RAISE Warning
**    _duplicateEntryHoldoffHours   Set this to a value greater than 0 to prevent duplicate entries being posted within the given number of hours
**
**  Example usage:
**        EXCEPTION
**            WHEN OTHERS THEN
**                GET STACKED DIAGNOSTICS
**                    _sqlState         = returned_sqlstate,         -- P0001
**                    _exceptionMessage = message_text,              -- Value is not numeric: apple
**                    _exceptionDetail  = pg_exception_detail,
**                    _exceptionContext = pg_exception_context;      -- PL/pgSQL function test.test_exception_handler(text,boolean) line 40 at RAISE
**
**            _message := local_error_handler (
**                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
**                            _currentLocation, _logError => true);
**
**  Auth:   mem
**  Date:   11/30/2006
**          01/03/2008 mem - Added parameter @duplicateEntryHoldoffHours
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          03/15/2021 mem - Treat @errorNum as an input/output parameter
**          08/24/2022 mem - Ported to PostgreSQL
**
****************************************************/
DECLARE
    _message text;
    _innerExceptionMessage text;
BEGIN

    -----------------------------------------------
    -- Validate the inputs
    -----------------------------------------------
    _sqlState            := Coalesce(_sqlState, '');
    _exceptionMessage    := Coalesce(_exceptionMessage, '');
    _exceptionDetail     := Coalesce(_exceptionDetail, '');
    _exceptionContext    := Coalesce(_exceptionContext, '');
    _callingProcLocation := Trim(Coalesce(_callingProcLocation, ''));
    _callingProcName     := Trim(Coalesce(_callingProcName, ''));
    _callingProcSchema   := Trim(Coalesce(_callingProcSchema, ''));
    _logError            := Coalesce(_logError, false);
    _displayError        := Coalesce(_displayError, false);
    _duplicateEntryHoldoffHours := Coalesce(_duplicateEntryHoldoffHours, 0);

    If (_callingProcName = '' Or
        _callingProcName::citext = '<AutoDetermine>'::citext Or
        _callingProcSchema::citext = '<AutoDetermine>'::citext
       ) AND
       char_length(_exceptionContext) > 0 Then

        -- Use _exceptionContext to resolve the function or procedure name

        SELECT schema_name, object_name
        INTO _callingProcSchema, _callingProcName
        FROM public.get_call_stack(_exceptionContext)
        ORDER BY depth DESC
        LIMIT 1;

        If Not FOUND Then
            _callingProcSchema := '';
            _callingProcName := 'Undefined_Function';
        End If;
    End If;

    _message := 'Error caught in ' || _callingProcName;

    If char_length(_callingProcLocation) > 0 Then
        _message := _message || ' at "' || _callingProcLocation || '"';
    End If;

    _message := format('%s; %s',
                        _message,
                        format_error_message(_sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext));

    If _displayError Then
        RAISE Warning '%', _message;
    End If;

    -- RAISE Warning 'Context: %', _exceptionContext;

    -- Rollback any open transactions
    -- Note that PostgreSQL doesn't assign a transaction ID until a write operation occurs
    If Not pg_current_xact_id_if_assigned() Is Null Then
        ROLLBACK;
    End If;

    If _logError Then
        Call public.post_log_entry ('Error', _message, _callingProcName, _callingProcSchema, _duplicateEntryHoldoffHours, _ignoreErrors => true);
    End If;

    Return _message;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            _innerExceptionMessage = message_text;

    _message := format('Error in local_error_handler: %s; calling method exception: %s',
                        Coalesce(_innerExceptionMessage, '??'),
                        Coalesce(_exceptionMessage, '??'));

    RAISE Warning '%', _message;
    Return _message;
END
$$;


ALTER FUNCTION public.local_error_handler(_sqlstate text, _exceptionmessage text, _exceptiondetail text, _exceptioncontext text, _callingproclocation text, _callingprocname text, _callingprocschema text, _logerror boolean, _displayerror boolean, _duplicateentryholdoffhours integer) OWNER TO d3l243;

