--
-- Name: v_mgr_params; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_mgr_params AS
 SELECT pv.mgr_id AS managerid,
    m.mgr_name AS managername,
    mt.mgr_type_name AS managertype,
    pt.param_name AS parametername,
    pv.value AS parametervalue,
    pv.comment,
    pv.entry_id,
    pv.last_affected,
    pv.entered_by
   FROM (((mc.t_mgrs m
     JOIN mc.t_mgr_types mt ON ((m.mgr_type_id = mt.mgr_type_id)))
     JOIN mc.t_param_value pv ON ((m.mgr_id = pv.mgr_id)))
     JOIN mc.t_param_type pt ON ((pv.type_id = pt.param_id)));


ALTER TABLE mc.v_mgr_params OWNER TO d3l243;

--
-- Name: v_mgr_params trig_u_v_mgr_params; Type: TRIGGER; Schema: mc; Owner: d3l243
--

CREATE TRIGGER trig_u_v_mgr_params INSTEAD OF UPDATE ON mc.v_mgr_params FOR EACH ROW EXECUTE FUNCTION mc.trigfn_u_v_mgr_params();

