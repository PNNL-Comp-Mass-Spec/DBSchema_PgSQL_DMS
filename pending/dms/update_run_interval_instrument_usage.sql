--
CREATE OR REPLACE PROCEDURE public.update_run_interval_instrument_usage
(
    _runIntervalId int,
    _daysToProcess Int = 90,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Determines the instrument associated with the given run interval ID
**      then calls Update_Dataset_Interval_For_Multiple_Instruments
**      (which calls Update_Dataset_Interval and Update_EMSL_Instrument_Usage_Report)
**
**  Auth:   mem
**  Date:   02/15/2022 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _nameWithSchema text;
    _authorized boolean;

    _instrumentName text;
    _logErrors boolean := false;

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

    _runIntervalId := Coalesce(_runIntervalId, -1);
    _daysToProcess := Coalesce(_daysToProcess, 90);
    _infoOnly := Coalesce(_infoOnly, false);

    _callingUser := Coalesce(_callingUser, '');
    If _callingUser = '' Then
        _callingUser := session_user;
    End If;

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

    BEGIN

        If _runIntervalId < 0 Then
            _message := format('Invalid run interval ID: %s', _runIntervalId);
            RAISE EXCEPTION '%', _message;
        End If;

        -- Lookup the instrument associated with the run interval
        SELECT instrument INTO _instrumentName
        FROM t_run_interval
        WHERE interval_id = _runIntervalId

        If _returnCode <> '' OR Coalesce(_instrumentName, '') = '' Then
            _message := format('Run Interval ID %s does not exist; cannot determine the instrument', _runIntervalId);
            RAISE EXCEPTION '%', _message;
        End If;

        _logErrors := true;

        If Not _infoOnly Then
            _message := format('Calling update_dataset_interval_for_multiple_instruments for instrument %s, calling user %s',
                                _instrumentName, _callingUser);

            CALL post_log_entry ('Info', _message, 'Update_Run_Interval_Instrument_Usage');
        End If;

        CALL update_dataset_interval_for_multiple_instruments (
                _daysToProcess => _daysToProcess,
                _updateEMSLInstrumentUsage => true,
                _infoOnly => _infoOnly,
                _instrumentsToProcess => _instrumentName,
                _message => _message,               -- Output
                _returnCode => _returnCode);        -- Output

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

COMMENT ON PROCEDURE public.update_run_interval_instrument_usage IS 'UpdateRunIntervalInstrumentUsage';
