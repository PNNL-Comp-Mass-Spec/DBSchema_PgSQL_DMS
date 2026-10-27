--
-- Name: v_dataset_acq_log_messages_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_acq_log_messages_list_report AS
 SELECT ds.dataset_id AS id,
    ds.dataset,
    acqmsgs.msg_type,
    acqmsgs.message,
    acqmsgs.obs_count,
    (acqmsgs.elution_time_min)::numeric(9,2) AS elution_time_min,
    (acqmsgs.elution_time_max)::numeric(9,2) AS elution_time_max,
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
    rr.eus_proposal_id AS proposal,
    rr.work_package,
    rr.requester_username AS requester,
    org.organism,
    ds.date_sort_key
   FROM ((((((((((((public.t_dataset_acq_messages acqmsgs
     JOIN public.t_dataset ds ON ((ds.dataset_id = acqmsgs.dataset_id)))
     JOIN public.t_dataset_state_name dsn ON ((dsn.dataset_state_id = ds.dataset_state_id)))
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     LEFT JOIN public.t_cached_dataset_stats cds ON ((ds.dataset_id = cds.dataset_id)))
     JOIN public.t_dataset_rating_name dsrating ON ((ds.dataset_rating_id = dsrating.dataset_rating_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     LEFT JOIN public.t_cached_dataset_links dl ON ((ds.dataset_id = dl.dataset_id)))
     JOIN public.t_lc_column lc ON ((ds.lc_column_id = lc.lc_column_id)))
     JOIN public.t_organisms org ON ((org.organism_id = e.organism_id)))
     LEFT JOIN public.t_lc_cart_configuration cartconfig ON ((ds.cart_config_id = cartconfig.cart_config_id)))
     LEFT JOIN public.t_requested_run rr ON ((ds.dataset_id = rr.dataset_id)));


ALTER VIEW public.v_dataset_acq_log_messages_list_report OWNER TO d3l243;

--
-- Name: TABLE v_dataset_acq_log_messages_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_acq_log_messages_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_acq_log_messages_list_report TO writeaccess;

