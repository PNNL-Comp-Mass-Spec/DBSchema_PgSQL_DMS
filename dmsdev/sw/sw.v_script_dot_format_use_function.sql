--
-- Name: v_script_dot_format_use_function; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_script_dot_format_use_function AS
 SELECT s.script,
    scriptlines.script_line AS line,
    scriptlines.seq
   FROM sw.t_scripts s,
    LATERAL ( SELECT get_task_script_dot_format_table.script_line,
            get_task_script_dot_format_table.seq
           FROM sw.get_task_script_dot_format_table((s.script)::text) get_task_script_dot_format_table(script_line, seq)) scriptlines;


ALTER VIEW sw.v_script_dot_format_use_function OWNER TO d3l243;

--
-- Name: TABLE v_script_dot_format_use_function; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_script_dot_format_use_function TO readaccess;
GRANT SELECT ON TABLE sw.v_script_dot_format_use_function TO writeaccess;

