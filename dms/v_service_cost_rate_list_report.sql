--
-- Name: v_service_cost_rate_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_service_cost_rate_list_report AS
 SELECT cr.cost_group_id,
    cg.description,
    t.service_type,
    cr.service_type_id,
    cr.indirect_per_run AS indirect_rate_per_run,
    cr.direct_per_run AS labor_rate_per_run,
    cr.non_labor_per_run AS non_labor_rate_per_run,
    cr.base_rate_per_run,
    cr.doe_burdened_rate_per_run AS doe_burdened_rate,
    cr.hhs_burdened_rate_per_run AS hhs_burdened_rate,
    cr.ldrd_burdened_rate_per_run AS ldrd_burdened_rate
   FROM ((svc.t_service_cost_rate cr
     JOIN svc.t_service_type t ON ((t.service_type_id = cr.service_type_id)))
     JOIN svc.t_service_cost_group cg ON ((cg.cost_group_id = cr.cost_group_id)));


ALTER VIEW public.v_service_cost_rate_list_report OWNER TO d3l243;

--
-- Name: TABLE v_service_cost_rate_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_service_cost_rate_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_service_cost_rate_list_report TO writeaccess;

