--
-- Name: v_mts_mt_db_jobs; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mts_mt_db_jobs AS
 SELECT jm.job,
    ds.dataset,
    jm.server_name,
    jm.mt_db_name,
    jm.result_type,
    jm.last_affected,
    jm.process_state,
    inst.instrument,
    c.campaign,
    tool.analysis_tool AS tool,
    j.param_file_name AS param_file,
    j.settings_file_name AS settings_file,
    j.protein_collection_list,
    ds.separation_type,
    dfp.dataset_folder_path,
    jm.sort_key AS "#sort_key"
   FROM ((public.t_mts_mt_db_jobs_cached jm
     JOIN public.t_mts_mt_dbs_cached mtdbs ON ((jm.mt_db_name OPERATOR(public.=) mtdbs.mt_db_name)))
     LEFT JOIN ((((((public.t_dataset ds
     JOIN public.v_dataset_folder_paths dfp ON ((ds.dataset_id = dfp.dataset_id)))
     JOIN public.t_analysis_job j ON ((ds.dataset_id = j.dataset_id)))
     JOIN public.t_instrument_name inst ON ((ds.instrument_id = inst.instrument_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_analysis_tool tool ON ((j.analysis_tool_id = tool.analysis_tool_id))) ON ((jm.job = j.job)));


ALTER TABLE public.v_mts_mt_db_jobs OWNER TO d3l243;

--
-- Name: TABLE v_mts_mt_db_jobs; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mts_mt_db_jobs TO readaccess;
GRANT SELECT ON TABLE public.v_mts_mt_db_jobs TO writeaccess;

