--
-- Name: v_analysis_job_export_storage_path; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_export_storage_path AS
 SELECT aj.job,
    ds.dataset,
    ((dsarch.archive_path)::text || '\'::text) AS storagepathclient,
    public.combine_paths((sp.vol_name_client)::text, (sp.storage_path)::text) AS storagepathserver,
    ds.folder_name AS datasetfolder,
    aj.results_folder_name AS resultsfolder
   FROM (((public.t_analysis_job aj
     JOIN public.t_dataset ds ON ((aj.dataset_id = ds.dataset_id)))
     JOIN public.v_dataset_archive_path dsarch ON ((ds.dataset_id = dsarch.dataset_id)))
     JOIN public.t_storage_path sp ON ((ds.storage_path_id = sp.storage_path_id)))
  WHERE (aj.job_state_id = ANY (ARRAY[4, 14]));


ALTER TABLE public.v_analysis_job_export_storage_path OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_export_storage_path; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_export_storage_path TO readaccess;

