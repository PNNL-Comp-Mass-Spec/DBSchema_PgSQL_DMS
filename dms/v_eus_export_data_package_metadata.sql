--
-- Name: v_eus_export_data_package_metadata; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_export_data_package_metadata AS
 SELECT dpe.data_pkg_id,
    dpe.name,
    dpe.description,
    dpe.owner AS owner_username,
    dpe.team,
    dpe.state,
    dpe.package_type,
    dpe.total AS total_items,
    dpe.jobs,
    dpe.datasets,
    dpe.experiments,
    dpe.biomaterial,
    dpe.last_modified,
    dpe.created,
    dpe.package_file_folder,
    dpe.storage_path_relative,
    dpe.share_path,
    dpe.archive_path,
    dpe.data_pkg_id AS id
   FROM dpkg.v_data_package_export dpe;


ALTER VIEW public.v_eus_export_data_package_metadata OWNER TO d3l243;

--
-- Name: TABLE v_eus_export_data_package_metadata; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_export_data_package_metadata TO readaccess;
GRANT SELECT ON TABLE public.v_eus_export_data_package_metadata TO writeaccess;

