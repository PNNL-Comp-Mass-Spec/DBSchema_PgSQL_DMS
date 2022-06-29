--
-- Name: get_processor_step_tool_list(public.citext); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.get_processor_step_tool_list(_processorname public.citext) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Builds delimited list of step tools for the given processor
**
**  Return value: comma separated list
**
**  Auth:   mem
**  Date:   03/30/2009
**          06/28/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(tool_name, ', ' ORDER BY tool_name)
    INTO _result
    FROM cap.t_processor_tool
    WHERE processor_name = _processorName AND enabled > 0;

    Return Coalesce(_result, '');
END
$$;


ALTER FUNCTION cap.get_processor_step_tool_list(_processorname public.citext) OWNER TO d3l243;

--
-- Name: FUNCTION get_processor_step_tool_list(_processorname public.citext); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON FUNCTION cap.get_processor_step_tool_list(_processorname public.citext) IS 'GetProcessorStepToolList';

