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
**      Updates the comments for long intervals to be 'Broken[100%]' for instruments with status 'broken'
**      See table t_run_interval
**
**  Arguments:
**    _targetDate   Date used to determine the target year and month to examine; if null, will examine the previous month
**    _infoOnly     When true, preview updates
**    _message      Output message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   05/12/2022 mem - Initial version
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
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
    _invalidUsage int;

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
    -- Validate the inputs
    ---------------------------------------------------

    BEGIN

        _targetDate := Coalesce(_targetDate, CURRENT_TIMESTAMP - INTERVAL '1 month');
        _infoOnly := Coalesce(_infoOnly, true);

        _targetMonth := Extract(month from _targetDate);
        _targetYear := Extract(year from _targetDate);

        -- Populate a string with the target month name and year
        _monthAndYear := format('%s %s', Trim(to_char(_targetDate, 'Month')), _targetYear);

        CREATE TEMP TABLE Tmp_BrokenInstruments (
            Instrument_ID int NOT NULL,
            Instrument text
        );

        CREATE TEMP TABLE Tmp_IntervalsToUpdate (
            IntervalID Int
        );

        INSERT INTO Tmp_BrokenInstruments(instrument_id, instrument )
        SELECT instrument_id, instrument
        FROM t_instrument_name
        WHERE status = 'Broken';

        _instrumentID := -1;
        _continue := true;

        FOR _instrumentID, _instrumentName IN
            SELECT Instrument_ID, Instrument
            FROM Tmp_BrokenInstruments
            ORDER BY Instrument_ID
        LOOP
            DELETE FROM Tmp_IntervalsToUpdate;

            INSERT INTO Tmp_IntervalsToUpdate( IntervalID )
            SELECT dataset_id
            FROM t_run_interval
            WHERE instrument = _instrumentName AND
                  Extract(month from start) = _targetMonth AND
                  Extract(year from start) = _targetYear AND
                  interval > 20000 AND
                  Coalesce(comment, '') = '';

            If Not FOUND Then
                _updateIntervals := false;

                If _infoOnly Then
                    _message := format('No unannotated long intervals were found for instrument %s in %s', _instrumentName, _monthAndYear);
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
                _intervalDescription := format('interval %s as Broken for instrument %s in %s',
                                                _runIntervalId, _instrumentName, _monthAndYear);

                If _infoOnly Then
                    RAISE INFO 'Preview: Call add_update_run_interval to annotate %', _intervalDescription;
                Else
                    CALL public.add_update_run_interval (
                                    _id           => _runIntervalID,
                                    _comment      => 'Broken[100%]',
                                    _mode         => 'update',
                                    _message      => _message,          -- Output
                                    _returnCode   => _returnCode,       -- Output
                                    _callingUser  => 'PNL\msdadmin (Auto_Annotate_Broken_Instrument_Long_Intervals)',
                                    _showdebug    => false,
                                    _invalidUsage => _invalidUsage);    -- Output

                    If _returnCode = '' Then
                        _message := format('Annotated %s', _intervalDescription);
                        CALL post_log_entry ('Normal', _message, 'Auto_Annotate_Broken_Instrument_Long_Intervals');
                    Else
                        _message := format('Error annotating %s', _intervalDescription);
                        CALL post_log_entry ('Error', _message, 'Auto_Annotate_Broken_Instrument_Long_Intervals');
                    End If;

                End If;

            END LOOP;

        END LOOP;

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
