--
-- Name: v_data_package_datasets_list_report_for_data_pkg; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_datasets_list_report_for_data_pkg AS
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
    count(aj.job) AS psm_jobs,
    COALESCE(max(psm_1.total_psms_fdr_filter), max(psm_1.total_psms)) AS max_total_psms,
    COALESCE(max(psm_1.unique_peptides_fdr_filter), max(psm_1.unique_peptides)) AS max_unique_peptides,
    COALESCE(max(psm_1.unique_proteins_fdr_filter), max(psm_1.unique_proteins)) AS max_unique_proteins,
    max(psm_1.unique_peptides_fdr_filter) AS max_unique_peptides_fdr_filter
   FROM ((((((((((((dpkg.t_data_package_datasets dpd
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
     LEFT JOIN public.t_analysis_job aj ON (((ds.dataset_id = aj.dataset_id) AND (aj.analysis_tool_id IN ( SELECT t_analysis_tool.analysis_tool_id
           FROM public.t_analysis_tool
          WHERE (t_analysis_tool.result_type OPERATOR(public.~~) '%peptide_hit'::public.citext))))))
     LEFT JOIN public.t_analysis_job_psm_stats psm_1 ON ((aj.job = psm_1.job)))
  GROUP BY dpd.data_pkg_id, ds.dataset, dpd.dataset_id, e.experiment, instname.instrument, dpd.package_comment, c.campaign, dsn.dataset_state, ds.created, dsrating.dataset_rating, dl.dataset_folder_path, COALESCE(ds.acq_time_start, rr.request_run_start), COALESCE(ds.acq_time_end, rr.request_run_finish), ds.acq_length_minutes, ds.scan_count, lc.lc_column, ds.separation_type, rr.request_id, dpd.item_added, ds.comment, dtn.dataset_type, rr.eus_proposal_id;


ALTER VIEW dpkg.v_data_package_datasets_list_report_for_data_pkg OWNER TO d3l243;

--
-- Name: VIEW v_data_package_datasets_list_report_for_data_pkg; Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON VIEW dpkg.v_data_package_datasets_list_report_for_data_pkg IS 'This view has excellent performance if you filter on a single data package; performance is poor without a filter';

--
-- Name: TABLE v_data_package_datasets_list_report_for_data_pkg; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_datasets_list_report_for_data_pkg TO readaccess;
GRANT SELECT ON TABLE dpkg.v_data_package_datasets_list_report_for_data_pkg TO writeaccess;

