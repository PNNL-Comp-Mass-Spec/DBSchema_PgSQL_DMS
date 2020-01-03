--
-- Name: v_param_name_picklist; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_param_name_picklist AS
 SELECT pt.param_name AS val,
    pt.param_name AS ex,
    mtpm.mgr_type_id AS m_typeid
   FROM (mc.t_param_type pt
     JOIN mc.t_mgr_type_param_type_map mtpm ON ((pt.param_id = mtpm.param_type_id)));


ALTER TABLE mc.v_param_name_picklist OWNER TO d3l243;

--
-- Name: TABLE v_param_name_picklist; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.v_param_name_picklist TO readaccess;
