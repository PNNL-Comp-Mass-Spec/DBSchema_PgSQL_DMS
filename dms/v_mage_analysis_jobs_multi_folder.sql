--
-- Name: v_mage_analysis_jobs_multi_folder; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mage_analysis_jobs_multi_folder AS
 SELECT j.job,
    j.state,
    j.dataset,
    j.dataset_id,
    j.tool,
    j.parameter_file,
    j.settings_file,
    j.instrument,
    j.experiment,
    j.campaign,
    j.organism,
    j.organism_db,
    j.protein_collection_list,
    j.protein_options,
    j.comment,
    j.results_folder,
    ((((COALESCE((((dfp.dataset_folder_path)::text || '\'::text) || (j.results_folder)::text), ''::text) || '|'::text) || COALESCE((((dfp.archive_folder_path)::text || '\'::text) || (j.results_folder)::text), ''::text)) || '|'::text) || COALESCE((((dfp.myemsl_path_flag)::text || '\'::text) || (j.results_folder)::text), ''::text)) AS folder,
    j.dataset_created,
    j.job_finish,
    j.dataset_rating
   FROM (public.v_mage_analysis_jobs j
     JOIN public.v_dataset_folder_paths dfp ON ((j.dataset_id = dfp.dataset_id)));


ALTER TABLE public.v_mage_analysis_jobs_multi_folder OWNER TO d3l243;

--
-- Name: TABLE v_mage_analysis_jobs_multi_folder; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mage_analysis_jobs_multi_folder TO readaccess;

