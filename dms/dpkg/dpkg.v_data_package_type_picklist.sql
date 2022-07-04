--
-- Name: v_data_package_type_picklist; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_type_picklist AS
 SELECT t_data_package_type.package_type,
    t_data_package_type.description
   FROM dpkg.t_data_package_type;


ALTER TABLE dpkg.v_data_package_type_picklist OWNER TO d3l243;

