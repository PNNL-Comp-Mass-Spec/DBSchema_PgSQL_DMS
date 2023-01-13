--
-- Name: v_analysis_job_export_multialign; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_export_multialign AS
 SELECT ds.dataset_id AS datasetid,
    spath.vol_name_client AS volname,
    spath.storage_path AS path,
    ds.folder_name AS datasetfolder,
    j.results_folder_name AS resultsfolder,
    ds.dataset AS datasetname,
    j.job AS jobid,
    ds.lc_column_id AS columnid,
    COALESCE(ds.acq_time_start, ds.created) AS acquisitiontime,
    e.labelling,
    instname.instrument AS instrumentname,
    j.analysis_tool_id AS toolid,
    rr.block AS blocknum,
    rr.request_name AS replicatename,
    ds.exp_id AS experimentid,
    rr.run_order AS runorder,
    rr.batch_id AS batchid,
    dfp.archive_folder_path AS archpath,
    dfp.dataset_folder_path AS datasetfullpath,
    org.organism,
    c.campaign,
    j.param_file_name AS parameterfilename,
    j.settings_file_name AS settingsfilename
   FROM ((((((((public.t_dataset ds
     JOIN public.t_analysis_job j ON ((ds.dataset_id = j.dataset_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_organisms org ON ((e.organism_id = org.organism_id)))
     LEFT JOIN public.t_requested_run rr ON ((rr.dataset_id = ds.dataset_id)))
     JOIN public.v_dataset_folder_paths dfp ON ((ds.dataset_id = dfp.dataset_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
  WHERE ((j.analysis_tool_id = ANY (ARRAY[2, 7, 10, 11, 12, 16, 18, 27])) AND (j.job_state_id = 4));


ALTER TABLE public.v_analysis_job_export_multialign OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_export_multialign; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_export_multialign TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_export_multialign TO writeaccess;

