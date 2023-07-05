--
CREATE OR REPLACE PROCEDURE public.add_bom_tracking_datasets
(
    _month text = '',
    _year text = '',
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text  = 'D3E154'
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds new tracking dataset for the first of the month
**      for all actively tracked instruments
**      for the given year and month
**
**      If _month is 'next', adds a tracking dataset for the beginning of the next month
**
**  Arguments:
**    _month         current month, if blank
**    _year          current year, if blank
**    _mode          'add, 'info' (just show instrument names), or 'debug' (call Add_BOM_Tracking_Dataset and preview tracking datasets)
**    _callingUser   Ron Moore
**
**  Auth:   grk
**  Date:   12/16/2012
**          12/16/2012 grk - Initial release
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          02/14/2022 mem - Assure that msg is not an empty string when _mode is 'debug'
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _instrumentName text;
    _entryID int;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Temp table to hold list of tracked instruments
    ---------------------------------------------------

    CREATE TEMP TABLE Tmp_TrackedInstruments (
        entry_id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        instrument text,
        msg text NULL,
        result text NULL
    );

    _mode := Lower(_mode);

    BEGIN

        ---------------------------------------------------
        -- Get list of tracked instruments
        ---------------------------------------------------

        INSERT INTO Tmp_TrackedInstruments (instrument)
        SELECT VT.Name
        FROM public.V_Instrument_Tracked VT;

        ---------------------------------------------------
        -- Loop through tracked instruments
        -- and try to make BOM tracking dataset for each
        ---------------------------------------------------

        FOR _entryID, _instrumentName IN
            SELECT entry_id, instrument
            FROM Tmp_TrackedInstruments
            ORDER BY Entry_ID
        LOOP

            If _mode::citext In ('debug', 'info') Then
                RAISE INFO '-> %', _instrumentName;
            End If;

            If _mode::citext In ('add', 'debug') Then
                CALL add_bom_tracking_dataset (
                        _month,
                        _year,
                        _instrumentName => _instrumentName,
                        _mode => _mode,
                        _message => _message,
                        _returnCode => _returnCode,
                        _callingUser => _callingUser);

                If _mode = 'debug' And Coalesce(_message, '') = '' Then
                    _message := 'Called Add_BOM_Tracking_Dataset with _mode=''debug''';
                End If;
            Else
                _message := '';
                _returnCode := '';
            End If;

            UPDATE Tmp_TrackedInstruments
            SET msg = _message,
                result = _returnCode,
            WHERE Entry_ID = _entryID;

        END LOOP;

        If _mode::citext In ('debug', 'info') Then

            -- ToDo: Preview results using RAISE INFO

            RAISE INFO '';

            _formatSpecifier := '%-10s %-10s %-10s %-10s %-10s';

            _infoHead := format(_formatSpecifier,
                                'abcdefg',
                                'abcdefg',
                                'abcdefg',
                                'abcdefg',
                                'abcdefg'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '---',
                                         '---',
                                         '---',
                                         '---',
                                         '---'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT entry_id,
                       instrument,
                       msg,
                       result
                FROM Tmp_TrackedInstruments
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.entry_jd,
                                    _previewData.instrument,
                                    _previewData.msg,
                                    _previewData.result
                                   );

                RAISE INFO '%', _infoData;
            END LOOP;

        End If;

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

    DROP TABLE IF EXISTS Tmp_TrackedInstruments;
END
$$;

COMMENT ON PROCEDURE public.add_bom_tracking_datasets IS 'AddBOMTrackingDatasets';
