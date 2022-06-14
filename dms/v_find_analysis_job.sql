--
-- Name: v_find_analysis_job; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_find_analysis_job AS
 SELECT aj.job,
    aj.priority AS pri,
    aj.state_name_cached AS state,
    analysistool.analysis_tool AS tool,
    ds.dataset,
    c.campaign,
    e.experiment,
    instname.instrument,
    aj.param_file_name AS parm_file,
    aj.settings_file_name AS settings_file,
    org.organism,
    aj.organism_db_name AS organism_db,
    aj.protein_collection_list,
    aj.protein_options_list AS protein_options,
    aj.comment,
    aj.created,
    aj.start AS started,
    aj.finish AS finished,
    COALESCE(aj.assigned_processor_name, '(none)'::public.citext) AS processor,
    aj.request_id AS run_request,
    (((((dap.archive_path)::text || '\'::text) || (ds.dataset)::text) || '\'::text) || (aj.results_folder_name)::text) AS archive_folder_path
   FROM (public.v_dataset_archive_path dap
     RIGHT JOIN (((((((public.t_analysis_job aj
     JOIN public.t_dataset ds ON ((aj.dataset_id = ds.dataset_id)))
     JOIN public.t_organisms org ON ((aj.organism_id = org.organism_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_analysis_tool analysistool ON ((aj.analysis_tool_id = analysistool.analysis_tool_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id))) ON ((dap.dataset_id = ds.dataset_id)));


ALTER TABLE public.v_find_analysis_job OWNER TO d3l243;

--
-- Name: TABLE v_find_analysis_job; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_find_analysis_job TO readaccess;

