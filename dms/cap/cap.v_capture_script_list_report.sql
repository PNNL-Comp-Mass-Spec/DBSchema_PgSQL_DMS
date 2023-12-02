--
-- Name: v_capture_script_list_report; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_capture_script_list_report AS
 SELECT t_scripts.script,
    t_scripts.description,
    t_scripts.enabled,
    t_scripts.results_tag,
    t_scripts.script_id AS id
   FROM cap.t_scripts;


ALTER VIEW cap.v_capture_script_list_report OWNER TO d3l243;

--
-- Name: TABLE v_capture_script_list_report; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_capture_script_list_report TO readaccess;
GRANT SELECT ON TABLE cap.v_capture_script_list_report TO writeaccess;

