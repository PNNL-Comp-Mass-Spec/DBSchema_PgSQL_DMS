--
-- Name: v_param_value; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_param_value AS
 SELECT m.mgr_name AS m_name,
    pt.param_name,
    pv.entry_id,
    pv.type_id,
    pv.value,
    pv.mgr_id,
    pv.comment,
    pv.last_affected,
    pv.entered_by,
    m.mgr_type_id
   FROM ((mc.t_param_value pv
     JOIN mc.t_mgrs m ON ((pv.mgr_id = m.mgr_id)))
     JOIN mc.t_param_type pt ON ((pv.type_id = pt.param_id)));


ALTER TABLE mc.v_param_value OWNER TO d3l243;

--
-- Name: v_param_value trig_u_v_param_value; Type: TRIGGER; Schema: mc; Owner: d3l243
--

CREATE TRIGGER trig_u_v_param_value INSTEAD OF UPDATE ON mc.v_param_value FOR EACH ROW EXECUTE FUNCTION mc.trigfn_u_v_param_value();

--
-- Name: TABLE v_param_value; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.v_param_value TO readaccess;

