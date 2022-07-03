--
-- Name: v_data_package_dataset_aggregation_list_report; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_dataset_aggregation_list_report AS
 SELECT t_data_package_analysis_jobs.data_pkg_id AS id,
    t_data_package_analysis_jobs.dataset,
    count(*) AS jobs
   FROM dpkg.t_data_package_analysis_jobs
  GROUP BY t_data_package_analysis_jobs.dataset, t_data_package_analysis_jobs.data_pkg_id;


ALTER TABLE dpkg.v_data_package_dataset_aggregation_list_report OWNER TO d3l243;

