--
-- Name: v_capture_script_entry; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_capture_script_entry AS
 SELECT t_scripts.script_id AS id,
    t_scripts.script,
    t_scripts.description,
    t_scripts.enabled,
    t_scripts.results_tag,
    t_scripts.contents
   FROM cap.t_scripts;


ALTER VIEW cap.v_capture_script_entry OWNER TO d3l243;

--
-- Name: TABLE v_capture_script_entry; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_capture_script_entry TO readaccess;
GRANT SELECT ON TABLE cap.v_capture_script_entry TO writeaccess;

