--
-- Name: v_manager_update_required; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_manager_update_required AS
 SELECT t_mgrs.m_name,
    pt.param_name,
    pv.value
   FROM ((mc.t_mgrs
     JOIN mc.t_param_value pv ON ((t_mgrs.m_id = pv.mgr_id)))
     JOIN mc.t_param_type pt ON ((pv.type_id = pt.param_id)))
  WHERE (pt.param_name OPERATOR(public.=) 'ManagerUpdateRequired'::public.citext);


ALTER TABLE mc.v_manager_update_required OWNER TO d3l243;

--
-- Name: TABLE v_manager_update_required; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.v_manager_update_required TO readaccess;
