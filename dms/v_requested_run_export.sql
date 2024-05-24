--
-- Name: v_requested_run_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_export AS
 SELECT rr.request_id,
    rr.request_name,
    rr.state_name,
    rr.origin,
    COALESCE(ds.acq_time_start, rr.request_run_start) AS acq_start,
    rr.batch_id,
    c.campaign,
    e.experiment,
    ds.dataset,
    COALESCE(instname.instrument, ''::public.citext) AS instrument,
    rr.instrument_group,
    u.name AS requester,
    rr.created,
    qt.days_in_queue,
    qs.queue_state_name,
    COALESCE(assignedinstrument.instrument, ''::public.citext) AS queued_instrument,
    rr.work_package,
    COALESCE(cca.activation_state_name, ''::public.citext) AS wp_state,
    eut.eus_usage_type,
    rr.eus_proposal_id,
    ept.abbreviation AS eus_proposal_type,
    psn.state_name AS proposal_state,
    rr.comment,
    dtn.dataset_type,
    rr.separation_group,
    rr.wellplate,
    rr.well,
    rr.vialing_conc,
    rr.vialing_vol,
    ml.location AS staging_location,
    rr.block,
    rr.run_order,
    lc.cart_name,
    cartconfig.cart_config_name AS cart_config,
    ds.comment AS dataset_comment,
    rr.request_name_code
   FROM (((((((((((((((((public.t_requested_run rr
     JOIN public.t_dataset_type_name dtn ON ((dtn.dataset_type_id = rr.request_type_id)))
     JOIN public.t_users u ON ((rr.requester_username OPERATOR(public.=) u.username)))
     JOIN public.t_experiments e ON ((rr.exp_id = e.exp_id)))
     JOIN public.t_eus_usage_type eut ON ((rr.eus_usage_type_id = eut.eus_usage_type_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_lc_cart lc ON ((rr.cart_id = lc.cart_id)))
     JOIN public.t_requested_run_queue_state qs ON ((rr.queue_state = qs.queue_state)))
     JOIN public.t_charge_code_activation_state cca ON ((rr.cached_wp_activation_state = cca.activation_state)))
     LEFT JOIN public.t_dataset ds ON ((rr.dataset_id = ds.dataset_id)))
     LEFT JOIN public.t_lc_cart_configuration cartconfig ON ((rr.cart_config_id = cartconfig.cart_config_id)))
     LEFT JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     LEFT JOIN public.t_instrument_name assignedinstrument ON ((rr.queue_instrument_id = assignedinstrument.instrument_id)))
     LEFT JOIN public.v_requested_run_queue_times qt ON ((rr.request_id = qt.requested_run_id)))
     LEFT JOIN public.t_eus_proposals eup ON ((rr.eus_proposal_id OPERATOR(public.=) eup.proposal_id)))
     LEFT JOIN public.t_eus_proposal_type ept ON ((eup.proposal_type OPERATOR(public.=) ept.proposal_type)))
     LEFT JOIN public.t_eus_proposal_state_name psn ON ((eup.state_id = psn.state_id)))
     LEFT JOIN public.t_material_locations ml ON ((rr.location_id = ml.location_id)));


ALTER VIEW public.v_requested_run_export OWNER TO d3l243;

--
-- Name: TABLE v_requested_run_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_export TO readaccess;
GRANT SELECT ON TABLE public.v_requested_run_export TO writeaccess;

