--
-- Name: v_analysis_job_list_report_2; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_list_report_2 AS
 SELECT j.job,
    j.priority AS pri,
    j.state_name_cached AS state,
    j.analysis_tool_cached AS tool,
    ds.dataset,
    c.campaign,
    e.experiment,
    instname.instrument,
    j.param_file_name AS param_file,
    j.settings_file_name AS settings_file,
    exporg.organism,
    bto.tissue,
    joborg.organism AS job_organism,
    j.organism_db_name AS organism_db,
    j.protein_collection_list,
    j.protein_options_list AS protein_options,
    j.comment,
    ds.dataset_id,
    j.created,
    j.start AS started,
    j.finish AS finished,
    round((j.processing_time_minutes)::numeric, 2) AS runtime_minutes,
    round((j.progress)::numeric, 2) AS progress,
    round((j.eta_minutes)::numeric, 1) AS eta_minutes,
    j.request_id AS job_request,
    COALESCE(j.results_folder_name, '(none)'::public.citext) AS results_folder,
        CASE
            WHEN (j.purged = 0) THEN (((((spath.vol_name_client)::text || (spath.storage_path)::text) || (COALESCE(ds.folder_name, ds.dataset))::text) || '\'::text) || (j.results_folder_name)::text)
            ELSE 'Purged'::text
        END AS results_folder_path,
        CASE
            WHEN (j.purged = 0) THEN (((dfp.dataset_url)::text || (j.results_folder_name)::text) || '/'::text)
            ELSE (dfp.dataset_url)::text
        END AS results_url,
    j.last_affected,
    dr.dataset_rating AS rating
   FROM ((((((((((public.t_analysis_job j
     JOIN public.t_dataset ds ON ((j.dataset_id = ds.dataset_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_dataset_rating_name dr ON ((ds.dataset_rating_id = dr.dataset_rating_id)))
     JOIN public.t_organisms joborg ON ((j.organism_id = joborg.organism_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_organisms exporg ON ((e.organism_id = exporg.organism_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     LEFT JOIN public.t_cached_dataset_folder_paths dfp ON ((ds.dataset_id = dfp.dataset_id)))
     LEFT JOIN ont.v_bto_id_to_name bto ON ((bto.identifier OPERATOR(public.=) e.tissue_id)));


ALTER TABLE public.v_analysis_job_list_report_2 OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_list_report_2; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_list_report_2 TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_list_report_2 TO writeaccess;

