--
-- Name: v_mgr_param_defaults; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_mgr_param_defaults AS
 SELECT mtpm.mgr_type_id,
    mt.mgr_type_name AS manager_type,
    mtpm.param_type_id AS param_id,
    pt.param_name AS param,
    mtpm.default_value AS value,
    COALESCE(pt.picklist_name, ''::public.citext) AS picklist_name
   FROM ((mc.t_mgr_type_param_type_map mtpm
     JOIN mc.t_param_type pt ON ((mtpm.param_type_id = pt.param_type_id)))
     JOIN mc.t_mgr_types mt ON ((mtpm.mgr_type_id = mt.mgr_type_id)));


ALTER VIEW mc.v_mgr_param_defaults OWNER TO d3l243;

--
-- Name: TABLE v_mgr_param_defaults; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.v_mgr_param_defaults TO readaccess;
GRANT SELECT ON TABLE mc.v_mgr_param_defaults TO writeaccess;

