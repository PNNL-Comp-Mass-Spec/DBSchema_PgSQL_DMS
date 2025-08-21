--
-- Name: v_service_cost_rate_list_report; Type: VIEW; cc: public; Owner: d3l243
--

CREATE VIEW cc.v_service_cost_rate_list_report_v1 AS
 SELECT cr.cost_group_id,
    cg.description,
    t.service_type,
    cr.service_type_id,
    cr.adjustment,
    cr.base_rate_per_hour_adj,
    cr.overhead_hours_per_run,
    cr.base_rate_per_run,
    cr.labor_rate_per_hour,
    cr.labor_hours_per_run,
    cr.labor_rate_per_run,
    (cr.base_rate_per_run + cr.labor_rate_per_run) AS total_rate_per_run
   FROM ((cc.t_service_cost_rate_v1 cr
     JOIN cc.t_service_type_v1 t ON ((t.service_type_id = cr.service_type_id)))
     JOIN cc.t_service_cost_group cg ON ((cg.cost_group_id = cr.cost_group_id)));


ALTER VIEW public.v_service_cost_rate_list_report_v1 OWNER TO d3l243;

--
-- Name: TABLE v_service_cost_rate_list_report_v1; Type: ACL; Schema: cc; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_service_cost_rate_list_report_v1 TO readaccess;
GRANT SELECT ON TABLE public.v_service_cost_rate_list_report_v1 TO writeaccess;

