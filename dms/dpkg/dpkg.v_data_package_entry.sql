--
-- Name: v_data_package_entry; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_entry AS
 SELECT t_data_package.data_pkg_id AS id,
    t_data_package.package_name AS name,
    t_data_package.package_type,
    t_data_package.description,
    t_data_package.comment,
    t_data_package.owner_username AS owner,
    t_data_package.requester,
    t_data_package.state,
    t_data_package.path_team AS team,
    t_data_package.mass_tag_database,
    t_data_package.wiki_page_link AS prismwiki_link,
    t_data_package.data_doi,
    t_data_package.manuscript_doi,
    ''::text AS creation_params
   FROM dpkg.t_data_package;


ALTER VIEW dpkg.v_data_package_entry OWNER TO d3l243;

--
-- Name: TABLE v_data_package_entry; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_entry TO readaccess;
GRANT SELECT ON TABLE dpkg.v_data_package_entry TO writeaccess;

