--
-- Name: v_eus_export_data_package_metadata; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_export_data_package_metadata AS
 SELECT data_pkg_id,
    name,
    description,
    owner AS owner_username,
    team,
    state,
    package_type,
    total AS total_items,
    jobs,
    datasets,
    experiments,
    biomaterial,
    last_modified,
    created,
    package_file_folder,
    storage_path_relative,
    share_path,
    archive_path,
    data_pkg_id AS id
   FROM dpkg.v_data_package_export dpe;


ALTER VIEW public.v_eus_export_data_package_metadata OWNER TO d3l243;

--
-- Name: TABLE v_eus_export_data_package_metadata; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_export_data_package_metadata TO readaccess;
GRANT SELECT ON TABLE public.v_eus_export_data_package_metadata TO writeaccess;

