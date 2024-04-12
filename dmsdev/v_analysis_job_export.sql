--
-- Name: v_analysis_job_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_export AS
 SELECT aj.job,
    ds.dataset,
    exp.experiment,
    campaign.campaign,
    aj.dataset_id AS datasetid,
    org.organism,
    instname.instrument AS instrumentname,
    instname.instrument_class AS instrumentclass,
    analysistool.analysis_tool AS analysistool,
    aj.finish AS completed,
    aj.param_file_name AS parameterfilename,
    aj.settings_file_name AS settingsfilename,
    aj.organism_db_name AS organismdbname,
    aj.protein_collection_list AS proteincollectionlist,
    aj.protein_options_list AS proteinoptions,
    ((dsarch.archive_path)::text || '\'::text) AS storagepathclient,
    public.combine_paths((spath.vol_name_client)::text, (spath.storage_path)::text) AS storagepathserver,
    ds.folder_name AS datasetfolder,
    aj.results_folder_name AS resultsfolder,
    ds.separation_type AS separationsystype,
    analysistool.result_type AS resulttype,
    ds.created AS ds_created,
    exp.enzyme_id AS enzymeid
   FROM ((((((((public.t_analysis_job aj
     JOIN public.t_dataset ds ON ((aj.dataset_id = ds.dataset_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_experiments exp ON ((ds.exp_id = exp.exp_id)))
     JOIN public.t_analysis_tool analysistool ON ((aj.analysis_tool_id = analysistool.analysis_tool_id)))
     JOIN public.t_campaign campaign ON ((exp.campaign_id = campaign.campaign_id)))
     JOIN public.t_organisms org ON ((exp.organism_id = org.organism_id)))
     JOIN public.v_dataset_archive_path dsarch ON ((ds.dataset_id = dsarch.dataset_id)))
  WHERE ((aj.job_state_id = 4) AND ((ds.dataset_rating_id >= 1) OR (ds.dataset_rating_id = '-6'::integer)));


ALTER VIEW public.v_analysis_job_export OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_export TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_export TO writeaccess;

