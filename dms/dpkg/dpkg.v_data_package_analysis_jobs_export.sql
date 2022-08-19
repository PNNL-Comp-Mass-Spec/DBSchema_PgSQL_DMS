--
-- Name: v_data_package_analysis_jobs_export; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_analysis_jobs_export AS
 SELECT t_data_package_analysis_jobs.data_pkg_id AS data_package_id,
    t_data_package_analysis_jobs.job,
    t_data_package_analysis_jobs.dataset,
    t_data_package_analysis_jobs.tool,
    t_data_package_analysis_jobs.package_comment,
    t_data_package_analysis_jobs.item_added
   FROM dpkg.t_data_package_analysis_jobs;


ALTER TABLE dpkg.v_data_package_analysis_jobs_export OWNER TO d3l243;

--
-- Name: TABLE v_data_package_analysis_jobs_export; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_analysis_jobs_export TO readaccess;

