--
-- Name: v_mgr_params; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_mgr_params AS
 SELECT pv.mgr_id AS manager_id,
    m.mgr_name AS manager_name,
    mt.mgr_type_name AS manager_type,
    pt.param_name AS parameter_name,
    pv.value AS parameter_value,
    pv.comment,
    pv.entry_id,
    pv.last_affected,
    pv.entered_by
   FROM (((mc.t_mgrs m
     JOIN mc.t_mgr_types mt ON ((m.mgr_type_id = mt.mgr_type_id)))
     JOIN mc.t_param_value pv ON ((m.mgr_id = pv.mgr_id)))
     JOIN mc.t_param_type pt ON ((pv.param_type_id = pt.param_type_id)));


ALTER VIEW mc.v_mgr_params OWNER TO d3l243;

--
-- Name: v_mgr_params trig_v_mgr_params_instead_of_update; Type: TRIGGER; Schema: mc; Owner: d3l243
--

CREATE TRIGGER trig_v_mgr_params_instead_of_update INSTEAD OF UPDATE ON mc.v_mgr_params FOR EACH ROW EXECUTE FUNCTION mc.trigfn_v_mgr_params_instead_of_update();

--
-- Name: TABLE v_mgr_params; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.v_mgr_params TO readaccess;
GRANT SELECT ON TABLE mc.v_mgr_params TO writeaccess;

