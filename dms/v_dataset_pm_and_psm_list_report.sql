--
-- Name: v_dataset_pm_and_psm_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_pm_and_psm_list_report AS
 SELECT pm.dataset,
    psm.unique_peptides_fdr AS unique_peptides,
    (qcm.xic_fwhm_q3)::numeric(9,2) AS xic_fwhm_q3,
    qcm.mass_error_ppm,
    COALESCE(qcm.mass_error_ppm_viper, (- pm.ppm_shift)) AS mass_error_amts,
    COALESCE(qcm.amts_10pct_fdr, pm.amts_10pct_fdr) AS amts_10pct_fdr,
    COALESCE(qcm.amts_25pct_fdr, pm.amts_25pct_fdr) AS amts_25pct_fdr,
    ((dfp.dataset_url)::text || 'QC/index.html'::text) AS qc_link,
    pm.results_url AS pm_results_url,
    psm.phospho_pep,
    pm.instrument,
    pm.dataset_id,
    dtn.dataset_type,
    ds.separation_type,
    dr.dataset_rating AS ds_rating,
    pm.acq_length AS ds_acq_length,
    pm.acq_time_start AS acq_start,
    psm.job AS psm_job,
    psm.tool AS psm_tool,
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
   FROM ((((((public.v_mts_pm_results_list_report pm
     JOIN public.v_dataset_folder_paths dfp ON ((pm.dataset_id = dfp.dataset_id)))
     JOIN public.t_dataset ds ON ((pm.dataset_id = ds.dataset_id)))
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     JOIN public.t_dataset_rating_name dr ON ((ds.dataset_rating_id = dr.dataset_rating_id)))
     LEFT JOIN public.v_dataset_qc_metrics qcm ON ((pm.dataset_id = qcm.dataset_id)))
     LEFT JOIN public.v_analysis_job_psm_list_report psm ON (((psm.dataset_id = pm.dataset_id) AND (psm.state_id <> ALL (ARRAY[5, 14])))));


ALTER TABLE public.v_dataset_pm_and_psm_list_report OWNER TO d3l243;

--
-- Name: TABLE v_dataset_pm_and_psm_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_pm_and_psm_list_report TO readaccess;

