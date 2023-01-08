--
-- Name: v_data_package_analysis_jobs_list_report; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_analysis_jobs_list_report AS
 SELECT dpj.data_pkg_id AS id,
    dpj.job,
    dpj.dataset,
    dpj.dataset_id,
    dpj.tool,
    dpj.package_comment,
    c.campaign,
    e.experiment,
    instname.instrument,
    aj.param_file_name AS param_file,
    aj.settings_file_name AS settings_file,
    exporg.organism,
    aj.organism_db_name AS organism_db,
    aj.protein_collection_list,
    aj.protein_options_list AS protein_options,
    aj.state_name_cached AS state,
    aj.finish AS finished,
    round((aj.processing_time_minutes)::numeric, 2) AS runtime_minutes,
    aj.request_id AS job_request,
    COALESCE(aj.results_folder_name, '(none)'::public.citext) AS results_folder,
        CASE
            WHEN (aj.purged = 0) THEN (((((spath.vol_name_client)::text || (spath.storage_path)::text) || (COALESCE(ds.folder_name, ds.dataset))::text) || '\'::text) || (aj.results_folder_name)::text)
            ELSE 'Purged'::text
        END AS results_folder_path,
        CASE
            WHEN (aj.purged = 0) THEN (((dfp.dataset_url)::text || (aj.results_folder_name)::text) || '/'::text)
            ELSE (dfp.dataset_url)::text
        END AS results_url,
    dpj.item_added,
    aj.comment
   FROM ((((((((dpkg.t_data_package_analysis_jobs dpj
     JOIN public.t_analysis_job aj ON ((dpj.job = aj.job)))
     JOIN public.t_dataset ds ON ((aj.dataset_id = ds.dataset_id)))
     JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_organisms exporg ON ((e.organism_id = exporg.organism_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     LEFT JOIN public.t_cached_dataset_folder_paths dfp ON ((ds.dataset_id = dfp.dataset_id)));


ALTER TABLE dpkg.v_data_package_analysis_jobs_list_report OWNER TO d3l243;

--
-- Name: TABLE v_data_package_analysis_jobs_list_report; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_analysis_jobs_list_report TO readaccess;
GRANT SELECT ON TABLE dpkg.v_data_package_analysis_jobs_list_report TO writeaccess;

