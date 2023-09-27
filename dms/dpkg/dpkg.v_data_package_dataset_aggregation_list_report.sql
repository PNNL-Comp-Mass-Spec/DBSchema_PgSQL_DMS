--
-- Name: v_data_package_dataset_aggregation_list_report; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_dataset_aggregation_list_report AS
 SELECT dpj.data_pkg_id AS id,
    ds.dataset,
    count(dpj.job) AS jobs
   FROM ((dpkg.t_data_package_analysis_jobs dpj
     JOIN public.t_analysis_job aj ON ((aj.job = dpj.job)))
     JOIN public.t_dataset ds ON ((aj.dataset_id = ds.dataset_id)))
  GROUP BY ds.dataset, dpj.data_pkg_id;


ALTER TABLE dpkg.v_data_package_dataset_aggregation_list_report OWNER TO d3l243;

--
-- Name: TABLE v_data_package_dataset_aggregation_list_report; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_dataset_aggregation_list_report TO readaccess;
GRANT SELECT ON TABLE dpkg.v_data_package_dataset_aggregation_list_report TO writeaccess;

