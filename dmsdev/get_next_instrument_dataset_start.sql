--
-- Name: get_next_instrument_dataset_start(integer, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_next_instrument_dataset_start(_instrumentid integer, _start timestamp without time zone) RETURNS timestamp without time zone
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return start time of first dataset that was run on given instrument after given time
**
**  Auth:   grk
**  Date:   05/16/2011
**          06/21/2022 mem - Ported to PostgreSQL
**          05/22/2023 mem - Capitalize reserved words
**
*****************************************************/
DECLARE
    _nextStartTime timestamp;
BEGIN
    SELECT acq_time_start
    INTO _nextStartTime
    FROM t_dataset
    WHERE instrument_id = _instrumentID AND
          acq_time_start > _start
    ORDER BY acq_time_start
    LIMIT 1;

    If FOUND Then
        RETURN _nextStartTime;
    Else
        RETURN _start;
    End If;
END
$$;


ALTER FUNCTION public.get_next_instrument_dataset_start(_instrumentid integer, _start timestamp without time zone) OWNER TO d3l243;

--
-- Name: FUNCTION get_next_instrument_dataset_start(_instrumentid integer, _start timestamp without time zone); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_next_instrument_dataset_start(_instrumentid integer, _start timestamp without time zone) IS 'GetNextInstrumentDatasetStart';

