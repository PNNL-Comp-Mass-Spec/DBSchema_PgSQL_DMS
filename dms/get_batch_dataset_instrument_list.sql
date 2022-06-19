--
-- Name: get_batch_dataset_instrument_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_batch_dataset_instrument_list(_batchid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Builds delimited list of instruments for the datasets
**      associated with the given requested run batch
**
**  Return value: comma separated list
**
**  Auth:   mem
**  Date:   08/29/2010 mem - Initial version
**          03/29/2019 mem - Return an empty string when _batchID is 0 (meaning "unassigned", no batch)
**          06/18/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result text := '';
BEGIN
    SELECT string_agg(instrument, ', ' ORDER BY instrument)
    INTO _result
    FROM ( SELECT DISTINCT InstName.instrument AS Instrument
           FROM t_requested_run RR
                INNER JOIN t_dataset DS
                  ON RR.dataset_id = DS.dataset_id
                INNER JOIN t_instrument_name InstName
                  ON DS.instrument_id = InstName.instrument_id
           WHERE RR.batch_id = _batchID AND RR.batch_id <> 0
          ) LookupQ;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_batch_dataset_instrument_list(_batchid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_batch_dataset_instrument_list(_batchid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_batch_dataset_instrument_list(_batchid integer) IS 'GetBatchDatasetInstrumentList';

