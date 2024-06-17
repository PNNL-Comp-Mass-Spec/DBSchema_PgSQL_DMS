--
-- Name: get_ctm_processor_step_tool_list(text); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.get_ctm_processor_step_tool_list(_processorname text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build delimited list of step tools for the given processor
**
**  Arguments:
**    _processorName    Processor name
**
**  Returns:
**      Comma-separated list
**
**  Auth:   mem
**  Date:   03/30/2009
**          06/28/2022 mem - Ported to PostgreSQL
**          04/02/2023 mem - Rename procedure and functions
**          05/22/2023 mem - Capitalize reserved word
**          01/21/2024 mem - Change data type of argument _processorName to text
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(tool_name, ', ' ORDER BY tool_name)
    INTO _result
    FROM cap.t_processor_tool
    WHERE processor_name = _processorName::citext AND enabled > 0;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION cap.get_ctm_processor_step_tool_list(_processorname text) OWNER TO d3l243;

--
-- Name: FUNCTION get_ctm_processor_step_tool_list(_processorname text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON FUNCTION cap.get_ctm_processor_step_tool_list(_processorname text) IS 'GetProcessorStepToolList';

