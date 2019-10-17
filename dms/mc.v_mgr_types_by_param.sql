--
-- Name: v_mgr_types_by_param; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_mgr_types_by_param AS
 SELECT DISTINCT pt.param_name,
    mt.mt_type_name
   FROM ((mc.t_mgr_type_param_type_map pm
     JOIN mc.t_mgr_types mt ON ((pm.mgr_type_id = mt.mt_type_id)))
     JOIN mc.t_param_type pt ON ((pm.param_type_id = pt.param_id)));


ALTER TABLE mc.v_mgr_types_by_param OWNER TO d3l243;

--
-- Name: TABLE v_mgr_types_by_param; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.v_mgr_types_by_param TO readaccess;
