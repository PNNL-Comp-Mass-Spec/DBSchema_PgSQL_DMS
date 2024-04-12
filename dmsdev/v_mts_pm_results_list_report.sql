--
-- Name: v_mts_pm_results_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mts_pm_results_list_report AS
 SELECT pm.dms_job AS job,
    ds.dataset,
    pm.tool_name,
    pm.job_start AS task_start,
    pm.results_url,
    pm.task_id,
    pm.state_id AS task_state_id,
    pm.job_finish AS task_finish,
    pm.task_server,
    pm.task_database,
    pm.tool_version,
    pm.output_folder_path,
    pm.mts_job_id,
    inst.instrument,
    pm.amt_count_1pct_fdr AS amts_1pct_fdr,
    pm.amt_count_5pct_fdr AS amts_5pct_fdr,
    pm.amt_count_10pct_fdr AS amts_10pct_fdr,
    pm.amt_count_25pct_fdr AS amts_25pct_fdr,
    pm.amt_count_50pct_fdr AS amts_50pct_fdr,
    pm.refine_mass_cal_ppm_shift AS ppm_shift,
    pm.qid,
    pm.md_id,
    aj.param_file_name AS param_file,
    aj.settings_file_name AS settings_file,
    pm.ini_file_name,
    pm.comparison_mass_tag_count,
    pm.md_state,
    ds.dataset_id,
    ds.acq_length_minutes AS acq_length,
    ds.acq_time_start
   FROM (((public.t_dataset ds
     JOIN public.t_analysis_job aj ON ((ds.dataset_id = aj.dataset_id)))
     JOIN public.t_instrument_name inst ON ((ds.instrument_id = inst.instrument_id)))
     RIGHT JOIN public.t_mts_peak_matching_tasks_cached pm ON ((aj.job = pm.dms_job)));


ALTER VIEW public.v_mts_pm_results_list_report OWNER TO d3l243;

--
-- Name: TABLE v_mts_pm_results_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mts_pm_results_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_mts_pm_results_list_report TO writeaccess;

