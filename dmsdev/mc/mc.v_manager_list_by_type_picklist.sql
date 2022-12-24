--
-- Name: v_manager_list_by_type_picklist; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_manager_list_by_type_picklist AS
 SELECT m.mgr_id AS id,
    m.mgr_name AS managername,
    mt.mgr_type_name AS managertype
   FROM (mc.t_mgrs m
     JOIN mc.t_mgr_types mt ON ((m.mgr_type_id = mt.mgr_type_id)));


ALTER TABLE mc.v_manager_list_by_type_picklist OWNER TO d3l243;

