--
-- Name: v_data_package_aggregation_list_report; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_aggregation_list_report AS
 SELECT dpkg.get_xml_row(dpd.data_pkg_id, 'Job'::text, (jobq.job)::text) AS sel,
    jobq.job,
    jobq.state,
    jobq.tool,
    ds.dataset,
    dpd.dataset_id,
        CASE
            WHEN (dpj.job IS NULL) THEN 'No'::public.citext
            ELSE 'Yes'::public.citext
        END AS in_package,
    jobq.param_file_name AS param_file,
    jobq.settings_file,
    dpd.data_pkg_id AS data_package_id,
    jobq.organism_db,
    jobq.protein_collection_list,
    jobq.protein_options,
    drn.dataset_rating AS rating,
    instname.instrument
   FROM (((((dpkg.t_data_package_datasets dpd
     JOIN public.t_dataset ds ON ((dpd.dataset_id = ds.dataset_id)))
     JOIN public.t_dataset_rating_name drn ON ((ds.dataset_rating_id = drn.dataset_rating_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     LEFT JOIN ( SELECT j.job,
            j.dataset_id,
            ajs.job_state AS state,
            tool.analysis_tool AS tool,
            j.param_file_name,
            j.settings_file_name AS settings_file,
            j.organism_db_name AS organism_db,
            j.protein_collection_list,
            j.protein_options_list AS protein_options
           FROM ((public.t_analysis_job j
             JOIN public.t_analysis_job_state ajs ON ((j.job_state_id = ajs.job_state_id)))
             JOIN public.t_analysis_tool tool ON ((j.analysis_tool_id = tool.analysis_tool_id)))) jobq ON ((dpd.dataset_id = jobq.dataset_id)))
     LEFT JOIN dpkg.t_data_package_analysis_jobs dpj ON (((dpj.job = jobq.job) AND (dpj.dataset_id = dpd.dataset_id) AND (dpj.data_pkg_id = dpd.data_pkg_id))));


ALTER TABLE dpkg.v_data_package_aggregation_list_report OWNER TO d3l243;

--
-- Name: TABLE v_data_package_aggregation_list_report; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_aggregation_list_report TO readaccess;
GRANT SELECT ON TABLE dpkg.v_data_package_aggregation_list_report TO writeaccess;

