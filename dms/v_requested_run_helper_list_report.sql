--
-- Name: v_requested_run_helper_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_helper_list_report AS
 SELECT rr.request_id AS request,
    rr.request_name AS name,
    rr.batch_id AS batch,
    e.experiment,
    rr.instrument_group AS instrument,
    u.name AS requester,
    rr.created,
    rr.work_package,
    rr.comment,
    dtn.dataset_type AS type,
    rr.wellplate,
    rr.well
   FROM (((public.t_dataset_type_name dtn
     JOIN public.t_requested_run rr ON ((dtn.dataset_type_id = rr.request_type_id)))
     JOIN public.t_users u ON ((rr.requester_username OPERATOR(public.=) u.username)))
     JOIN public.t_experiments e ON ((rr.exp_id = e.exp_id)))
  WHERE (rr.dataset_id IS NULL);


ALTER VIEW public.v_requested_run_helper_list_report OWNER TO d3l243;

--
-- Name: TABLE v_requested_run_helper_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_helper_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_requested_run_helper_list_report TO writeaccess;

