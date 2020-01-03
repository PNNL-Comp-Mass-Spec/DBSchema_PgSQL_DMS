--
-- Name: v_manager_type_detail; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_manager_type_detail AS
 SELECT t_mgr_types.mgr_type_id AS id,
    ''::text AS manager_list
   FROM mc.t_mgr_types;


ALTER TABLE mc.v_manager_type_detail OWNER TO d3l243;

--
-- Name: TABLE v_manager_type_detail; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.v_manager_type_detail TO readaccess;
