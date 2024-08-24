--
-- Name: v_mage_data_package_list; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mage_data_package_list AS
 SELECT dp.data_pkg_id,
    dp.package_name AS package,
    dp.description,
    dp.owner_username AS owner,
    dp.path_team AS team,
    dp.state,
    dp.package_type,
    dp.last_modified,
    dp.created,
    dpp.share_path AS folder,
    ''::text AS archive_path,
    dp.data_pkg_id AS id
   FROM (dpkg.t_data_package dp
     JOIN dpkg.v_data_package_paths dpp ON ((dp.data_pkg_id = dpp.data_pkg_id)));


ALTER VIEW public.v_mage_data_package_list OWNER TO d3l243;

--
-- Name: TABLE v_mage_data_package_list; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mage_data_package_list TO readaccess;
GRANT SELECT ON TABLE public.v_mage_data_package_list TO writeaccess;

