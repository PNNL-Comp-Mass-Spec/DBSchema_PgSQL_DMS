--
-- Name: v_manager_list_by_type; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_manager_list_by_type AS
 SELECT m.mgr_id AS id,
    m.mgr_name AS "Manager Name",
    mt.mgr_type_name AS "Manager Type",
    COALESCE(activeq.active, 'not defined'::public.citext) AS active,
    m.mgr_type_id,
    activeq.last_affected AS "State Last Changed",
    activeq.entered_by AS "Changed By",
    m.comment
   FROM ((mc.t_mgrs m
     JOIN mc.t_mgr_types mt ON ((m.mgr_type_id = mt.mgr_type_id)))
     LEFT JOIN ( SELECT pv.mgr_id,
            pv.value AS active,
            pv.last_affected,
            pv.entered_by
           FROM (mc.t_param_value pv
             JOIN mc.t_param_type pt ON ((pv.type_id = pt.param_id)))
          WHERE (pt.param_name OPERATOR(public.=) 'mgractive'::public.citext)) activeq ON ((m.mgr_id = activeq.mgr_id)))
  WHERE (m.control_from_website > 0);


ALTER TABLE mc.v_manager_list_by_type OWNER TO d3l243;

--
-- Name: TABLE v_manager_list_by_type; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.v_manager_list_by_type TO readaccess;

