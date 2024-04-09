--
-- Name: v_dataset_psm_and_pm_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_psm_and_pm_list_report AS
 SELECT psm.dataset,
    psm.unique_peptides_fdr AS unique_peptides,
    (qcm.xic_fwhm_q3)::numeric(9,2) AS xic_fwhm_q3,
    qcm.mass_error_ppm,
    COALESCE(qcm.mass_error_ppm_viper, (- pm.ppm_shift)) AS mass_error_amts,
    COALESCE(qcm.amts_10pct_fdr, pm.amts_10pct_fdr) AS amts_10pct_fdr,
    COALESCE(qcm.amts_25pct_fdr, pm.amts_25pct_fdr) AS amts_25pct_fdr,
    ((dfp.dataset_url)::text || 'QC/index.html'::text) AS qc_link,
    pm.results_url AS pm_results_url,
    psm.pct_tryptic,
    psm.pct_missed_clvg,
    psm.total_psms_fdr AS psms,
    psm.keratin_pep,
    psm.phospho_pep,
    psm.trypsin_pep,
    psm.acetyl_pep,
    psm.ubiquitin_pep,
    psm.instrument,
    psm.dataset_id,
    dtn.dataset_type,
    ds.separation_type,
    psm.rating AS ds_rating,
    psm.acq_length AS ds_acq_length,
    psm.acq_time_start AS acq_start,
    psm.job AS psm_job,
    psm.tool AS psm_tool,
    psm.job_progress,
    psm.job_eta_minutes,
    psm.campaign,
    psm.experiment,
    psm.param_file AS psm_job_param_file,
    psm.settings_file AS psm_job_settings_file,
    psm.organism,
    psm.organism_db AS psm_job_org_db,
    psm.protein_collection_list AS psm_job_protein_collection,
    psm.results_folder_path,
    pm.task_id AS pm_task_id,
    pm.task_server AS pm_server,
    pm.task_database AS pm_database,
    pm.ini_file_name AS pm_ini_file_name
   FROM (((((public.v_analysis_job_psm_list_report psm
     JOIN public.v_dataset_folder_paths dfp ON ((psm.dataset_id = dfp.dataset_id)))
     JOIN public.t_dataset ds ON ((psm.dataset_id = ds.dataset_id)))
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     LEFT JOIN public.v_dataset_qc_metrics qcm ON ((psm.dataset_id = qcm.dataset_id)))
     LEFT JOIN public.v_mts_pm_results_list_report pm ON ((psm.dataset_id = pm.dataset_id)))
  WHERE (psm.state_id <> ALL (ARRAY[5, 14]));


ALTER VIEW public.v_dataset_psm_and_pm_list_report OWNER TO d3l243;

--
-- Name: TABLE v_dataset_psm_and_pm_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_psm_and_pm_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_psm_and_pm_list_report TO writeaccess;

