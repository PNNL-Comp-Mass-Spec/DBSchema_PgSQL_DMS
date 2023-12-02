--
-- Name: v_mage_analysis_jobs; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mage_analysis_jobs AS
 SELECT aj.job,
    aj.state_name_cached AS state,
    ds.dataset,
    ds.dataset_id,
    analysistool.analysis_tool AS tool,
    aj.param_file_name AS parameter_file,
    aj.settings_file_name AS settings_file,
    instname.instrument,
    e.experiment,
    c.campaign,
    org.organism,
    aj.organism_db_name AS organism_db,
    aj.protein_collection_list,
    aj.protein_options_list AS protein_options,
    aj.comment,
    COALESCE(aj.results_folder_name, '(none)'::public.citext) AS results_folder,
        CASE
            WHEN (aj.purged = 0) THEN COALESCE((((dfp.dataset_folder_path)::text || '\'::text) || (aj.results_folder_name)::text), ''::text)
            ELSE
            CASE
                WHEN (aj.myemsl_state >= 1) THEN COALESCE((((dfp.myemsl_path_flag)::text || '\'::text) || (aj.results_folder_name)::text), ''::text)
                ELSE COALESCE((((dfp.archive_folder_path)::text || '\'::text) || (aj.results_folder_name)::text), ''::text)
            END
        END AS folder,
    ds.created AS dataset_created,
    aj.finish AS job_finish,
    dr.dataset_rating,
    ds.separation_type,
    dtn.dataset_type,
    aj.request_id
   FROM ((((((((((public.t_analysis_job aj
     JOIN public.t_dataset ds ON ((aj.dataset_id = ds.dataset_id)))
     JOIN public.t_organisms org ON ((aj.organism_id = org.organism_id)))
     JOIN public.t_analysis_tool analysistool ON ((aj.analysis_tool_id = analysistool.analysis_tool_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_dataset_rating_name dr ON ((ds.dataset_rating_id = dr.dataset_rating_id)))
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     JOIN public.v_dataset_folder_paths dfp ON ((ds.dataset_id = dfp.dataset_id)))
  WHERE (aj.job_state_id = ANY (ARRAY[4, 7, 14]));


ALTER VIEW public.v_mage_analysis_jobs OWNER TO d3l243;

--
-- Name: TABLE v_mage_analysis_jobs; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mage_analysis_jobs TO readaccess;
GRANT SELECT ON TABLE public.v_mage_analysis_jobs TO writeaccess;

