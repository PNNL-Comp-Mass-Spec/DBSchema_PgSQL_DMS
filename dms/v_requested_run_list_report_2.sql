--
-- Name: v_requested_run_list_report_2; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_list_report_2 AS
 SELECT rr.request_id AS request,
    rr.request_name AS name,
    rr.state_name AS status,
    rr.origin,
    COALESCE(ds.acq_time_start, rr.request_run_start) AS acq_start,
    rr.batch_id AS batch,
    c.campaign,
    e.experiment,
    ds.dataset,
    COALESCE(instname.instrument, ''::public.citext) AS instrument,
    rr.instrument_group AS inst_group,
    u.name AS requester,
    rr.created,
    qt.days_in_queue,
    qs.queue_state_name AS queue_state,
    COALESCE(assignedinstrument.instrument, ''::public.citext) AS queued_instrument,
    rr.work_package,
    COALESCE(cc.activation_state_name, ''::public.citext) AS wp_state,
    eut.eus_usage_type AS usage,
    rr.eus_proposal_id AS proposal,
    ept.abbreviation AS proposal_type,
    psn.state_name AS proposal_state,
    rr.comment,
    dtn.dataset_type AS type,
    rr.separation_group,
    rr.wellplate,
    rr.well,
    rr.vialing_conc,
    rr.vialing_vol,
    ml.tag AS staging_location,
    rr.block,
    rr.run_order,
    lc.cart_name AS cart,
    cartconfig.cart_config_name AS cart_config,
    ds.comment AS dataset_comment,
    rr.request_name_code,
        CASE
            WHEN (rr.state_name OPERATOR(public.<>) 'Active'::public.citext) THEN 0
            WHEN (qt.days_in_queue <= (30)::numeric) THEN 30
            WHEN (qt.days_in_queue <= (60)::numeric) THEN 60
            WHEN (qt.days_in_queue <= (90)::numeric) THEN 90
            ELSE 120
        END AS days_in_queue_bin,
        CASE
            WHEN ((rr.state_name OPERATOR(public.=) 'Active'::public.citext) AND (cc.activation_state >= 3)) THEN 10
            ELSE (cc.activation_state)::integer
        END AS wp_activation_state
   FROM (((((((((((((((((public.t_requested_run rr
     JOIN public.t_dataset_type_name dtn ON ((dtn.dataset_type_id = rr.request_type_id)))
     JOIN public.t_users u ON ((rr.requester_prn OPERATOR(public.=) u.username)))
     JOIN public.t_experiments e ON ((rr.exp_id = e.exp_id)))
     JOIN public.t_eus_usage_type eut ON ((rr.eus_usage_type_id = eut.eus_usage_type_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_lc_cart lc ON ((rr.cart_id = lc.cart_id)))
     JOIN public.t_requested_run_queue_state qs ON ((rr.queue_state = qs.queue_state)))
     LEFT JOIN public.t_dataset ds ON ((rr.dataset_id = ds.dataset_id)))
     LEFT JOIN public.t_lc_cart_configuration cartconfig ON ((rr.cart_config_id = cartconfig.cart_config_id)))
     LEFT JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     LEFT JOIN public.t_instrument_name assignedinstrument ON ((rr.queue_instrument_id = assignedinstrument.instrument_id)))
     LEFT JOIN public.v_requested_run_queue_times qt ON ((rr.request_id = qt.requested_run_id)))
     LEFT JOIN public.v_charge_code_status cc ON ((rr.work_package OPERATOR(public.=) cc.charge_code)))
     LEFT JOIN public.t_eus_proposals eup ON ((rr.eus_proposal_id OPERATOR(public.=) eup.proposal_id)))
     LEFT JOIN public.t_eus_proposal_type ept ON ((eup.proposal_type OPERATOR(public.=) ept.proposal_type)))
     LEFT JOIN public.t_eus_proposal_state_name psn ON ((eup.state_id = psn.state_id)))
     LEFT JOIN public.t_material_locations ml ON ((rr.location_id = ml.location_id)));


ALTER TABLE public.v_requested_run_list_report_2 OWNER TO d3l243;

--
-- Name: VIEW v_requested_run_list_report_2; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_requested_run_list_report_2 IS 'If the requested run is active, but the charge code is inactive, return 10 for wp_activation_state';

--
-- Name: TABLE v_requested_run_list_report_2; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_list_report_2 TO readaccess;
GRANT SELECT ON TABLE public.v_requested_run_list_report_2 TO writeaccess;

