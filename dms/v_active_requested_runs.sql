--
-- Name: v_active_requested_runs; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_active_requested_runs AS
 SELECT v_requested_run_list_report_2.request,
    v_requested_run_list_report_2.name,
    v_requested_run_list_report_2.status,
    v_requested_run_list_report_2.origin,
    v_requested_run_list_report_2.acq_start,
    v_requested_run_list_report_2.batch,
    v_requested_run_list_report_2.campaign,
    v_requested_run_list_report_2.experiment,
    v_requested_run_list_report_2.dataset,
    v_requested_run_list_report_2.instrument,
    v_requested_run_list_report_2.inst_group,
    v_requested_run_list_report_2.requester,
    v_requested_run_list_report_2.created,
    v_requested_run_list_report_2.days_in_queue,
    v_requested_run_list_report_2.queue_state,
    v_requested_run_list_report_2.queued_instrument,
    v_requested_run_list_report_2.work_package,
    v_requested_run_list_report_2.wp_state,
    v_requested_run_list_report_2.usage,
    v_requested_run_list_report_2.proposal,
    v_requested_run_list_report_2.proposal_type,
    v_requested_run_list_report_2.proposal_state,
    v_requested_run_list_report_2.comment,
    v_requested_run_list_report_2.type,
    v_requested_run_list_report_2.separation_group,
    v_requested_run_list_report_2.wellplate,
    v_requested_run_list_report_2.well,
    v_requested_run_list_report_2.vialing_conc,
    v_requested_run_list_report_2.vialing_vol,
    v_requested_run_list_report_2.staging_location,
    v_requested_run_list_report_2.block,
    v_requested_run_list_report_2.run_order,
    v_requested_run_list_report_2.cart,
    v_requested_run_list_report_2.cart_config,
    v_requested_run_list_report_2.dataset_comment,
    v_requested_run_list_report_2.request_name_code,
    v_requested_run_list_report_2."#DaysInQueue",
    v_requested_run_list_report_2."#WPActivationState"
   FROM public.v_requested_run_list_report_2
  WHERE (v_requested_run_list_report_2.status OPERATOR(public.=) 'Active'::public.citext);


ALTER TABLE public.v_active_requested_runs OWNER TO d3l243;

--
-- Name: TABLE v_active_requested_runs; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_active_requested_runs TO readaccess;
GRANT SELECT ON TABLE public.v_active_requested_runs TO writeaccess;

