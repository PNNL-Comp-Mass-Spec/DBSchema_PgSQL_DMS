--
-- Name: v_data_package_type_picklist; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_type_picklist AS
 SELECT package_type AS name,
    description
   FROM dpkg.t_data_package_type;


ALTER VIEW dpkg.v_data_package_type_picklist OWNER TO d3l243;

--
-- Name: TABLE v_data_package_type_picklist; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_type_picklist TO readaccess;
GRANT SELECT ON TABLE dpkg.v_data_package_type_picklist TO writeaccess;

