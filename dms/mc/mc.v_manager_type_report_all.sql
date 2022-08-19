--
-- Name: v_manager_type_report_all; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_manager_type_report_all AS
 SELECT DISTINCT mt.mgr_type_name AS manager_type,
    mt.mgr_type_id AS id
   FROM ((mc.t_mgr_types mt
     JOIN mc.t_mgrs m ON ((m.mgr_type_id = mt.mgr_type_id)))
     JOIN mc.t_param_value pv ON (((pv.mgr_id = m.mgr_id) AND (m.mgr_type_id = mt.mgr_type_id))));


ALTER TABLE mc.v_manager_type_report_all OWNER TO d3l243;

--
-- Name: TABLE v_manager_type_report_all; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.v_manager_type_report_all TO readaccess;
GRANT SELECT ON TABLE mc.v_manager_type_report_all TO writeaccess;

