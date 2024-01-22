--
-- Name: v_analysis_job_psm_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_psm_detail_report AS
 SELECT j.job,
    ds.dataset,
    e.experiment,
    instname.instrument,
        CASE
            WHEN (j.purged = 0) THEN (((dfp.dataset_folder_path)::text || '\'::text) || (j.results_folder_name)::text)
            ELSE ((('Purged: '::text || (dfp.dataset_folder_path)::text) || '\'::text) || (j.results_folder_name)::text)
        END AS results_folder_path,
        CASE
            WHEN (j.purged = 0) THEN (((dfp.dataset_url)::text || (j.results_folder_name)::text) || '/'::text)
            ELSE (dfp.dataset_url)::text
        END AS data_folder_link,
    psm.spectra_searched,
    psm.total_psms AS total_psms_msgf_filtered,
    psm.unique_peptides AS unique_peptides_msgf_filtered,
    psm.unique_proteins AS unique_proteins_msgf_filtered,
    psm.total_psms_fdr_filter AS total_psms_fdr_filtered,
    psm.unique_peptides_fdr_filter AS unique_peptides_fdr_filtered,
    psm.unique_proteins_fdr_filter AS unique_proteins_fdr_filtered,
    psm.msgf_threshold,
    ((((psm.fdr_threshold * (100)::double precision))::numeric(5,2))::text || '%'::text) AS fdr_threshold,
    psm.tryptic_peptides_fdr AS unique_tryptic_peptides,
    ((((psm.tryptic_peptides_fdr)::double precision / (NULLIF(psm.unique_peptides_fdr_filter, 0))::double precision) * (100)::double precision))::numeric(9,1) AS pct_tryptic,
    ((psm.missed_cleavage_ratio_fdr * (100)::double precision))::numeric(9,1) AS pct_missed_cleavage,
    psm.keratin_peptides_fdr AS unique_keratin_peptides,
    psm.trypsin_peptides_fdr AS unique_trypsin_peptides,
    psm.acetyl_peptides_fdr AS unique_acetyl_peptides,
    (psm.percent_psms_missing_nterm_reporter_ion)::numeric(9,2) AS pct_missing_nterm_reporter_ions,
    (psm.percent_psms_missing_reporter_ion)::numeric(9,2) AS pct_missing_reporter_ions,
    psm.last_affected AS psm_stats_date,
    phosphopsm.phosphopeptides AS phospho_pep,
    phosphopsm.cterm_k_phosphopeptides AS cterm_k_phospho_pep,
    phosphopsm.cterm_r_phosphopeptides AS cterm_r_phospho_pep,
    ((phosphopsm.missed_cleavage_ratio * (100)::double precision))::numeric(9,1) AS phospho_pct_missed_cleavage,
    COALESCE(mtspt.pt_db_count, (0)::bigint) AS mts_pt_db_count,
    COALESCE(mtsmt.mt_db_count, (0)::bigint) AS mts_mt_db_count,
    COALESCE(pmtaskcountq.pmtasks, (0)::bigint) AS peak_matching_results,
    analysistool.analysis_tool AS tool_name,
    j.param_file_name AS param_file,
    analysistool.param_file_storage_path,
    j.settings_file_name AS settings_file,
    org.organism,
    j.organism_db_name AS organism_db,
    public.get_fasta_file_path((j.organism_db_name)::text, (org.organism)::text) AS organism_db_storage_path,
    j.protein_collection_list,
    j.protein_options_list,
    js.job_state AS state,
    (j.processing_time_minutes)::numeric(9,2) AS runtime_minutes,
    j.owner_username AS owner,
    j.comment,
    j.special_processing,
    j.created,
    j.start AS started,
    j.finish AS finished,
    j.request_id AS request,
    j.priority,
    j.assigned_processor_name AS assigned_processor,
    j.analysis_manager_error AS am_code,
    public.get_dem_code_string((j.data_extraction_error)::integer) AS dem_code,
        CASE j.propagation_mode
            WHEN 0 THEN 'Export'::text
            ELSE 'No Export'::text
        END AS export_mode,
    t_yes_no.description AS dataset_unreviewed
   FROM ((((((((((((((public.t_analysis_job j
     JOIN public.t_dataset ds ON ((j.dataset_id = ds.dataset_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.v_dataset_folder_paths dfp ON ((dfp.dataset_id = ds.dataset_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_analysis_tool analysistool ON ((j.analysis_tool_id = analysistool.analysis_tool_id)))
     JOIN public.t_analysis_job_state js ON ((j.job_state_id = js.job_state_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_organisms org ON ((org.organism_id = j.organism_id)))
     JOIN public.t_yes_no ON ((j.dataset_unreviewed = t_yes_no.flag)))
     LEFT JOIN ( SELECT t_mts_mt_db_jobs_cached.job,
            count(t_mts_mt_db_jobs_cached.cached_info_id) AS mt_db_count
           FROM public.t_mts_mt_db_jobs_cached
          GROUP BY t_mts_mt_db_jobs_cached.job) mtsmt ON ((j.job = mtsmt.job)))
     LEFT JOIN ( SELECT t_mts_pt_db_jobs_cached.job,
            count(t_mts_pt_db_jobs_cached.cached_info_id) AS pt_db_count
           FROM public.t_mts_pt_db_jobs_cached
          GROUP BY t_mts_pt_db_jobs_cached.job) mtspt ON ((j.job = mtspt.job)))
     LEFT JOIN ( SELECT pm.dms_job,
            count(pm.cached_info_id) AS pmtasks
           FROM public.t_mts_peak_matching_tasks_cached pm
          GROUP BY pm.dms_job) pmtaskcountq ON ((pmtaskcountq.dms_job = j.job)))
     LEFT JOIN public.t_analysis_job_psm_stats psm ON ((j.job = psm.job)))
     LEFT JOIN public.t_analysis_job_psm_stats_phospho phosphopsm ON ((psm.job = phosphopsm.job)));


ALTER VIEW public.v_analysis_job_psm_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_psm_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_psm_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_psm_detail_report TO writeaccess;

