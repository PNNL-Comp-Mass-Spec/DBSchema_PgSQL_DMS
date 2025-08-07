--
-- Name: v_service_use_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_service_use_detail_report AS
 SELECT u.report_id,
    u.entry_id AS id,
    u.dataset_id,
    cc.sub_account,
    u.charge_code,
    u.service_type_id,
    t.service_type,
    u.transaction_date,
    u.transaction_units,
    u.is_held,
    u.comment,
    u.ticket_number,
    ((u.transaction_cost_est)::numeric(1000,2))::real AS transaction_cost_estimate,
    ds.cc_report_state_id AS cost_center_report_state_id,
    dsrepstate.cc_report_state AS cost_center_report_state
   FROM (((((cc.t_service_use u
     JOIN cc.t_service_use_report rep ON ((rep.report_id = u.report_id)))
     JOIN cc.t_service_type t ON ((t.service_type_id = u.service_type_id)))
     LEFT JOIN public.t_charge_code cc ON ((cc.charge_code OPERATOR(public.=) u.charge_code)))
     LEFT JOIN public.t_dataset ds ON ((u.dataset_id = ds.dataset_id)))
     LEFT JOIN public.t_dataset_cc_report_state dsrepstate ON ((ds.cc_report_state_id = dsrepstate.cc_report_state_id)));


ALTER VIEW public.v_service_use_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_service_use_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_service_use_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_service_use_detail_report TO writeaccess;

