--
-- Name: v_dataset_list_report_2; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_list_report_2 AS
 SELECT ds.dataset_id AS id,
    ds.dataset,
    e.experiment,
    c.campaign,
    dsn.dataset_state AS state,
    dsinst.instrument,
    ds.created,
    ds.comment,
    dsrating.dataset_rating AS rating,
    dtn.dataset_type,
    ds.operator_prn AS operator,
    dl.dataset_folder_path,
    dl.archive_folder_path,
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
    rr.requester_prn AS requester,
    org.organism,
    bto.tissue,
    ds.date_sort_key AS "#DateSortKey"
   FROM (((((((((((((public.t_dataset_state_name dsn
     JOIN public.t_dataset ds ON ((dsn.dataset_state_id = ds.dataset_state_id)))
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     LEFT JOIN public.t_cached_dataset_instruments dsinst ON ((ds.dataset_id = dsinst.dataset_id)))
     JOIN public.t_dataset_rating_name dsrating ON ((ds.dataset_rating_id = dsrating.dataset_rating_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     LEFT JOIN public.t_cached_dataset_links dl ON ((ds.dataset_id = dl.dataset_id)))
     JOIN public.t_lc_column lc ON ((ds.lc_column_id = lc.lc_column_id)))
     JOIN public.t_organisms org ON ((org.organism_id = e.organism_id)))
     LEFT JOIN public.t_lc_cart_configuration cartconfig ON ((ds.cart_config_id = cartconfig.cart_config_id)))
     LEFT JOIN public.t_requested_run rr ON ((ds.dataset_id = rr.dataset_id)))
     LEFT JOIN public.t_eus_usage_type eut ON ((rr.eus_usage_type_id = eut.eus_usage_type_id)))
     LEFT JOIN ont.v_bto_id_to_name bto ON ((bto.identifier OPERATOR(public.=) e.tissue_id)));


ALTER TABLE public.v_dataset_list_report_2 OWNER TO d3l243;

--
-- Name: TABLE v_dataset_list_report_2; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_list_report_2 TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_list_report_2 TO writeaccess;

