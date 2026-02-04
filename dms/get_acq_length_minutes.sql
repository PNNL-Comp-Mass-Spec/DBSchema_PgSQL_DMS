--
-- Name: get_acq_length_minutes(timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_acq_length_minutes(_starttime timestamp without time zone, _endtime timestamp without time zone) RETURNS numeric
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/****************************************************
**
**  Desc:
**      Computes the acquisition length, in minutes; if _startTime or _endTime is null, returns 0
**
**      Acquisition length is rounded to two decimal points if less than 10 minutes, one decimal point if less than 100 minutes, otherwise rounded to the nearest minute
**
**  Arguments:
**    _startTime        Acquisition start time
**    _endTime          Acquisition end time
**
**  Example usage:
**      SELECT dataset,
**             get_acq_length_minutes(acq_time_start, acq_time_end)
**      FROM t_dataset
**      WHERE dataset_id BETWEEN 1200000 AND 1200100;
**
**  Auth:   mem
**  Date:   02/03/2026 mem - Initial release
**
*****************************************************/
DECLARE
    _acqLengthMinutes numeric;
BEGIN

    _acqLengthMinutes := COALESCE((EXTRACT(epoch FROM (_endTime - _startTime)) / 60.0), 0);

    If _acqLengthMinutes < 10 Then
        _acqLengthMinutes := Round(_acqLengthMinutes, 2);
    ElsIf _acqLengthMinutes < 100 Then
        _acqLengthMinutes := Round(_acqLengthMinutes, 1);
    Else
        _acqLengthMinutes := Round(_acqLengthMinutes, 0);
    End If;

    RETURN _acqLengthMinutes;
END
$$;


ALTER FUNCTION public.get_acq_length_minutes(_starttime timestamp without time zone, _endtime timestamp without time zone) OWNER TO d3l243;

