--
-- Name: v_analysis_job_psm_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_psm_list_report AS
 SELECT aj.job,
    aj.state_name_cached AS state,
    analysistool.analysis_tool AS tool,
    ds.dataset,
    instname.instrument,
    psm.spectra_searched,
    psm.total_psms AS total_psms_msgf,
    psm.unique_peptides AS unique_peptides_msgf,
    psm.unique_proteins AS unique_proteins_msgf,
    psm.total_psms_fdr_filter AS total_psms_fdr,
    psm.unique_peptides_fdr_filter AS unique_peptides_fdr,
    psm.unique_proteins_fdr_filter AS unique_proteins_fdr,
    psm.msgf_threshold,
    ((psm.fdr_threshold * (100.0)::double precision))::numeric(9,2) AS fdr_threshold_pct,
    psm.tryptic_peptides_fdr AS unique_tryptic_peptides,
    ((((psm.tryptic_peptides_fdr)::double precision / (NULLIF(psm.unique_peptides_fdr_filter, 0))::double precision) * (100)::double precision))::numeric(9,1) AS pct_tryptic,
    ((psm.missed_cleavage_ratio_fdr * (100)::double precision))::numeric(9,1) AS pct_missed_clvg,
    psm.keratin_peptides_fdr AS keratin_pep,
    psm.trypsin_peptides_fdr AS trypsin_pep,
    psm.acetyl_peptides_fdr AS acetyl_pep,
    psm.ubiquitin_peptides_fdr AS ubiquitin_pep,
    (psm.percent_psms_missing_nterm_reporter_ion)::numeric(9,2) AS pct_missing_nterm_rep_ion,
    (psm.percent_psms_missing_reporter_ion)::numeric(9,2) AS pct_missing_rep_ion,
    psm.last_affected AS psm_stats_date,
    phosphopsm.phosphopeptides AS phospho_pep,
    phosphopsm.cterm_k_phosphopeptides AS cterm_k_phospho_pep,
    phosphopsm.cterm_r_phosphopeptides AS cterm_r_phospho_pep,
    ((phosphopsm.missed_cleavage_ratio * (100)::double precision))::numeric(9,1) AS phospho_pct_missed_clvg,
    c.campaign,
    e.experiment,
    aj.param_file_name AS param_file,
    aj.settings_file_name AS settings_file,
    org.organism,
    aj.organism_db_name AS organism_db,
    aj.protein_collection_list,
    aj.protein_options_list AS protein_options,
    aj.comment,
    aj.finish AS finished,
    (aj.processing_time_minutes)::numeric(9,2) AS runtime_minutes,
    aj.request_id AS job_request,
    COALESCE(aj.results_folder_name, '(none)'::public.citext) AS results_folder,
        CASE
            WHEN (aj.purged = 0) THEN (((((spath.vol_name_client)::text || (spath.storage_path)::text) || (COALESCE(ds.folder_name, ds.dataset))::text) || '\'::text) || (aj.results_folder_name)::text)
            ELSE (((((dap.archive_path)::text || '\'::text) || (COALESCE(ds.folder_name, ds.dataset))::text) || '\'::text) || (aj.results_folder_name)::text)
        END AS results_folder_path,
    dr.dataset_rating AS rating,
    ds.acq_length_minutes AS acq_length,
    ds.dataset_id,
    ds.acq_time_start,
    aj.job_state_id AS state_id,
    (aj.progress)::numeric(9,2) AS job_progress,
    (aj.eta_minutes)::numeric(18,1) AS job_eta_minutes
   FROM (((public.v_dataset_archive_path dap
     RIGHT JOIN ((((((((public.t_analysis_job aj
     JOIN public.t_dataset ds ON ((aj.dataset_id = ds.dataset_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_dataset_rating_name dr ON ((ds.dataset_rating_id = dr.dataset_rating_id)))
     JOIN public.t_organisms org ON ((aj.organism_id = org.organism_id)))
     JOIN public.t_analysis_tool analysistool ON ((aj.analysis_tool_id = analysistool.analysis_tool_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id))) ON ((dap.dataset_id = ds.dataset_id)))
     LEFT JOIN public.t_analysis_job_psm_stats psm ON ((aj.job = psm.job)))
     LEFT JOIN public.t_analysis_job_psm_stats_phospho phosphopsm ON ((psm.job = phosphopsm.job)))
  WHERE (aj.analysis_tool_id IN ( SELECT t_analysis_tool.analysis_tool_id
           FROM public.t_analysis_tool
          WHERE (t_analysis_tool.result_type OPERATOR(public.~~) '%peptide_hit'::public.citext)));


ALTER VIEW public.v_analysis_job_psm_list_report OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_psm_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_psm_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_psm_list_report TO writeaccess;

