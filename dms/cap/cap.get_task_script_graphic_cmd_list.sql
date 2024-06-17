--
-- Name: get_task_script_graphic_cmd_list(text); Type: FUNCTION; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE FUNCTION cap.get_task_script_graphic_cmd_list(_script text) RETURNS text
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Return Dot graphic command list (as text) for given script
**
**  Arguments:
**    _script   Capture task script name
**
**  Returns:
**      Semicolon-separated list
**
**  Auth:   grk
**  Date:   09/08/2009
**          06/24/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _result text;
BEGIN
    -- Note that each line returned by get_task_script_dot_format_table() should end in a semicolon
    SELECT string_agg(Src.script_line, '' ORDER BY src.seq, src.script_line)
    INTO _result
    FROM cap.get_task_script_dot_format_table(_script) as Src;

    RETURN Coalesce(_result, '');
END
$$;


ALTER FUNCTION cap.get_task_script_graphic_cmd_list(_script text) OWNER TO d3l243;

--
-- Name: FUNCTION get_task_script_graphic_cmd_list(_script text); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON FUNCTION cap.get_task_script_graphic_cmd_list(_script text) IS 'GetTaskScriptGraphicCmdList or GetJobScriptGraphicCmdList';

