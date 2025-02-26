--
-- Name: v_analysis_job_detail_report_2; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_detail_report_2 AS
 SELECT j.job,
    ds.dataset,
    e.experiment,
    ds.folder_name AS dataset_folder,
    dfp.dataset_folder_path,
        CASE
            WHEN (COALESCE((da.myemsl_state)::integer, 0) > 1) THEN ''::public.citext
            ELSE dfp.archive_folder_path
        END AS archive_folder_path,
    instname.instrument,
    tool.analysis_tool AS tool_name,
    j.param_file_name AS param_file,
    tool.param_file_storage_path,
    j.settings_file_name AS settings_file,
    exporg.organism,
    bto.term_name AS experiment_tissue,
    joborg.organism AS job_organism,
    j.organism_db_name AS organism_db,
    public.get_fasta_file_path((j.organism_db_name)::text, (joborg.organism)::text) AS organism_db_storage_path,
    j.protein_collection_list,
    j.protein_options_list,
        CASE
            WHEN (j.job_state_id = 2) THEN (((((js.job_state)::text || ': '::text) || (((COALESCE(j.progress, (0)::real))::numeric(9,2))::character varying(12))::text) || '%, ETA '::text) ||
            CASE
                WHEN (j.eta_minutes IS NULL) THEN '??'::text
                WHEN (j.eta_minutes > (3600)::double precision) THEN (((((j.eta_minutes / (1440.0)::double precision))::numeric(18,1))::character varying(12))::text || ' days'::text)
                WHEN (j.eta_minutes > (90)::double precision) THEN (((((j.eta_minutes / (60.0)::double precision))::numeric(18,1))::character varying(12))::text || ' hours'::text)
                ELSE ((((j.eta_minutes)::numeric(18,1))::character varying(12))::text || ' minutes'::text)
            END)
            ELSE (js.job_state)::text
        END AS state,
    (j.processing_time_minutes)::numeric(9,2) AS runtime_minutes,
    j.owner_username AS owner,
    j.comment,
    j.special_processing,
        CASE
            WHEN (j.purged = 0) THEN public.combine_paths((dfp.dataset_folder_path)::text, (j.results_folder_name)::text)
            ELSE ('Purged: '::text || public.combine_paths((dfp.dataset_folder_path)::text, (j.results_folder_name)::text))
        END AS results_folder_path,
        CASE
            WHEN ((j.myemsl_state > 0) OR (COALESCE((da.myemsl_state)::integer, 0) > 1)) THEN ''::text
            ELSE public.combine_paths((dfp.archive_folder_path)::text, (j.results_folder_name)::text)
        END AS archive_results_folder_path,
        CASE
            WHEN (j.purged = 0) THEN (((dfp.dataset_url)::text || (j.results_folder_name)::text) || '/'::text)
            ELSE (dfp.dataset_url)::text
        END AS data_folder_link,
    public.get_job_psm_stats(j.job) AS psm_stats,
    j.dataset_id,
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
    t_yes_no.description AS dataset_unreviewed,
    t_myemsl_state.myemsl_state_name AS myemsl_state,
    COALESCE(mtspt.pt_db_count, (0)::bigint) AS mts_pt_db_count,
    COALESCE(mtsmt.mt_db_count, (0)::bigint) AS mts_mt_db_count,
    COALESCE(pmtaskcountq.pmtasks, (0)::bigint) AS peak_matching_results,
    ajpg.group_name AS processor_group
   FROM ((((((ont.t_cv_bto_cached_names bto
     RIGHT JOIN (((((((((((public.t_analysis_job j
     JOIN public.t_dataset ds ON ((j.dataset_id = ds.dataset_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_organisms exporg ON ((e.organism_id = exporg.organism_id)))
     LEFT JOIN public.v_dataset_folder_paths dfp ON ((dfp.dataset_id = ds.dataset_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_analysis_tool tool ON ((j.analysis_tool_id = tool.analysis_tool_id)))
     JOIN public.t_analysis_job_state js ON ((j.job_state_id = js.job_state_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_organisms joborg ON ((joborg.organism_id = j.organism_id)))
     JOIN public.t_yes_no ON ((j.dataset_unreviewed = t_yes_no.flag)))
     JOIN public.t_myemsl_state ON ((j.myemsl_state = t_myemsl_state.myemsl_state))) ON ((bto.identifier OPERATOR(public.=) e.tissue_id)))
     LEFT JOIN (public.t_analysis_job_processor_group ajpg
     JOIN public.t_analysis_job_processor_group_associations ajpja ON ((ajpg.group_id = ajpja.group_id))) ON ((j.job = ajpja.job)))
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
     LEFT JOIN public.t_dataset_archive da ON ((ds.dataset_id = da.dataset_id)));


ALTER VIEW public.v_analysis_job_detail_report_2 OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_detail_report_2; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_detail_report_2 TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_detail_report_2 TO writeaccess;

