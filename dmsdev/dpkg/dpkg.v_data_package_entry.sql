--
-- Name: v_data_package_entry; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_entry AS
 SELECT data_pkg_id AS id,
    package_name AS name,
    package_type,
    description,
    comment,
    owner_username AS owner,
    requester,
    state,
    path_team AS team,
    mass_tag_database,
    wiki_page_link AS prismwiki_link,
    data_doi,
    manuscript_doi,
    ''::text AS creation_params
   FROM dpkg.t_data_package;


ALTER VIEW dpkg.v_data_package_entry OWNER TO d3l243;

--
-- Name: TABLE v_data_package_entry; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_entry TO readaccess;
GRANT SELECT ON TABLE dpkg.v_data_package_entry TO writeaccess;

