--
-- Name: get_aj_processor_analysis_tool_list(integer); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_aj_processor_analysis_tool_list(_processorid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build delimited list of analysis tools for given analysis job processor ID
**
**  Arguments:
**    _processorID      Processor ID
**
**  Returns:
**      Comma-separated list
**
**  Auth:   grk
**  Date:   02/23/2007 (Ticket 389)
**          03/15/2007 mem - Increased size of _result to varchar(4000); now ordering by tool name
**          03/30/2009 mem - Now using Coalesce to generate the comma-separated list
**          06/17/2022 mem - Ported to PostgreSQL
**          05/19/2023 mem - Remove redundant parentheses
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(T.analysis_tool, ', ' ORDER BY T.analysis_tool)
    INTO _result
    FROM t_analysis_job_processor_tools AJPT INNER JOIN
          t_analysis_tool T ON AJPT.tool_id = T.analysis_tool_id
    WHERE AJPT.processor_id = _processorID;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION public.get_aj_processor_analysis_tool_list(_processorid integer) OWNER TO d3l243;

--
-- Name: FUNCTION get_aj_processor_analysis_tool_list(_processorid integer); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON FUNCTION public.get_aj_processor_analysis_tool_list(_processorid integer) IS 'GetAJProcessorAnalysisToolList';

