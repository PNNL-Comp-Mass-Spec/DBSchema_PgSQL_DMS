--
-- Name: v_data_package_detail_report; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_detail_report AS
 SELECT dp.data_pkg_id AS id,
    dp.package_name,
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
    dpkg.get_myemsl_url_data_package_id(dp.data_pkg_id) AS myemsl_url,
    dp.mass_tag_database AS amt_tag_database,
    dp.biomaterial_item_count,
    dp.experiment_item_count,
    dp.eus_proposal_item_count AS eus_proposals_count,
    dp.dataset_item_count,
    dp.analysis_job_item_count,
    campaignstats.campaigns AS campaign_count,
    dp.total_item_count,
    dp.wiki_page_link AS prism_wiki,
    dp.data_doi,
    dp.manuscript_doi,
    dp.eus_person_id AS eus_user_id,
    dp.eus_proposal_id
   FROM ((((dpkg.t_data_package dp
     JOIN dpkg.v_data_package_paths dpp ON ((dp.data_pkg_id = dpp.id)))
     LEFT JOIN public.t_users u1 ON ((dp.owner OPERATOR(public.=) u1.username)))
     LEFT JOIN public.t_users u2 ON ((dp.requester OPERATOR(public.=) u2.username)))
     LEFT JOIN ( SELECT v_data_package_campaigns_list_report.id,
            count(*) AS campaigns
           FROM dpkg.v_data_package_campaigns_list_report
          GROUP BY v_data_package_campaigns_list_report.id) campaignstats ON ((dp.data_pkg_id = campaignstats.id)));


ALTER TABLE dpkg.v_data_package_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_data_package_detail_report; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_detail_report TO readaccess;

