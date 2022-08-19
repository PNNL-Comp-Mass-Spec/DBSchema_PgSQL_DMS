--
-- Name: v_script_dot_format; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_script_dot_format AS
 SELECT s.script,
    scriptlines.script_line AS line,
    scriptlines.seq
   FROM cap.t_scripts s,
    LATERAL ( SELECT get_task_script_dot_format_table.script_line,
            get_task_script_dot_format_table.seq
           FROM cap.get_task_script_dot_format_table((s.script)::text) get_task_script_dot_format_table(script_line, seq)) scriptlines;


ALTER TABLE cap.v_script_dot_format OWNER TO d3l243;

--
-- Name: TABLE v_script_dot_format; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_script_dot_format TO readaccess;

