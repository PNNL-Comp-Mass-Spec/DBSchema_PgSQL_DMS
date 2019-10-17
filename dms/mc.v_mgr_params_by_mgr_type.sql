--
-- Name: v_mgr_params_by_mgr_type; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_mgr_params_by_mgr_type AS
 SELECT mt.mt_type_name AS mgrtype,
    pt.param_name
   FROM ((mc.t_param_type pt
     JOIN mc.t_mgr_type_param_type_map pm ON ((pt.param_id = pm.param_type_id)))
     JOIN mc.t_mgr_types mt ON ((pm.mgr_type_id = mt.mt_type_id)));


ALTER TABLE mc.v_mgr_params_by_mgr_type OWNER TO d3l243;

--
-- Name: TABLE v_mgr_params_by_mgr_type; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.v_mgr_params_by_mgr_type TO readaccess;
