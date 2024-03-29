--
-- Name: v_manager_type_report_ex; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_manager_type_report_ex AS
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
          GROUP BY ml.mgr_type_id, ml.manager_type) activemanagersq ON ((mt.mgr_type_id = activemanagersq.mgr_type_id)));


ALTER VIEW mc.v_manager_type_report_ex OWNER TO d3l243;

--
-- Name: TABLE v_manager_type_report_ex; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.v_manager_type_report_ex TO readaccess;
GRANT SELECT ON TABLE mc.v_manager_type_report_ex TO writeaccess;

