--
-- Name: v_data_package_datasets_list_report; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_datasets_list_report AS
 SELECT dpd.data_pkg_id AS id,
    ds.dataset,
    dpd.dataset_id,
    e.experiment,
    instname.instrument,
    dpd.package_comment,
    c.campaign,
    dsn.dataset_state AS state,
    ds.created,
    dsrating.dataset_rating AS rating,
    dl.dataset_folder_path,
    COALESCE(ds.acq_time_start, rr.request_run_start) AS acq_start,
    COALESCE(ds.acq_time_end, rr.request_run_finish) AS acq_end,
    ds.acq_length_minutes AS acq_length,
    ds.scan_count,
    lc.lc_column,
    ds.separation_type,
    rr.request_id AS request,
    dpd.item_added,
    ds.comment,
    dtn.dataset_type AS type,
    rr.eus_proposal_id AS proposal,
    cds.psm_job_count AS psm_jobs,
    cds.max_total_psms,
    cds.max_unique_peptides,
    cds.max_unique_proteins,
    cds.max_unique_peptides_fdr_filter
   FROM (((((((((((dpkg.t_data_package_datasets dpd
     JOIN public.t_dataset ds ON ((dpd.dataset_id = ds.dataset_id)))
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_lc_column lc ON ((ds.lc_column_id = lc.lc_column_id)))
     JOIN public.t_dataset_state_name dsn ON ((dsn.dataset_state_id = ds.dataset_state_id)))
     JOIN public.t_dataset_rating_name dsrating ON ((ds.dataset_rating_id = dsrating.dataset_rating_id)))
     LEFT JOIN public.t_cached_dataset_links dl ON ((ds.dataset_id = dl.dataset_id)))
     LEFT JOIN public.t_requested_run rr ON ((ds.dataset_id = rr.dataset_id)))
     LEFT JOIN public.t_cached_dataset_stats cds ON ((dpd.dataset_id = cds.dataset_id)));


ALTER VIEW dpkg.v_data_package_datasets_list_report OWNER TO d3l243;

--
-- Name: TABLE v_data_package_datasets_list_report; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_datasets_list_report TO readaccess;
GRANT SELECT ON TABLE dpkg.v_data_package_datasets_list_report TO writeaccess;

