--
-- Name: v_data_package_analysis_jobs; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_data_package_analysis_jobs AS
 SELECT dpj.data_pkg_id,
    dpj.job,
    ds.dataset,
    aj.dataset_id,
    t.analysis_tool AS tool,
    dpj.package_comment,
    dpj.item_added,
        CASE
            WHEN (aj.purged = 0) THEN COALESCE((((dfp.dataset_folder_path)::text || '\'::text) || (aj.results_folder_name)::text), ''::text)
            ELSE
            CASE
                WHEN (aj.myemsl_state >= 1) THEN COALESCE((((dfp.myemsl_path_flag)::text || '\'::text) || (aj.results_folder_name)::text), ''::text)
                ELSE COALESCE((((dfp.archive_folder_path)::text || '\'::text) || (aj.results_folder_name)::text), ''::text)
            END
        END AS folder,
    dpj.data_pkg_id AS data_package_id
   FROM ((((dpkg.t_data_package_analysis_jobs dpj
     JOIN public.t_analysis_job aj ON ((aj.job = dpj.job)))
     JOIN public.t_analysis_tool t ON ((aj.analysis_tool_id = t.analysis_tool_id)))
     JOIN public.t_dataset ds ON ((aj.dataset_id = ds.dataset_id)))
     JOIN public.v_dataset_folder_paths dfp ON ((ds.dataset_id = dfp.dataset_id)));


ALTER VIEW public.v_data_package_analysis_jobs OWNER TO d3l243;

--
-- Name: TABLE v_data_package_analysis_jobs; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_data_package_analysis_jobs TO readaccess;
GRANT SELECT ON TABLE public.v_data_package_analysis_jobs TO writeaccess;

