--
-- Name: v_qc_metrics_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_qc_metrics_list_report AS
 SELECT ds.dataset,
    round((((ds.file_size_bytes)::numeric / 1024.0) / 1024.0), 1) AS file_size_mb,
    pm.amt_count_10pct_fdr AS amts_10pct_fdr,
    pm.amt_count_50pct_fdr AS amts_50pct_fdr,
    pm.refine_mass_cal_ppm_shift AS ppm_shift,
    pm.results_url,
    (((((spath.url_https)::text || (COALESCE(ds.folder_name, ds.dataset))::text) || '/QC/'::text) || (ds.dataset)::text) || '_BPI_MS.png'::text) AS qc_link,
    pm.task_database,
    aj.param_file_name AS param_file,
    aj.settings_file_name AS settings_file,
    public.get_factor_list(rr.request_id) AS factors,
    inst.instrument,
    pm.dms_job AS job,
    pm.tool_name,
    ds.acq_time_start AS acquisition_start,
    ds.acq_time_end AS acquisition_end,
    dsn.dataset_state AS state,
    dsrating.dataset_rating AS rating,
    lc.lc_column,
    aj.created,
    aj.start AS started,
    aj.finish AS finished,
    pm.ini_file_name,
    pm.md_state
   FROM ((((((((public.t_dataset ds
     JOIN public.t_analysis_job aj ON ((ds.dataset_id = aj.dataset_id)))
     JOIN public.t_instrument_name inst ON ((ds.instrument_id = inst.instrument_id)))
     RIGHT JOIN public.t_mts_peak_matching_tasks_cached pm ON ((aj.job = pm.dms_job)))
     JOIN public.t_lc_column lc ON ((ds.lc_column_id = lc.lc_column_id)))
     JOIN public.t_dataset_rating_name dsrating ON ((ds.dataset_rating_id = dsrating.dataset_rating_id)))
     JOIN public.t_dataset_state_name dsn ON ((dsn.dataset_state_id = ds.dataset_state_id)))
     LEFT JOIN public.t_requested_run rr ON ((ds.dataset_id = rr.dataset_id)))
     LEFT JOIN public.t_storage_path spath ON ((spath.storage_path_id = ds.storage_path_id)));


ALTER TABLE public.v_qc_metrics_list_report OWNER TO d3l243;

--
-- Name: TABLE v_qc_metrics_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_qc_metrics_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_qc_metrics_list_report TO writeaccess;

