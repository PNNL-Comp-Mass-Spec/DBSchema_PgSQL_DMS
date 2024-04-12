--
-- Name: v_active_requested_runs; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_active_requested_runs AS
 SELECT request,
    name,
    status,
    origin,
    acq_start,
    batch,
    campaign,
    experiment,
    dataset,
    instrument,
    inst_group,
    requester,
    created,
    days_in_queue,
    queue_state,
    queued_instrument,
    work_package,
    wp_state,
    usage,
    proposal,
    proposal_type,
    proposal_state,
    comment,
    type,
    separation_group,
    wellplate,
    well,
    vialing_conc,
    vialing_vol,
    staging_location,
    block,
    run_order,
    cart,
    cart_config,
    dataset_comment,
    request_name_code,
    days_in_queue_bin,
    wp_activation_state
   FROM public.v_requested_run_list_report_2
  WHERE (status OPERATOR(public.=) 'Active'::public.citext);


ALTER VIEW public.v_active_requested_runs OWNER TO d3l243;

--
-- Name: TABLE v_active_requested_runs; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_active_requested_runs TO readaccess;
GRANT SELECT ON TABLE public.v_active_requested_runs TO writeaccess;

