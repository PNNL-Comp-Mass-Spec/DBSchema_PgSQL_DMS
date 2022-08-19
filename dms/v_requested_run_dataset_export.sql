--
-- Name: v_requested_run_dataset_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_dataset_export AS
 SELECT rr.request_id,
    rr.request_name,
    rr.state_name AS status,
    rr.origin,
    rr.comment AS request_comment,
    rr.created AS request_created,
    rr.batch_id AS batch,
    rr.instrument_group AS requested_inst_group,
    rr.work_package,
    u.name AS requestor,
    c.campaign,
    e.experiment,
    ds.dataset,
    ds.dataset_id,
    ds.comment AS dataset_comment,
    COALESCE(ds.acq_time_start, rr.request_run_start) AS acq_start,
    instname.instrument,
    instname.instrument_group,
    ds.separation_type,
    rr.separation_group,
    lc.cart_name AS cart,
    dtn.dataset_type,
    eut.eus_usage_type AS eus_usage,
    rr.eus_proposal_id AS rds_eus_proposal_id,
    ept.abbreviation AS eus_proposal_type,
    rr.updated
   FROM ((((((((((public.t_requested_run rr
     JOIN public.t_dataset_type_name dtn ON ((dtn.dataset_type_id = rr.request_type_id)))
     JOIN public.t_users u ON ((rr.requester_prn OPERATOR(public.=) u.username)))
     JOIN public.t_experiments e ON ((rr.exp_id = e.exp_id)))
     JOIN public.t_eus_usage_type eut ON ((rr.eus_usage_type_id = eut.eus_usage_type_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_lc_cart lc ON ((rr.cart_id = lc.cart_id)))
     JOIN public.t_dataset ds ON ((rr.dataset_id = ds.dataset_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     LEFT JOIN public.t_eus_proposals eup ON ((rr.eus_proposal_id OPERATOR(public.=) eup.proposal_id)))
     LEFT JOIN public.t_eus_proposal_type ept ON ((eup.proposal_type OPERATOR(public.=) ept.proposal_type)));


ALTER TABLE public.v_requested_run_dataset_export OWNER TO d3l243;

--
-- Name: VIEW v_requested_run_dataset_export; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_requested_run_dataset_export IS 'MyEMSL uses this view';

--
-- Name: TABLE v_requested_run_dataset_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_dataset_export TO readaccess;
GRANT SELECT ON TABLE public.v_requested_run_dataset_export TO writeaccess;

