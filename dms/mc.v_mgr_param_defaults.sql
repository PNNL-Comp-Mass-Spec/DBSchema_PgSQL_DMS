--
-- Name: v_mgr_param_defaults; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_mgr_param_defaults AS
 SELECT pm.mgr_type_id,
    mt.mt_type_name AS managertype,
    pm.param_type_id AS "Param ID",
    pt.param_name AS param,
    pm.default_value AS value,
    COALESCE(pt.picklist_name, ''::public.citext) AS picklist_name
   FROM ((mc.t_mgr_type_param_type_map pm
     JOIN mc.t_param_type pt ON ((pm.param_type_id = pt.param_id)))
     JOIN mc.t_mgr_types mt ON ((pm.mgr_type_id = mt.mt_type_id)));


ALTER TABLE mc.v_mgr_param_defaults OWNER TO d3l243;

--
-- Name: TABLE v_mgr_param_defaults; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.v_mgr_param_defaults TO readaccess;
