--
-- Name: v_capture_script_detail_report; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_capture_script_detail_report AS
 SELECT t_scripts.script_id AS id,
    t_scripts.script,
    t_scripts.description,
    t_scripts.enabled,
    t_scripts.results_tag
   FROM cap.t_scripts;


ALTER TABLE cap.v_capture_script_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_capture_script_detail_report; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_capture_script_detail_report TO readaccess;
GRANT SELECT ON TABLE cap.v_capture_script_detail_report TO writeaccess;

