--
CREATE OR REPLACE PROCEDURE public.auto_annotate_broken_instrument_long_intervals
(
    _targetDate timestamp,
    _infoOnly boolean = true,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the comments for long intervals in table T_Run_Interval
**      to be 'Broken[100%]' for instruments with status 'broken'
**
**  Arguments:
**    _targetDate   Date used to determine the target year and month to examine; if null, will examine the previous month
**
**  Auth:   mem
**  Date:   05/12/2022 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized boolean;

    _targetMonth int;
    _targetYear int;
    _monthAndYear text;
    _intervalDescription text;
    _continue boolean;
    _updateIntervals boolean;
    _instrumentID int;
    _instrumentName text;
    _runIntervalID int;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode:= '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Validate inputs
    ---------------------------------------------------

    BEGIN

        _targetDate := Coalesce(_targetDate, CURRENT_TIMESTAMP - INTERVAL '1 month');
        _infoOnly := Coalesce(_infoOnly, true);

        _targetMonth := Extract(month from _targetDate);
        _targetYear := Extract(year from _targetDate);

        -- Populate a string with the target month name and year
        _monthAndYear := DateName(month, _targetDate) || ' ' || Cast(_targetYear As text);

        CREATE TEMP TABLE Tmp_BrokenInstruments (
            Instrument_ID int NOT NULL,
            Instrument text
        )

        CREATE TEMP TABLE Tmp_IntervalsToUpdate (
            IntervalID Int
        )

        INSERT INTO Tmp_BrokenInstruments(instrument_id, instrument )
        SELECT instrument_id, instrument
        FROM t_instrument_name
        WHERE status = 'Broken'

        _instrumentID := -1;
        _continue := true;

        FOR _instrumentID, _instrumentName IN
            SELECT Instrument_ID, Instrument
            FROM Tmp_BrokenInstruments
            ORDER BY Instrument_ID
        LOOP
            DELETE FROM Tmp_IntervalsToUpdate

            INSERT INTO Tmp_IntervalsToUpdate( IntervalID )
            SELECT interval_id
            FROM t_run_interval
            WHERE instrument = _instrumentName AND
                  Extract(month from start) = _targetMonth AND
                  Extract(year from start) = _targetYear AND
                  interval > 20000 AND
                  Coalesce(comment, '') = '';

            If Not FOUND Then
                _updateIntervals := false;

                If _infoOnly Then
                    _message := 'No unannotated long intervals were found for instrument ' || _instrumentName || ' in ' || _monthAndYear;
                    RAISE INFO '%', _message;
                End If;
            Else
                _updateIntervals := true;
            End If;

            If Not _updateIntervals Then
                CONTINUE;
            End If;

            FOR _runIntervalID IN
                SELECT IntervalID
                FROM Tmp_IntervalsToUpdate
                ORDER BY IntervalID
            LOOP
                _intervalDescription := 'interval ' || Cast(_runIntervalId As text) || ' as Broken for instrument ' || _instrumentName || ' in ' || _monthAndYear;

                If _infoOnly Then
                    RAISE INFO '%', 'Preview: Call add_update_run_interval to annotate ' || _intervalDescription;
                Else
                    Call add_update_run_interval (
                                _runIntervalID,
                                'Broken[100%]',
                                'update',
                                _message => _message,       -- Output
                                _callingUser => 'PNL\msdadmin (Auto_Annotate_Broken_Instrument_Long_Intervals)');

                    If _returnCode = '' Then
                        _message := 'Annotated ' || _intervalDescription;
                        Call post_log_entry ('Normal', _message, 'Auto_Annotate_Broken_Instrument_Long_Intervals');
                    Else
                        _message := 'Error annotating ' || _intervalDescription;
                        Call post_log_entry ('Error', _message, 'Auto_Annotate_Broken_Instrument_Long_Intervals');
                    End If;

                End If;

            END LOOP

        END LOOP; -- </a>

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

    DROP TABLE IF EXISTS Tmp_BrokenInstruments;
    DROP TABLE IF EXISTS Tmp_IntervalsToUpdate;
END
$$;

COMMENT ON PROCEDURE public.auto_annotate_broken_instrument_long_intervals IS 'AutoAnnotateBrokenInstrumentLongIntervals';
