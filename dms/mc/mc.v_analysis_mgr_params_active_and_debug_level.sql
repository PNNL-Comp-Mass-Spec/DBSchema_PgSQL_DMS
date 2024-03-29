--
-- Name: v_analysis_mgr_params_active_and_debug_level; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_analysis_mgr_params_active_and_debug_level AS
 SELECT pv.mgr_id,
    m.mgr_name AS manager,
    pt.param_name,
    pv.param_type_id,
    pv.value,
    pv.last_affected,
    pv.entered_by
   FROM ((mc.t_param_value pv
     JOIN mc.t_param_type pt ON ((pv.param_type_id = pt.param_type_id)))
     JOIN mc.t_mgrs m ON ((pv.mgr_id = m.mgr_id)))
  WHERE ((pt.param_name OPERATOR(public.=) ANY (ARRAY['mgractive'::public.citext, 'debuglevel'::public.citext, 'ManagerErrorCleanupMode'::public.citext])) AND (m.mgr_type_id = ANY (ARRAY[11, 15])));


ALTER VIEW mc.v_analysis_mgr_params_active_and_debug_level OWNER TO d3l243;

--
-- Name: TABLE v_analysis_mgr_params_active_and_debug_level; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.v_analysis_mgr_params_active_and_debug_level TO readaccess;
GRANT SELECT ON TABLE mc.v_analysis_mgr_params_active_and_debug_level TO writeaccess;

