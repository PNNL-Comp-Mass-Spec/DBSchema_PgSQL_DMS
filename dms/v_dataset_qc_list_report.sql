--
-- Name: v_dataset_qc_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_qc_list_report AS
 SELECT ds.dataset_id AS id,
    ds.dataset,
    (((((spath.url_https)::text || (COALESCE(ds.folder_name, ds.dataset))::text) || '/QC/'::text) || (ds.dataset)::text) || '_BPI_MS.png'::text) AS qc_link,
    (((((spath.url_https)::text || (COALESCE(ds.folder_name, ds.dataset))::text) || '/QC/'::text) || (ds.dataset)::text) || '_HighAbu_LCMS.png'::text) AS qc_2d,
    (((((((spath.url_https)::text || (COALESCE(ds.folder_name, ds.dataset))::text) || '/'::text) || (j.results_folder_name)::text) || '/'::text) || (ds.dataset)::text) || '_HighAbu_LCMS_zoom.png'::text) AS qc_decontools,
    e.experiment,
    c.campaign,
    instname.instrument,
    ds.created,
    ds.comment,
    dsn.dataset_state AS state,
    dsrating.dataset_rating AS rating,
    ds.acq_length_minutes AS acq_length,
    COALESCE(ds.acq_time_start, rr.request_run_start) AS acq_start,
    COALESCE(ds.acq_time_end, rr.request_run_finish) AS acq_end,
    dtn.dataset_type,
    ds.operator_username AS operator,
    lc.lc_column,
    rr.request_id AS request,
    rr.batch_id AS batch,
    ds.separation_type
   FROM ((((((((((public.t_dataset_state_name dsn
     JOIN public.t_dataset ds ON ((dsn.dataset_state_id = ds.dataset_state_id)))
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_dataset_rating_name dsrating ON ((ds.dataset_rating_id = dsrating.dataset_rating_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_storage_path spath ON ((spath.storage_path_id = ds.storage_path_id)))
     JOIN public.t_lc_column lc ON ((ds.lc_column_id = lc.lc_column_id)))
     LEFT JOIN public.t_requested_run rr ON ((ds.dataset_id = rr.dataset_id)))
     LEFT JOIN public.t_analysis_job j ON ((ds.decontools_job_for_qc = j.job)));


ALTER TABLE public.v_dataset_qc_list_report OWNER TO d3l243;

--
-- Name: TABLE v_dataset_qc_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_qc_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_qc_list_report TO writeaccess;

