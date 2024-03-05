--
-- Name: v_analysis_job_export_ex; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_export_ex AS
 SELECT aj.job,
    aj.priority,
    ds.dataset,
    e.experiment,
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
    aj.owner_username AS owner,
    aj.comment,
    ds.separation_type AS separationsystype,
    analysistool.result_type AS resulttype,
    dataset_int_std.name AS dataset_int_std,
    ds.created AS ds_created,
        CASE
            WHEN ((ds.acq_time_end - ds.acq_time_start) < '90 days'::interval) THEN (EXTRACT(epoch FROM (ds.acq_time_end - ds.acq_time_start)) / (60)::numeric)
            ELSE NULL::numeric
        END AS ds_acq_length,
    e.enzyme_id AS enzymeid,
    e.labelling,
    predigest_int_std.name AS predigest_int_std,
    postdigest_int_std.name AS postdigest_int_std,
    aj.assigned_processor_name AS processor,
    aj.request_id AS requestid,
    aj.myemsl_state AS myemslstate
   FROM (((((((((((public.t_analysis_job aj
     JOIN public.t_dataset ds ON ((aj.dataset_id = ds.dataset_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_analysis_tool analysistool ON ((aj.analysis_tool_id = analysistool.analysis_tool_id)))
     JOIN public.t_campaign campaign ON ((e.campaign_id = campaign.campaign_id)))
     JOIN public.t_internal_standards dataset_int_std ON ((ds.internal_standard_id = dataset_int_std.internal_standard_id)))
     JOIN public.t_internal_standards predigest_int_std ON ((e.internal_standard_id = predigest_int_std.internal_standard_id)))
     JOIN public.t_internal_standards postdigest_int_std ON ((e.post_digest_internal_std_id = postdigest_int_std.internal_standard_id)))
     JOIN public.t_organisms org ON ((e.organism_id = org.organism_id)))
     JOIN public.v_dataset_archive_path dsarch ON ((ds.dataset_id = dsarch.dataset_id)))
  WHERE ((aj.job_state_id = 4) AND ((ds.dataset_rating_id >= 1) OR (ds.dataset_rating_id = '-6'::integer)));


ALTER VIEW public.v_analysis_job_export_ex OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_export_ex; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_export_ex TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_export_ex TO writeaccess;

