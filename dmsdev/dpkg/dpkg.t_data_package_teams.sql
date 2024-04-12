--
-- Name: t_data_package_teams; Type: TABLE; Schema: dpkg; Owner: d3l243
--

CREATE TABLE dpkg.t_data_package_teams (
    team_name public.citext NOT NULL,
    description public.citext
);


ALTER TABLE dpkg.t_data_package_teams OWNER TO d3l243;

--
-- Name: t_data_package_teams pk_t_data_package_teams_team_name; Type: CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_data_package_teams
    ADD CONSTRAINT pk_t_data_package_teams_team_name PRIMARY KEY (team_name);

--
-- Name: TABLE t_data_package_teams; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.t_data_package_teams TO readaccess;
GRANT SELECT ON TABLE dpkg.t_data_package_teams TO writeaccess;

