--
-- Name: v_service_cost_rate_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_service_cost_rate_list_report AS
 SELECT cr.cost_group_id,
    costgroup.description,
    servicetype.service_type,
    cr.adjustment,
    cr.base_rate_per_hour_adj,
    cr.overhead_hours_per_run,
    cr.base_rate_per_run,
    cr.labor_rate_per_hour,
    cr.labor_hours_per_run,
    cr.labor_rate_per_run,
    (cr.base_rate_per_run + cr.labor_rate_per_run) AS total_rate_per_run,
    cr.service_type_id
   FROM ((cc.t_service_cost_rate cr
     JOIN cc.t_service_type servicetype ON ((servicetype.service_type_id = cr.service_type_id)))
     JOIN cc.t_service_cost_group costgroup ON ((costgroup.cost_group_id = cr.cost_group_id)));


ALTER VIEW public.v_service_cost_rate_list_report OWNER TO d3l243;

--
-- Name: TABLE v_service_cost_rate_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_service_cost_rate_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_service_cost_rate_list_report TO writeaccess;

