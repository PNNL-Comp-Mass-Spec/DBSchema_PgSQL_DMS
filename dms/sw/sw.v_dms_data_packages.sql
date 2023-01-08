--
-- Name: v_dms_data_packages; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_dms_data_packages AS
 SELECT dp.data_pkg_id AS id,
    dp.package_name AS name,
    dp.package_type,
    dp.description,
    dp.comment,
    COALESCE(u1.name, dp.owner) AS owner,
    COALESCE(u2.name, dp.requester) AS requester,
    dp.path_team AS team,
    dp.created,
    dp.last_modified,
    dp.state,
    dp.package_directory AS package_file_folder,
    dpp.share_path,
    dpp.web_path,
    dp.mass_tag_database AS amt_tag_database,
    dp.biomaterial_item_count AS biomaterial_count,
    dp.experiment_item_count AS experiment_count,
    dp.eus_proposal_item_count AS eus_proposal_count,
    dp.dataset_item_count AS dataset_count,
    dp.analysis_job_item_count AS analysis_job_count,
    dp.total_item_count,
    dp.wiki_page_link AS prism_wiki
   FROM (((dpkg.t_data_package dp
     JOIN dpkg.v_data_package_paths dpp ON ((dp.data_pkg_id = dpp.id)))
     LEFT JOIN public.t_users u1 ON ((dp.owner OPERATOR(public.=) u1.username)))
     LEFT JOIN public.t_users u2 ON ((dp.requester OPERATOR(public.=) u2.username)));


ALTER TABLE sw.v_dms_data_packages OWNER TO d3l243;

--
-- Name: TABLE v_dms_data_packages; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_dms_data_packages TO readaccess;
GRANT SELECT ON TABLE sw.v_dms_data_packages TO writeaccess;

