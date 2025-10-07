--
-- Name: resolve_start_and_end_dates(text, text, timestamp without time zone, timestamp without time zone, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.resolve_start_and_end_dates(IN _startdate text, IN _enddate text, INOUT _stdate timestamp without time zone DEFAULT NULL::timestamp without time zone, INOUT _edate timestamp without time zone DEFAULT NULL::timestamp without time zone, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Examine text arguments _startDate and _endDate to populate output arguments _stDate and _eDate with actual timestamp values
**      - If _startDate is empty, _stDate will be 2 weeks before _eDate
**      - If _endDate is empty, _eDate will be the end of the current day
**      - If _endDate is only year, month, and day, _eDate will span thru 23:59:59.999 on the given day
**
**  Arguments:
**    _startDate    Start date (as text)
**    _endDate      End date (as text)
**    _stDate       Output: start date (as a timestamp)
**    _eDate        Output: end date (as a timestamp)
**    _message      Status message
**    _returnCode   Return code
**
**  Date:   07/22/2019 mem - Initial version
**          12/12/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _eDateAlternate timestamp;
BEGIN
    _message := '';
    _returnCode := '';

    --------------------------------------------------------------------
    -- If _endDate is empty, auto-set to the end of the current day
    --------------------------------------------------------------------

    If Trim(Coalesce(_endDate, '')) = '' Then
        _eDateAlternate := date_trunc('day', CURRENT_TIMESTAMP) + Interval '86399.999 seconds';

        _endDate := (_eDateAlternate::timestamp without time zone)::text;
    End If;

    --------------------------------------------------------------------
    -- Check whether _endDate only contains year, month, and day
    --------------------------------------------------------------------

    _eDate := public.try_cast(_endDate, null::timestamp);

    If _eDate Is Null Then
        _message := format('End date "%s" is not a valid date', _endDate);
        _returnCode := 'U52021';
        RETURN;
    End If;

    _eDateAlternate := date_trunc('day', _eDate);

    If _eDate = _eDateAlternate Then
        -- _endDate only specified year, month, and day
        -- Update _eDate to span thru 23:59:59.999 on the given day

        _eDate := _eDateAlternate + Interval '86399.999 seconds';
    End If;

    --------------------------------------------------------------------
    -- If _startDate is empty, auto-set to 2 weeks before _eDate
    --------------------------------------------------------------------

    If Trim(Coalesce(_startDate, '')) = '' Then
        _stDate := date_trunc('day', _eDate) - Interval '2 weeks';
    Else
        _stDate := public.try_cast(_startDate, null::timestamp);

        If _stDate Is Null Then
            _message := format('Start date "%s" is not a valid date', _startDate);
            _returnCode := 'U5202';
            RETURN;
        End If;

    End If;
END
$$;


ALTER PROCEDURE public.resolve_start_and_end_dates(IN _startdate text, IN _enddate text, INOUT _stdate timestamp without time zone, INOUT _edate timestamp without time zone, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE resolve_start_and_end_dates(IN _startdate text, IN _enddate text, INOUT _stdate timestamp without time zone, INOUT _edate timestamp without time zone, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.resolve_start_and_end_dates(IN _startdate text, IN _enddate text, INOUT _stdate timestamp without time zone, INOUT _edate timestamp without time zone, INOUT _message text, INOUT _returncode text) IS 'ResolveStartAndEndDates';

