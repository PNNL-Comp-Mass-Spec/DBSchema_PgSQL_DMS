--
-- Name: v_service_cost_rate_burdened_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_service_cost_rate_burdened_list_report AS
 SELECT cr.cost_group_id,
    cg.description,
    crb.funding_agency,
    t.service_type,
    cr.service_type_id,
    cr.indirect_per_run AS indirect_rate_per_run,
    cr.direct_per_run AS labor_rate_per_run,
    cr.non_labor_per_run AS non_labor_rate_per_run,
    crb.base_rate_per_run,
    crb.pdm,
    crb.general_and_administration,
    crb.safeguards_and_security,
    crb.fee,
    crb.ldrd,
    crb.facilities,
    crb.total_burdened_rate_per_run
   FROM (((svc.t_service_cost_rate cr
     JOIN svc.t_service_type t ON ((t.service_type_id = cr.service_type_id)))
     JOIN svc.t_service_cost_group cg ON ((cg.cost_group_id = cr.cost_group_id)))
     JOIN svc.t_service_cost_rate_burdened crb ON (((cg.cost_group_id = cr.cost_group_id) AND (t.service_type_id = crb.service_type_id))));


ALTER VIEW public.v_service_cost_rate_burdened_list_report OWNER TO d3l243;

--
-- Name: TABLE v_service_cost_rate_burdened_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_service_cost_rate_burdened_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_service_cost_rate_burdened_list_report TO writeaccess;

