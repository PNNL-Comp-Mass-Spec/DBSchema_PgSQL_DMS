--
-- Name: v_analysis_job_psm_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_psm_detail_report AS
 SELECT aj.job,
    ds.dataset,
    e.experiment,
    instname.instrument,
        CASE
            WHEN (aj.purged = 0) THEN (((dfp.dataset_folder_path)::text || '\'::text) || (aj.results_folder_name)::text)
            ELSE ((('Purged: '::text || (dfp.dataset_folder_path)::text) || '\'::text) || (aj.results_folder_name)::text)
        END AS results_folder_path,
        CASE
            WHEN (aj.purged = 0) THEN (((dfp.dataset_url)::text || (aj.results_folder_name)::text) || '/'::text)
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
    aj.param_file_name AS param_file,
    analysistool.param_file_storage_path,
    aj.settings_file_name AS settings_file,
    org.organism,
    aj.organism_db_name AS organism_db,
    public.get_fasta_file_path(aj.organism_db_name, org.organism) AS organism_db_storage_path,
    aj.protein_collection_list,
    aj.protein_options_list,
    asn.job_state AS state,
    (aj.processing_time_minutes)::numeric(9,2) AS runtime_minutes,
    aj.owner,
    aj.comment,
    aj.special_processing,
    aj.created,
    aj.start AS started,
    aj.finish AS finished,
    aj.request_id AS request,
    aj.priority,
    aj.assigned_processor_name AS assigned_processor,
    aj.analysis_manager_error AS am_code,
    public.get_dem_code_string((aj.data_extraction_error)::integer) AS dem_code,
        CASE aj.propagation_mode
            WHEN 0 THEN 'Export'::text
            ELSE 'No Export'::text
        END AS export_mode,
    t_yes_no.description AS dataset_unreviewed
   FROM ((((((((((((((public.t_analysis_job aj
     JOIN public.t_dataset ds ON ((aj.dataset_id = ds.dataset_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.v_dataset_folder_paths dfp ON ((dfp.dataset_id = ds.dataset_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_analysis_tool analysistool ON ((aj.analysis_tool_id = analysistool.analysis_tool_id)))
     JOIN public.t_analysis_job_state asn ON ((aj.job_state_id = asn.job_state_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_organisms org ON ((org.organism_id = aj.organism_id)))
     JOIN public.t_yes_no ON ((aj.dataset_unreviewed = t_yes_no.flag)))
     LEFT JOIN ( SELECT t_mts_mt_db_jobs_cached.job,
            count(*) AS mt_db_count
           FROM public.t_mts_mt_db_jobs_cached
          GROUP BY t_mts_mt_db_jobs_cached.job) mtsmt ON ((aj.job = mtsmt.job)))
     LEFT JOIN ( SELECT t_mts_pt_db_jobs_cached.job,
            count(*) AS pt_db_count
           FROM public.t_mts_pt_db_jobs_cached
          GROUP BY t_mts_pt_db_jobs_cached.job) mtspt ON ((aj.job = mtspt.job)))
     LEFT JOIN ( SELECT pm.dms_job,
            count(*) AS pmtasks
           FROM public.t_mts_peak_matching_tasks_cached pm
          GROUP BY pm.dms_job) pmtaskcountq ON ((pmtaskcountq.dms_job = aj.job)))
     LEFT JOIN public.t_analysis_job_psm_stats psm ON ((aj.job = psm.job)))
     LEFT JOIN public.t_analysis_job_psm_stats_phospho phosphopsm ON ((psm.job = phosphopsm.job)));


ALTER TABLE public.v_analysis_job_psm_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_psm_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_psm_detail_report TO readaccess;

