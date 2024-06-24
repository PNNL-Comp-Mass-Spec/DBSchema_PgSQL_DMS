--
-- Name: update_run_interval_instrument_usage(integer, integer, boolean, text, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_run_interval_instrument_usage(IN _runintervalid integer, IN _daystoprocess integer DEFAULT 90, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Determine the instrument associated with the given run interval ID, then call update_dataset_interval_for_multiple_instruments(),
**      which calls update_dataset_interval() and update_emsl_instrument_usage_report()
**
**  Arguments:
**    _runIntervalId    Run interval ID, corresponding to dataset_id in t_run_interval
**    _daysToProcess    Used to determine the date range of datasets to process
**    _infoOnly         When true, preview updates
**    _message          Status message
**    _returnCode       Return code
**    _callingUser      Username of the calling user
**
**  Auth:   mem
**  Date:   02/15/2022 mem - Initial version
**          03/07/2024 mem - Ported to PostgreSQL
**          03/12/2024 mem - Show the message returned by verify_sp_authorized() when the user is not authorized to use this procedure
**          06/23/2024 mem - When verify_sp_authorized() returns false, wrap the Commit statement in an exception handler
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _instrumentName text;
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
        BEGIN
            -- Commit changes to persist the message logged to public.t_log_entries
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
            -- The commit failed, likely because this procedure was called from the DMS website, which wraps procedure calls in a transaction
            -- Ignore the commit error (t_log_entries will not be updated, but _message will be updated)
        END;

        If Coalesce(_message, '') = '' Then
            _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        End If;

        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN
        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        _runIntervalId := Coalesce(_runIntervalId, -1);
        _daysToProcess := Coalesce(_daysToProcess, 90);
        _infoOnly      := Coalesce(_infoOnly, false);
        _callingUser   := Trim(Coalesce(_callingUser, ''));

        If _callingUser = '' Then
            _callingUser := SESSION_USER;
        End If;

        If _runIntervalId < 0 Then
            _message := format('Invalid run interval ID: %s', _runIntervalId);
            RAISE WARNING '%', _message;

            _logErrors := false;
            RAISE EXCEPTION '%', _message;
        End If;

        -- Lookup the instrument associated with the run interval
        SELECT instrument
        INTO _instrumentName
        FROM t_run_interval
        WHERE dataset_id = _runIntervalId;

        If Not FOUND Then
            _message := format('Run Interval ID %s does not exist; cannot determine the instrument', _runIntervalId);
            RAISE WARNING '%', _message;

            _logErrors := false;
            RAISE EXCEPTION '%', _message;
        End If;

        If Not _infoOnly Then
            _message := format('Calling update_dataset_interval_for_multiple_instruments for instrument %s, calling user %s',
                                _instrumentName, _callingUser);

            RAISE INFO '%', _message;

            CALL post_log_entry ('Info', _message, 'Update_Run_Interval_Instrument_Usage');
        End If;

        CALL public.update_dataset_interval_for_multiple_instruments (
                        _daysToProcess             => _daysToProcess,
                        _updateEMSLInstrumentUsage => true,
                        _infoOnly                  => _infoOnly,
                        _instrumentsToProcess      => _instrumentName,
                        _message                   => _message,         -- Output
                        _returnCode                => _returnCode);     -- Output

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

END
$$;


ALTER PROCEDURE public.update_run_interval_instrument_usage(IN _runintervalid integer, IN _daystoprocess integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_run_interval_instrument_usage(IN _runintervalid integer, IN _daystoprocess integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_run_interval_instrument_usage(IN _runintervalid integer, IN _daystoprocess integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text, IN _callinguser text) IS 'UpdateRunIntervalInstrumentUsage';

