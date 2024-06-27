--
-- Name: get_disabled_processor_step_tool_list(text); Type: FUNCTION; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE FUNCTION sw.get_disabled_processor_step_tool_list(_processorname text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Build a comma-separated list of disabled step tools for the given processor
**
**  Arguments:
**    _processorName    Processor name
**
**  Returns:
**      Comma-separated list
**
**  Auth:   mem
**  Date:   06/27/2024 mem - Initial version (based on get_processor_step_tool_list)
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
    WHERE LP.processor_name = _processorName::citext AND
          PTGD.enabled <= 0;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION sw.get_disabled_processor_step_tool_list(_processorname text) OWNER TO d3l243;

