--
-- Name: v_capture_scripts; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_capture_scripts AS
 SELECT script_id AS id,
    script,
    description,
    enabled,
    results_tag,
    (contents)::public.citext AS contents
   FROM cap.t_scripts;


ALTER VIEW cap.v_capture_scripts OWNER TO d3l243;

--
-- Name: TABLE v_capture_scripts; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_capture_scripts TO readaccess;
GRANT SELECT ON TABLE cap.v_capture_scripts TO writeaccess;

