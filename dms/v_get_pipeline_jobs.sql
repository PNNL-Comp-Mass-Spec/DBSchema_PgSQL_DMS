--
-- Name: v_get_pipeline_jobs; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_get_pipeline_jobs AS
 SELECT j.job,
    j.priority,
    tool.analysis_tool AS tool,
    ds.dataset,
    ds.dataset_id,
    j.settings_file_name,
    j.param_file_name AS parameter_file_name,
    j.job_state_id AS state,
    ((((spath.vol_name_client)::text || 'DMS3_XFER\'::text) || (ds.dataset)::text) || '\'::text) AS transfer_folder_path,
    j.comment,
    j.special_processing,
    j.owner
   FROM ((((public.t_analysis_job j
     JOIN public.t_analysis_tool tool ON ((j.analysis_tool_id = tool.analysis_tool_id)))
     JOIN public.t_dataset ds ON ((j.dataset_id = ds.dataset_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_dataset_archive da ON ((da.dataset_id = ds.dataset_id)))
  WHERE ((j.job_state_id = ANY (ARRAY[1, 8])) AND ((da.archive_state_id = ANY (ARRAY[3, 4, 10, 14, 15])) OR ((da.archive_state_id = 1) AND (da.archive_state_last_affected < (CURRENT_TIMESTAMP - '01:00:00'::interval))) OR ((da.archive_state_id = ANY (ARRAY[2, 6, 9])) AND (da.archive_state_last_affected < (CURRENT_TIMESTAMP - '01:00:00'::interval))) OR ((da.archive_state_id = ANY (ARRAY[7, 8])) AND (da.archive_state_last_affected < (CURRENT_TIMESTAMP - '01:00:00'::interval))) OR (((ds.dataset OPERATOR(public.~~) 'QC_Shew%'::public.citext) OR (ds.dataset OPERATOR(public.~~) 'QC_Mam%'::public.citext)) AND (ds.dataset_rating_id >= 1) AND (NOT (da.archive_state_id = ANY (ARRAY[6, 7]))) AND (da.archive_state_last_affected < (CURRENT_TIMESTAMP - '00:15:00'::interval)))));


ALTER TABLE public.v_get_pipeline_jobs OWNER TO d3l243;

--
-- Name: VIEW v_get_pipeline_jobs; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_get_pipeline_jobs IS 'Ideally we only allow a job to start processing if the dataset is archived (state 3) or purged (states 4, 14, 15) or NonPurgeable (10). But if the archive state is "New" (state 1) for over 60 minutes, let the job start. Also, if the dataset has been in state "Archive in progress", "Operation Failed", or "Holding" (states 2, 6, and 9) for over 60 minutes, let the job start. If the archive state is "Purge in Progress" or "Purge failed" (states 7 and 8) for over 60 minutes, let the job start. Let QC_Shew and QC_Mam datasets start if they have been dispositioned (DS_Rating >= 1) and the archive state changed more than 15 minutes ago. However, exclude QC datasets with an archive state of 6 (Operation Failed) or 7 (Purge In Progress). Note that this view only returns datasets that have an entry in T_Dataset_Archive (which should be true for any instrument-run based job); this is by design.';

--
-- Name: TABLE v_get_pipeline_jobs; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_get_pipeline_jobs TO readaccess;
GRANT SELECT ON TABLE public.v_get_pipeline_jobs TO writeaccess;

