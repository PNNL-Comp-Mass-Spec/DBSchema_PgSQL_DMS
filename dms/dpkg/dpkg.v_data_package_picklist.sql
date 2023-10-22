--
-- Name: v_data_package_picklist; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_picklist AS
 SELECT (((((((t_data_package.data_pkg_id)::public.citext)::text || chr(32)))::public.citext)::text || (t_data_package.package_name)::text))::public.citext AS label,
    t_data_package.data_pkg_id AS value
   FROM dpkg.t_data_package;


ALTER TABLE dpkg.v_data_package_picklist OWNER TO d3l243;

--
-- Name: VIEW v_data_package_picklist; Type: COMMENT; Schema: dpkg; Owner: d3l243
--

COMMENT ON VIEW dpkg.v_data_package_picklist IS 'Used by ad-hoc query "data_package_list"; see https://dmsdev.pnl.gov/config_db/edit_table/ad_hoc_query.db/utility_queries';

--
-- Name: TABLE v_data_package_picklist; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_picklist TO readaccess;
GRANT SELECT ON TABLE dpkg.v_data_package_picklist TO writeaccess;

