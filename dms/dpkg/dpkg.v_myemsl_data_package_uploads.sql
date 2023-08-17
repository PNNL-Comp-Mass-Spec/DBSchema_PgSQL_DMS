--
-- Name: v_myemsl_data_package_uploads; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_myemsl_data_package_uploads AS
 SELECT mu.entry_id,
    mu.data_pkg_id,
    mu.subfolder,
    mu.file_count_new,
    mu.file_count_updated,
    round((((mu.bytes)::numeric / 1024.0) / 1024.0), 3) AS mb,
    round((mu.upload_time_seconds)::numeric, 1) AS upload_time_seconds,
    mu.status_uri_path_id,
    mu.status_num,
    mu.error_code,
    (((p.uri_path)::text || (mu.status_num)::text) ||
        CASE
            WHEN (p.uri_path OPERATOR(public.~~) '%/status/%'::public.citext) THEN '/xml'::text
            ELSE ''::text
        END) AS status_uri,
    mu.available,
    mu.verified,
    mu.entered,
    mu.data_pkg_id AS data_package_id
   FROM (dpkg.t_myemsl_uploads mu
     LEFT JOIN dpkg.t_uri_paths p ON ((mu.status_uri_path_id = p.uri_path_id)));


ALTER TABLE dpkg.v_myemsl_data_package_uploads OWNER TO d3l243;

--
-- Name: VIEW v_myemsl_data_package_uploads; Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON VIEW dpkg.v_myemsl_data_package_uploads IS 'This view is used by clsDataPackageArchiver in the DataPackage Archive Manager';

--
-- Name: TABLE v_myemsl_data_package_uploads; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_myemsl_data_package_uploads TO readaccess;
GRANT SELECT ON TABLE dpkg.v_myemsl_data_package_uploads TO writeaccess;

