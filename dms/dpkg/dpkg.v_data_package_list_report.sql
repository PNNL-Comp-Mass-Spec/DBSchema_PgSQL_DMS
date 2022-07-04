--
-- Name: v_data_package_list_report; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_list_report AS
 SELECT dp.data_pkg_id AS id,
    dp.package_name,
    dp.description,
    COALESCE(ownerinfo.name, dp.owner) AS owner,
    dp.path_team AS team,
    dp.state,
    dp.package_type,
    COALESCE(requesterinfo.name, dp.requester) AS requester,
    dp.total_item_count AS total,
    dp.analysis_job_item_count AS jobs,
    dp.dataset_item_count AS datasets,
    dp.eus_proposal_item_count AS proposals,
    dp.experiment_item_count AS experiments,
    dp.biomaterial_item_count AS biomaterial,
    dp.last_modified,
    dp.created,
    dp.data_doi,
    dp.manuscript_doi
   FROM ((dpkg.t_data_package dp
     LEFT JOIN public.t_users ownerinfo ON ((dp.owner OPERATOR(public.=) ownerinfo.username)))
     LEFT JOIN public.t_users requesterinfo ON ((dp.requester OPERATOR(public.=) requesterinfo.username)));


ALTER TABLE dpkg.v_data_package_list_report OWNER TO d3l243;

