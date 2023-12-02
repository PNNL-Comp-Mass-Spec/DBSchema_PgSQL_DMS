--
-- Name: v_mage_data_package_list; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mage_data_package_list AS
 SELECT dpe.data_pkg_id,
    dpe.name AS package,
    dpe.description,
    dpe.owner,
    dpe.team,
    dpe.state,
    dpe.package_type,
    dpe.last_modified,
    dpe.created,
    dpe.share_path AS folder,
    ''::text AS archive_path,
    dpe.data_pkg_id AS id
   FROM dpkg.v_data_package_export dpe;


ALTER VIEW public.v_mage_data_package_list OWNER TO d3l243;

--
-- Name: TABLE v_mage_data_package_list; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mage_data_package_list TO readaccess;
GRANT SELECT ON TABLE public.v_mage_data_package_list TO writeaccess;

