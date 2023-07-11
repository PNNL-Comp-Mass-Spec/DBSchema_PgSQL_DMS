--
-- Name: v_manager_type_report; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_manager_type_report AS
 SELECT mt.mgr_type_name AS manager_type,
    mt.mgr_type_id AS id,
    COALESCE(activemanagersq.managercountactive, (0)::bigint) AS manager_count_active,
    COALESCE(activemanagersq.managercountinactive, (0)::bigint) AS manager_count_inactive
   FROM (mc.t_mgr_types mt
     LEFT JOIN ( SELECT ml.mgr_type_id,
            ml.manager_type,
            count(ml.id) FILTER (WHERE (ml.active OPERATOR(public.=) 'True'::public.citext)) AS managercountactive,
            count(ml.id) FILTER (WHERE (ml.active OPERATOR(public.<>) 'True'::public.citext)) AS managercountinactive
           FROM mc.v_manager_list_by_type ml
          GROUP BY ml.mgr_type_id, ml.manager_type) activemanagersq ON ((mt.mgr_type_id = activemanagersq.mgr_type_id)))
  WHERE (mt.mgr_type_id IN ( SELECT t_mgrs.mgr_type_id
           FROM mc.t_mgrs
          WHERE (t_mgrs.control_from_website > 0)));


ALTER TABLE mc.v_manager_type_report OWNER TO d3l243;

--
-- Name: TABLE v_manager_type_report; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.v_manager_type_report TO readaccess;
GRANT SELECT ON TABLE mc.v_manager_type_report TO writeaccess;

