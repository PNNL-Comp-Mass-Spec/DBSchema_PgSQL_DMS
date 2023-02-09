--
-- Name: v_eus_export_data_package_metadata; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_export_data_package_metadata AS
 SELECT v_data_package_export.id,
    v_data_package_export.name,
    v_data_package_export.description,
    v_data_package_export.owner AS owner_username,
    v_data_package_export.team,
    v_data_package_export.state,
    v_data_package_export.package_type,
    v_data_package_export.total AS total_items,
    v_data_package_export.jobs,
    v_data_package_export.datasets,
    v_data_package_export.experiments,
    v_data_package_export.biomaterial,
    v_data_package_export.last_modified,
    v_data_package_export.created,
    v_data_package_export.package_file_folder,
    v_data_package_export.storage_path_relative,
    v_data_package_export.share_path,
    v_data_package_export.archive_path
   FROM dpkg.v_data_package_export;


ALTER TABLE public.v_eus_export_data_package_metadata OWNER TO d3l243;

--
-- Name: TABLE v_eus_export_data_package_metadata; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_export_data_package_metadata TO readaccess;
GRANT SELECT ON TABLE public.v_eus_export_data_package_metadata TO writeaccess;

