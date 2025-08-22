--
-- Name: v_dataset_svc_center_report_state_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_svc_center_report_state_list_report AS
 SELECT cc_report_state_id,
    cc_report_state,
    description
   FROM public.t_dataset_svc_center_report_state;


ALTER VIEW public.v_dataset_svc_center_report_state_list_report OWNER TO d3l243;

--
-- Name: TABLE v_dataset_svc_center_report_state_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_svc_center_report_state_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_svc_center_report_state_list_report TO writeaccess;

