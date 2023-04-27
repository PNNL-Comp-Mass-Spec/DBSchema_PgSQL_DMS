--
CREATE OR REPLACE PROCEDURE public.report_dataset_instrument_runtime
(
    _startDate text = '',
    _endDate text = '',
    _instrumentName text = 'Exact01',
    _reportOptions text = 'Show All',
    INOUT _message text
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Generates dataset runtime and interval
**      statistics for specified instrument
**
**  Arguments:
**    _reportOptions   'No Intervals', 'Intervals Only'
**
**  Auth:   grk
**  Date:   05/26/2011 grk - initial release
**          01/31/2012 grk - Added Interval column to output and made separate interval rows an option
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _weeksInRange int;
    _stDate timestamp;
    _eDate timestamp;
    _msg text;
    _eDateAlternate timestamp;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    BEGIN

        _message := '';

        --------------------------------------------------------------------
        -- If _endDate is empty, auto-set to the end of the current day
        --------------------------------------------------------------------
        --
        If Trim(Coalesce(_endDate, '')) = '' Then
            _eDateAlternate := date_trunc('day', CURRENT_TIMESTAMP) + Interval '86399.999 seconds';

            -- Convert to text, e.g. 2022-10-21 23:59:59.999
            _endDate := (_eDateAlternate::timestamp without time zone)::text

        Else
            -- IsDate() equivalent
            If public.try_cast(_endDate, null::timestamp) Is Null Then
                _msg := 'End date "' || _endDate || '" is not a valid date';
                RAISE EXCEPTION '%', _msg;
            End If;
        End If;

        --------------------------------------------------------------------
        -- Check whether _endDate only contains year, month, and day
        --------------------------------------------------------------------
        --
        _eDate := public.try_cast(_endDate, CURRENT_TIMESTAMP);

        _eDateAlternate := date_trunc('day', _eDate);

        If _eDate = _eDateAlternate Then
            -- _endDate only specified year, month, and day
            -- Update _eDateAlternate to span thru 23:59:59.999 on the given day,
            -- then copy that value to _eDate

            _eDateAlternate := _eDateAlternate + Interval '86399.999 seconds';
            _eDate := _eDateAlternate;
        End If;

        --------------------------------------------------------------------
        -- If _startDate is empty, auto-set to 2 weeks before _eDate
        --------------------------------------------------------------------
        --
        If Coalesce(_startDate, '') = '' Then
            _stDate := date_trunc('day', _eDate) - Interval '2 weeks';
        Else
            _stDate := public.try_cast(_startDate, null::timestamp);

            If _stDate Is Null Then
                _msg := 'Start date "' || _startDate || '" is not a valid date';
                RAISE EXCEPTION '%', _msg;
            End If;
        End If;

        ---------------------------------------------------
        -- Generate report
        ---------------------------------------------------

        SELECT *
        FROM get_dataset_instrument_runtime(_stDate, _eDate, _instrumentName, _reportOptions)
        ORDER BY Seq

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

END
$$;

COMMENT ON PROCEDURE public.report_dataset_instrument_runtime IS 'ReportDatasetInstrumentRunTime';


----------------------------------------------
-- ToDo: Create procedure report_production_stats_proc with the same arguments as function report_production_stats
--       The procedure should use a cursor to return the results from querying report_production_stats, only including column proposal_type if _includeProposalType > 0
----------------------------------------------

