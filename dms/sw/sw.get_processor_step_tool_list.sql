--
-- Name: get_processor_step_tool_list(text); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.get_processor_step_tool_list(_processorname text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build a delimited list of step tools for the given processor
**
**  Returns:
**      Comma-separated list
**
**  Auth:   mem
**  Date:   03/30/2009
**          09/02/2009 mem - Now using T_Processor_Tool_Groups and T_Processor_Tool_Group_Details to determine the processor tool priorities for the given processor
**          06/26/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    SELECT string_agg(PTGD.tool_name, ', ' ORDER BY PTGD.tool_name)
    INTO _result
    FROM sw.t_machines M
         INNER JOIN sw.t_local_processors LP
           ON M.machine = LP.machine
         INNER JOIN sw.t_processor_tool_groups PTG
           ON M.proc_tool_group_id = PTG.group_id
         INNER JOIN sw.t_processor_tool_group_details PTGD
           ON PTG.group_id = PTGD.group_id AND
              LP.proc_tool_mgr_id = PTGD.mgr_id
    WHERE LP.processor_name = _processorName AND
          PTGD.enabled > 0;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION sw.get_processor_step_tool_list(_processorname text) OWNER TO d3l243;

--
-- Name: FUNCTION get_processor_step_tool_list(_processorname text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON FUNCTION sw.get_processor_step_tool_list(_processorname text) IS 'GetProcessorStepToolList';

