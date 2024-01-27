--
-- Name: auto_annotate_broken_instrument_long_intervals(timestamp without time zone, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.auto_annotate_broken_instrument_long_intervals(IN _targetdate timestamp without time zone, IN _infoonly boolean DEFAULT true, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update the comments for long intervals to be 'Broken[100%]' for instruments with status 'broken'
**      See table t_run_interval
**
**  Arguments:
**    _targetDate   Date used to determine the target year and month to examine; if null, will examine the previous month
**    _infoOnly     When true, preview updates
**    _message      Status message
**    _returnCode   Return code
**
**  Auth:   mem
**  Date:   05/12/2022 mem - Initial version
**          01/26/2024 mem - Ported to PostgreSQL
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
    _instrumentID int;
    _instrumentName citext;
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

        _targetDate  := Coalesce(_targetDate, CURRENT_TIMESTAMP - INTERVAL '1 month');
        _infoOnly    := Coalesce(_infoOnly, true);

        _targetMonth := Extract(month from _targetDate);
        _targetYear  := Extract(year  from _targetDate);

        -- Populate a string with the target month name and year, e.g. January 2024
        _monthAndYear := format('%s %s', Trim(to_char(_targetDate, 'Month')), _targetYear);

        CREATE TEMP TABLE Tmp_IntervalsToUpdate (
            IntervalID Int
        );

        FOR _instrumentID, _instrumentName IN
            SELECT instrument_id, instrument
            FROM t_instrument_name
            WHERE status = 'Broken'
            ORDER BY instrument_id
        LOOP
            DELETE FROM Tmp_IntervalsToUpdate;

            -- Note that interval ID is same as dataset ID
            INSERT INTO Tmp_IntervalsToUpdate (IntervalID)
            SELECT I.dataset_id
            FROM t_run_interval I
            WHERE I.instrument = _instrumentName AND
                  Extract(month from I.start) = _targetMonth AND
                  Extract(year  from I.start) = _targetYear AND
                  I.interval > 20000 AND
                  Trim(Coalesce(I.comment, '')) = '';

            If Not FOUND Then
                If _infoOnly Then
                    _message := format('No unannotated long intervals were found for instrument %s in %s', _instrumentName, _monthAndYear);
                    RAISE INFO '%', _message;
                End If;

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

        DROP TABLE Tmp_IntervalsToUpdate;
        RETURN;

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

    DROP TABLE IF EXISTS Tmp_IntervalsToUpdate;
END
$$;


ALTER PROCEDURE public.auto_annotate_broken_instrument_long_intervals(IN _targetdate timestamp without time zone, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE auto_annotate_broken_instrument_long_intervals(IN _targetdate timestamp without time zone, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.auto_annotate_broken_instrument_long_intervals(IN _targetdate timestamp without time zone, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'AutoAnnotateBrokenInstrumentLongIntervals';

