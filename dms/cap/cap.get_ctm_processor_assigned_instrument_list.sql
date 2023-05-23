--
-- Name: get_ctm_processor_assigned_instrument_list(public.citext); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.get_ctm_processor_assigned_instrument_list(_processorname public.citext) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Builds delimited list of assigned instruments for the given processor
**
**  Return value: comma separated list
**
**  Auth:   grk
**  Date:   01/21/2010
**          06/28/2022 mem - Ported to PostgreSQL
**          04/02/2023 mem - Rename procedure and functions
**          05/22/2023 mem - Capitalize reserved word
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(instrument_name, ', ' ORDER BY instrument_name)
    INTO _result
    FROM cap.t_processor_instrument
    WHERE processor_name = _processorName AND enabled > 0;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION cap.get_ctm_processor_assigned_instrument_list(_processorname public.citext) OWNER TO d3l243;

--
-- Name: FUNCTION get_ctm_processor_assigned_instrument_list(_processorname public.citext); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON FUNCTION cap.get_ctm_processor_assigned_instrument_list(_processorname public.citext) IS 'GetProcessorAssignedInstrumentList';

