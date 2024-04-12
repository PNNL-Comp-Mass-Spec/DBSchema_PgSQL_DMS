--
-- Name: get_next_instrument_dataset(integer, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_next_instrument_dataset(_instrumentid integer, _start timestamp without time zone) RETURNS integer
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return ID of first dataset that was run on given instrument after given time
**
**  Auth:   grk
**  Date:   05/16/2011
**          06/21/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _datasetID int;
BEGIN
    SELECT dataset_id
    INTO _datasetID
    FROM t_dataset
    WHERE instrument_id = _instrumentID AND
          acq_time_start > _start
    ORDER BY acq_time_start
    LIMIT 1;

    RETURN Coalesce(_datasetID, 0);
END
$$;


ALTER FUNCTION public.get_next_instrument_dataset(_instrumentid integer, _start timestamp without time zone) OWNER TO d3l243;

--
-- Name: FUNCTION get_next_instrument_dataset(_instrumentid integer, _start timestamp without time zone); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_next_instrument_dataset(_instrumentid integer, _start timestamp without time zone) IS 'GetNextInstrumentDataset';

