--
-- Name: v_manager_type_report_all; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_manager_type_report_all AS
 SELECT DISTINCT mt.mt_type_name AS "Manager Type",
    mt.mt_type_id AS id
   FROM ((mc.t_mgr_types mt
     JOIN mc.t_mgrs m ON ((m.m_type_id = mt.mt_type_id)))
     JOIN mc.t_param_value pv ON (((pv.mgr_id = m.m_id) AND (m.m_type_id = mt.mt_type_id))));


ALTER TABLE mc.v_manager_type_report_all OWNER TO d3l243;

--
-- Name: TABLE v_manager_type_report_all; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.v_manager_type_report_all TO readaccess;
