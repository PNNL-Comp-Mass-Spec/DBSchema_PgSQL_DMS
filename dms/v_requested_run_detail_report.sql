--
-- Name: v_requested_run_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_detail_report AS
 SELECT rr.request_id AS request,
    rr.request_name AS name,
    rr.state_name AS status,
    c.campaign,
    e.experiment,
    ds.dataset,
    ml.location AS staging_location,
    instname.instrument AS instrument_used,
    rr.instrument_group,
    dtn.dataset_type AS run_type,
    rr.separation_group,
    u.name_with_username AS requester,
    rr.requester_username AS username,
    rr.created,
    qt.days_in_queue,
    qs.queue_state_name AS queue_state,
    COALESCE(assignedinstrument.instrument, ''::public.citext) AS queued_instrument,
    rr.origin,
    rr.instrument_setting AS instrument_settings,
    rr.wellplate,
    rr.well,
    rr.vialing_conc AS vialing_concentration,
    rr.vialing_vol AS vialing_volume,
    rr.comment,
    COALESCE(fc.factor_count, (0)::bigint) AS factors,
    rrb.batch AS batch_name,
    rr.batch_id AS batch,
    rr.block,
    rr.run_order,
    lc.cart_name AS cart,
    cartconfig.cart_config_name AS cart_config,
    rr.cart_column AS column_name,
    rr.work_package,
        CASE
            WHEN (rr.work_package OPERATOR(public.=) ANY (ARRAY['none'::public.citext, ''::public.citext])) THEN ''::public.citext
            ELSE COALESCE(cc.activation_state_name, 'Invalid'::public.citext)
        END AS work_package_state,
    eut.eus_usage_type,
    rr.eus_proposal_id AS eus_proposal,
    ept.proposal_type_name AS eus_proposal_type,
    (eup.proposal_end_date)::date AS eus_proposal_end_date,
    psn.state_name AS eus_proposal_state,
    public.get_requested_run_eus_users_list(rr.request_id, 'V'::text) AS eus_user,
    rr.service_type_id AS cost_center_service_type_id,
    ccst.service_type AS cost_center_service_type,
    t_attachments.attachment_name AS mrm_transition_list,
    rr.note,
    rr.special_instructions,
        CASE
            WHEN ((rr.state_name OPERATOR(public.=) ANY (ARRAY['Active'::public.citext, 'Holding'::public.citext])) AND (cc.activation_state >= 3)) THEN 10
            ELSE (cc.activation_state)::integer
        END AS wp_activation_state
   FROM ((((((((((((((((((((public.t_dataset_type_name dtn
     JOIN (public.t_requested_run rr
     JOIN public.t_experiments e ON ((rr.exp_id = e.exp_id))) ON ((dtn.dataset_type_id = rr.request_type_id)))
     JOIN public.t_users u ON ((rr.requester_username OPERATOR(public.=) u.username)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_lc_cart lc ON ((rr.cart_id = lc.cart_id)))
     JOIN public.t_requested_run_queue_state qs ON ((rr.queue_state = qs.queue_state)))
     JOIN public.t_requested_run_batches rrb ON ((rr.batch_id = rrb.batch_id)))
     JOIN public.t_eus_usage_type eut ON ((rr.eus_usage_type_id = eut.eus_usage_type_id)))
     JOIN cc.t_service_type ccst ON ((rr.service_type_id = ccst.service_type_id)))
     LEFT JOIN public.t_attachments ON ((rr.mrm_attachment = t_attachments.attachment_id)))
     LEFT JOIN public.t_dataset ds ON ((rr.dataset_id = ds.dataset_id)))
     LEFT JOIN public.t_lc_cart_configuration cartconfig ON ((rr.cart_config_id = cartconfig.cart_config_id)))
     LEFT JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     LEFT JOIN public.t_instrument_name assignedinstrument ON ((rr.queue_instrument_id = assignedinstrument.instrument_id)))
     LEFT JOIN public.v_requested_run_queue_times qt ON ((rr.request_id = qt.requested_run_id)))
     LEFT JOIN public.v_factor_count_by_requested_run fc ON ((fc.rr_id = rr.request_id)))
     LEFT JOIN public.v_charge_code_status cc ON ((rr.work_package OPERATOR(public.=) cc.charge_code)))
     LEFT JOIN public.t_eus_proposals eup ON ((rr.eus_proposal_id OPERATOR(public.=) eup.proposal_id)))
     LEFT JOIN public.t_eus_proposal_type ept ON ((eup.proposal_type OPERATOR(public.=) ept.proposal_type)))
     LEFT JOIN public.t_eus_proposal_state_name psn ON ((eup.state_id = psn.state_id)))
     LEFT JOIN public.t_material_locations ml ON ((rr.location_id = ml.location_id)));


ALTER VIEW public.v_requested_run_detail_report OWNER TO d3l243;

--
-- Name: VIEW v_requested_run_detail_report; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_requested_run_detail_report IS 'If the requested run is active, but the charge code is inactive, return 10 for wp_activation_state';

--
-- Name: TABLE v_requested_run_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_requested_run_detail_report TO writeaccess;

