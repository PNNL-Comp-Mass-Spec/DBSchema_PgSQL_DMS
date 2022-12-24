--
-- Name: v_mgr_param_defaults; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_mgr_param_defaults AS
 SELECT mtpm.mgr_type_id,
    mt.mgr_type_name AS managertype,
    mtpm.param_type_id AS "Param ID",
    pt.param_name AS param,
    mtpm.default_value AS value,
    COALESCE(pt.picklist_name, ''::public.citext) AS picklist_name
   FROM ((mc.t_mgr_type_param_type_map mtpm
     JOIN mc.t_param_type pt ON ((mtpm.param_type_id = pt.param_id)))
     JOIN mc.t_mgr_types mt ON ((mtpm.mgr_type_id = mt.mgr_type_id)));


ALTER TABLE mc.v_mgr_param_defaults OWNER TO d3l243;

