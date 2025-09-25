--
-- Name: v_svc_center_instrument_datasets; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_svc_center_instrument_datasets AS
 SELECT ds.dataset_id AS id,
    ds.dataset,
    e.experiment,
    c.campaign,
    dsn.dataset_state AS state,
    cds.instrument,
    ds.created,
    ds.comment,
    dsrating.dataset_rating AS rating,
    dtn.dataset_type,
    ds.operator_username AS operator,
    dl.dataset_folder_path,
    dl.qc_link,
    COALESCE(ds.acq_time_start, rr.request_run_start) AS acq_start,
    COALESCE(ds.acq_time_end, rr.request_run_finish) AS acq_end,
    ds.acq_length_minutes AS acq_length,
    ds.scan_count,
    round((((ds.file_size_bytes)::numeric / 1024.0) / (1024)::numeric), 2) AS file_size_mb,
    cartconfig.cart_config_name AS cart_config,
    lc.lc_column,
    ds.separation_type,
    rr.request_id AS request,
    rr.batch_id AS batch,
    eut.eus_usage_type AS usage,
    rr.eus_proposal_id AS proposal,
    rr.work_package,
    rr.requester_username AS requester,
    org.organism,
    bto.term_name AS tissue,
    ds.service_type_id AS svc_center_use_type,
    repstate.svc_center_report_state,
    ds.svc_center_report_state_id,
    ds.date_sort_key
   FROM ((((((((((((((public.t_dataset_state_name dsn
     JOIN public.t_dataset ds ON ((dsn.dataset_state_id = ds.dataset_state_id)))
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     LEFT JOIN public.t_cached_dataset_stats cds ON ((ds.dataset_id = cds.dataset_id)))
     JOIN public.t_dataset_rating_name dsrating ON ((ds.dataset_rating_id = dsrating.dataset_rating_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     LEFT JOIN public.t_cached_dataset_links dl ON ((ds.dataset_id = dl.dataset_id)))
     JOIN public.t_lc_column lc ON ((ds.lc_column_id = lc.lc_column_id)))
     JOIN public.t_organisms org ON ((org.organism_id = e.organism_id)))
     JOIN public.t_dataset_svc_center_report_state repstate ON ((ds.svc_center_report_state_id = repstate.svc_center_report_state_id)))
     LEFT JOIN public.t_lc_cart_configuration cartconfig ON ((ds.cart_config_id = cartconfig.cart_config_id)))
     LEFT JOIN public.t_requested_run rr ON ((ds.dataset_id = rr.dataset_id)))
     LEFT JOIN public.t_eus_usage_type eut ON ((rr.eus_usage_type_id = eut.eus_usage_type_id)))
     LEFT JOIN ont.t_cv_bto_cached_names bto ON ((bto.identifier OPERATOR(public.=) e.tissue_id)))
  WHERE (cds.service_center_eligible_instrument AND (NOT (dtn.dataset_type OPERATOR(public.=) ANY (ARRAY['DataFiles'::public.citext, 'Tracking'::public.citext]))) AND (NOT (c.campaign OPERATOR(public.=) ANY (ARRAY['QC_Mammalian'::public.citext, 'QC-Standard'::public.citext, 'QC-Shew-Standard'::public.citext]))) AND (e.experiment OPERATOR(public.<>) 'Blank'::public.citext) AND (NOT (ds.dataset OPERATOR(public.~~) 'QC_Mam%'::public.citext)) AND (NOT (ds.dataset OPERATOR(public.~~) 'QC_Metab%'::public.citext)) AND (NOT (ds.dataset OPERATOR(public.~~) 'QC_Shew%'::public.citext)) AND (NOT (ds.dataset OPERATOR(public.~~) 'QC_BTLE%'::public.citext)) AND (NOT (e.experiment OPERATOR(public.~~) 'QC_Mam%'::public.citext)) AND (NOT (e.experiment OPERATOR(public.~~) 'QC_Metab%'::public.citext)) AND (NOT (e.experiment OPERATOR(public.~~) 'QC_Shew%'::public.citext)) AND (NOT (e.experiment OPERATOR(public.~~) 'QC_BTLE%'::public.citext)));


ALTER VIEW public.v_svc_center_instrument_datasets OWNER TO d3l243;

--
-- Name: TABLE v_svc_center_instrument_datasets; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_svc_center_instrument_datasets TO readaccess;
GRANT SELECT ON TABLE public.v_svc_center_instrument_datasets TO writeaccess;

