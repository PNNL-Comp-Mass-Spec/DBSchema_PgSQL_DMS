--
-- Name: v_data_package_teams_picklist; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_teams_picklist AS
 SELECT team_name,
    description
   FROM dpkg.t_data_package_teams;


ALTER VIEW dpkg.v_data_package_teams_picklist OWNER TO d3l243;

--
-- Name: TABLE v_data_package_teams_picklist; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_teams_picklist TO readaccess;
GRANT SELECT ON TABLE dpkg.v_data_package_teams_picklist TO writeaccess;

