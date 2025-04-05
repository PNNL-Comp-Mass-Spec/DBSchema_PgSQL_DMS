--
-- Name: t_data_repository_data_packages; Type: TABLE; Schema: dpkg; Owner: d3l243
--

CREATE TABLE dpkg.t_data_repository_data_packages (
    upload_id integer NOT NULL,
    data_pkg_id integer NOT NULL
);


ALTER TABLE dpkg.t_data_repository_data_packages OWNER TO d3l243;

--
-- Name: t_data_repository_data_packages pk_t_data_repository_data_packages; Type: CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_data_repository_data_packages
    ADD CONSTRAINT pk_t_data_repository_data_packages PRIMARY KEY (upload_id, data_pkg_id);

ALTER TABLE dpkg.t_data_repository_data_packages CLUSTER ON pk_t_data_repository_data_packages;

--
-- Name: t_data_repository_data_packages fk_t_data_repository_data_packages_t_data_package; Type: FK CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_data_repository_data_packages
    ADD CONSTRAINT fk_t_data_repository_data_packages_t_data_package FOREIGN KEY (data_pkg_id) REFERENCES dpkg.t_data_package(data_pkg_id);

--
-- Name: t_data_repository_data_packages fk_t_data_repository_data_packages_t_data_repository_uploads; Type: FK CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_data_repository_data_packages
    ADD CONSTRAINT fk_t_data_repository_data_packages_t_data_repository_uploads FOREIGN KEY (upload_id) REFERENCES dpkg.t_data_repository_uploads(upload_id);

--
-- Name: TABLE t_data_repository_data_packages; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.t_data_repository_data_packages TO readaccess;
GRANT SELECT ON TABLE dpkg.t_data_repository_data_packages TO writeaccess;

