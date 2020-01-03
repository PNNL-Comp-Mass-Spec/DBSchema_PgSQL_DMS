--
-- Name: v_manager_type_report_ex; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_manager_type_report_ex AS
 SELECT mt.mgr_type_name AS "Manager Type",
    mt.mgr_type_id AS id,
    COALESCE(activemanagersq.managercountactive, (0)::bigint) AS "Manager Count Active",
    COALESCE(activemanagersq.managercountinactive, (0)::bigint) AS "Manager Count Inactive"
   FROM (mc.t_mgr_types mt
     LEFT JOIN ( SELECT v_manager_list_by_type.mgr_type_id,
            v_manager_list_by_type."Manager Type",
            count(*) FILTER (WHERE (v_manager_list_by_type.active OPERATOR(public.=) 'True'::public.citext)) AS managercountactive,
            count(*) FILTER (WHERE (v_manager_list_by_type.active OPERATOR(public.<>) 'True'::public.citext)) AS managercountinactive
           FROM mc.v_manager_list_by_type
          GROUP BY v_manager_list_by_type.mgr_type_id, v_manager_list_by_type."Manager Type") activemanagersq ON ((mt.mgr_type_id = activemanagersq.mgr_type_id)));


ALTER TABLE mc.v_manager_type_report_ex OWNER TO d3l243;

--
-- Name: TABLE v_manager_type_report_ex; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.v_manager_type_report_ex TO readaccess;
