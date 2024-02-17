--
-- Name: report_dataset_instrument_runtime(text, text, text, text, text, text, refcursor); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.report_dataset_instrument_runtime(IN _startdate text DEFAULT ''::text, IN _enddate text DEFAULT ''::text, IN _instrumentname text DEFAULT 'Lumos01'::text, IN _reportoptions text DEFAULT 'Show All'::text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, INOUT _results refcursor DEFAULT '_results'::refcursor)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Generate dataset runtime and interval statistics for specified instrument
**
**  Arguments:
**    _startDate        Start date; if an empty string, will use 2 weeks before _endDate
**    _endDate          End date; if an empty string, will use today as end date
**    _instrumentName   Instrument name
**    _reportOptions    'Show All', 'No Intervals', 'Intervals Only', or 'Long Intervals'
**    _message          Status message
**    _returnCode       Return code
**    _results          Output: RefCursor for viewing the results
**
**  Use this to view the data returned by the _results cursor
**  Note that this will result in an error if no matching items are found
**
**      BEGIN;
**          CALL public.report_dataset_instrument_runtime (
**                      _startDate      => '2023-01-01',
**                      _endDate        => '2023-01-30',
**                      _instrumentName => 'Lumos01',
**                      _reportOptions  => 'Show All'
**               );
**          FETCH ALL FROM _results;
**      END;
**
**  Auth:   grk
**  Date:   05/26/2011 grk - Initial release
**          01/31/2012 grk - Added Interval column to output and made separate interval rows an option
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          07/18/2023 mem - Ported to PostgreSQL
**          09/08/2023 mem - Include schema name when calling function verify_sp_authorized()
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
    _message := '';
    _returnCode := '';

    BEGIN

        --------------------------------------------------------------------
        -- If _endDate is empty, auto-set to the end of the current day
        --------------------------------------------------------------------

        If Trim(Coalesce(_endDate, '')) = '' Then
            _eDateAlternate := date_trunc('day', CURRENT_TIMESTAMP) + Interval '86399.999 seconds';

            -- Convert to text, e.g. 2022-10-21 23:59:59.999
            _endDate := (_eDateAlternate::timestamp without time zone)::text;

        Else
            If public.try_cast(_endDate, null::timestamp) Is Null Then
                _msg := format('End date "%s" is not a valid date', _endDate);
                RAISE EXCEPTION '%', _msg;
            End If;
        End If;

        --------------------------------------------------------------------
        -- Check whether _endDate only contains year, month, and day
        --------------------------------------------------------------------

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

        If Coalesce(_startDate, '') = '' Then
            _stDate := date_trunc('day', _eDate) - Interval '2 weeks';
        Else
            _stDate := public.try_cast(_startDate, null::timestamp);

            If _stDate Is Null Then
                _msg := format('Start date "%s" is not a valid date', _startDate);
                RAISE EXCEPTION '%', _msg;
            End If;
        End If;

        ---------------------------------------------------
        -- Generate report
        ---------------------------------------------------

        -- Note that get_dataset_instrument_runtime() converts:
        --   start date (_stDate) to the first day of the month
        --   end date   (_eDate)  to the first day of the next month

        Open _results For
            SELECT Src.seq,
                   Src.id,
                   Src.dataset,
                   Src.state,
                   Src.rating,
                   Src.duration,
                   Src."interval",
                   Src.time_start,
                   Src.time_end,
                   Src.request,
                   Src.eus_proposal,
                   Src.eus_usage,
                   Src.eus_proposal_type,
                   Src.work_package,
                   Src.lc_column,
                   Src.instrument,
                   Src.campaign_id,
                   Src.fraction_emsl_funded,
                   Src.campaign_proposals
            FROM public.get_dataset_instrument_runtime(_stDate, _eDate, _instrumentName::citext, _reportOptions::citext) AS Src
            ORDER BY Src.Seq;

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


ALTER PROCEDURE public.report_dataset_instrument_runtime(IN _startdate text, IN _enddate text, IN _instrumentname text, IN _reportoptions text, INOUT _message text, INOUT _returncode text, INOUT _results refcursor) OWNER TO d3l243;

--
-- Name: PROCEDURE report_dataset_instrument_runtime(IN _startdate text, IN _enddate text, IN _instrumentname text, IN _reportoptions text, INOUT _message text, INOUT _returncode text, INOUT _results refcursor); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.report_dataset_instrument_runtime(IN _startdate text, IN _enddate text, IN _instrumentname text, IN _reportoptions text, INOUT _message text, INOUT _returncode text, INOUT _results refcursor) IS 'ReportDatasetInstrumentRunTime';

