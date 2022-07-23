--
-- Name: v_mage_data_package_list; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mage_data_package_list AS
 SELECT v_data_package_export.id,
    v_data_package_export.name AS package,
    v_data_package_export.description,
    v_data_package_export.owner,
    v_data_package_export.team,
    v_data_package_export.state,
    v_data_package_export.package_type,
    v_data_package_export.last_modified,
    v_data_package_export.created,
    v_data_package_export.share_path AS folder,
    ''::text AS archive_path
   FROM dpkg.v_data_package_export;


ALTER TABLE public.v_mage_data_package_list OWNER TO d3l243;

--
-- Name: TABLE v_mage_data_package_list; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mage_data_package_list TO readaccess;

