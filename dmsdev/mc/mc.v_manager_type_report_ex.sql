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
            count(*) FILTER (WHERE (ml.active OPERATOR(public.=) 'True'::public.citext)) AS managercountactive,
            count(*) FILTER (WHERE (ml.active OPERATOR(public.<>) 'True'::public.citext)) AS managercountinactive
           FROM mc.v_manager_list_by_type ml
          GROUP BY ml.mgr_type_id, ml.manager_type) activemanagersq ON ((mt.mgr_type_id = activemanagersq.mgr_type_id)));


ALTER TABLE mc.v_manager_type_report_ex OWNER TO d3l243;

