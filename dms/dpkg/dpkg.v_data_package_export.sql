--
-- Name: v_data_package_export; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_export AS
 SELECT dp.data_pkg_id,
    dp.package_name AS name,
    dp.description,
    dp.owner_username AS owner,
    dp.path_team AS team,
    dp.state,
    dp.package_type,
    dp.requester,
    dp.total_item_count AS total,
    dp.analysis_job_item_count AS jobs,
    dp.dataset_item_count AS datasets,
    dp.experiment_item_count AS experiments,
    dp.biomaterial_item_count AS biomaterial,
    dp.last_modified,
    dp.created,
    dp.package_folder AS package_file_folder,
    dpp.storage_path_relative,
    dpp.share_path,
    dpp.archive_path,
    dpp.local_path,
    dp.instrument,
    dp.eus_person_id,
    dp.eus_proposal_id,
    dp.eus_instrument_id,
    COALESCE(uploadq.myemsl_uploads, (0)::bigint) AS myemsl_uploads,
    dp.data_pkg_id AS id
   FROM ((dpkg.t_data_package dp
     JOIN dpkg.v_data_package_paths dpp ON ((dp.data_pkg_id = dpp.data_pkg_id)))
     LEFT JOIN ( SELECT t_myemsl_uploads.data_pkg_id,
            count(t_myemsl_uploads.entry_id) AS myemsl_uploads
           FROM dpkg.t_myemsl_uploads
          WHERE ((t_myemsl_uploads.error_code = 0) AND (t_myemsl_uploads.status_num > 1) AND ((t_myemsl_uploads.file_count_new > 0) OR (t_myemsl_uploads.file_count_updated > 0)))
          GROUP BY t_myemsl_uploads.data_pkg_id) uploadq ON ((dp.data_pkg_id = uploadq.data_pkg_id)));


ALTER TABLE dpkg.v_data_package_export OWNER TO d3l243;

--
-- Name: TABLE v_data_package_export; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_export TO readaccess;
GRANT SELECT ON TABLE dpkg.v_data_package_export TO writeaccess;

