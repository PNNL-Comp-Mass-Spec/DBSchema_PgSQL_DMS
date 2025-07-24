--
-- Name: v_service_use_report_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_service_use_report_list_report AS
 SELECT rep.report_id,
    rep.start_time,
    rep.end_time,
    rep.requestor_employee_id,
    state.report_state,
    rep.report_state_id,
    rep.cost_group_id
   FROM (cc.t_service_use_report rep
     JOIN cc.t_service_use_report_state state ON ((rep.report_state_id = state.report_state_id)));


ALTER VIEW public.v_service_use_report_list_report OWNER TO d3l243;

--
-- Name: TABLE v_service_use_report_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_service_use_report_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_service_use_report_list_report TO writeaccess;

