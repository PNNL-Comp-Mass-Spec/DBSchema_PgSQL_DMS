--
-- Name: v_data_package_analysis_jobs_export; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_analysis_jobs_export AS
 SELECT dpj.data_pkg_id,
    dpj.job,
    dpj.dataset,
    dpj.tool,
    dpj.package_comment,
    dpj.item_added,
    dpj.data_pkg_id AS data_package_id
   FROM dpkg.t_data_package_analysis_jobs dpj;


ALTER TABLE dpkg.v_data_package_analysis_jobs_export OWNER TO d3l243;

--
-- Name: TABLE v_data_package_analysis_jobs_export; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_analysis_jobs_export TO readaccess;
GRANT SELECT ON TABLE dpkg.v_data_package_analysis_jobs_export TO writeaccess;

