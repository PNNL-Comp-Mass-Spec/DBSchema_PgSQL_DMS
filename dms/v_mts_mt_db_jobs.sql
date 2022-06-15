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
    antool.analysis_tool AS tool,
    aj.param_file_name AS parm_file,
    aj.settings_file_name AS settings_file,
    aj.protein_collection_list,
    ds.separation_type,
    dfp.dataset_folder_path,
    jm.sort_key AS "#SortKey"
   FROM ((public.t_mts_mt_db_jobs_cached jm
     JOIN public.t_mts_mt_dbs_cached mtdbs ON ((jm.mt_db_name OPERATOR(public.=) mtdbs.mt_db_name)))
     LEFT JOIN ((((((public.t_dataset ds
     JOIN public.v_dataset_folder_paths dfp ON ((ds.dataset_id = dfp.dataset_id)))
     JOIN public.t_analysis_job aj ON ((ds.dataset_id = aj.dataset_id)))
     JOIN public.t_instrument_name inst ON ((ds.instrument_id = inst.instrument_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_analysis_tool antool ON ((aj.analysis_tool_id = antool.analysis_tool_id))) ON ((jm.job = aj.job)));


ALTER TABLE public.v_mts_mt_db_jobs OWNER TO d3l243;

--
-- Name: TABLE v_mts_mt_db_jobs; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mts_mt_db_jobs TO readaccess;

