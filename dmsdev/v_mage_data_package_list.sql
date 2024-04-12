--
-- Name: v_mage_data_package_list; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mage_data_package_list AS
 SELECT data_pkg_id,
    name AS package,
    description,
    owner,
    team,
    state,
    package_type,
    last_modified,
    created,
    share_path AS folder,
    ''::text AS archive_path,
    data_pkg_id AS id
   FROM dpkg.v_data_package_export dpe;


ALTER VIEW public.v_mage_data_package_list OWNER TO d3l243;

--
-- Name: TABLE v_mage_data_package_list; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mage_data_package_list TO readaccess;
GRANT SELECT ON TABLE public.v_mage_data_package_list TO writeaccess;

