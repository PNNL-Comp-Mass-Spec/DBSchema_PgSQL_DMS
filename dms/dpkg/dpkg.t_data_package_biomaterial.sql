--
-- Name: t_data_package_biomaterial; Type: TABLE; Schema: dpkg; Owner: d3l243
--

CREATE TABLE dpkg.t_data_package_biomaterial (
    data_pkg_id integer NOT NULL,
    biomaterial_id integer NOT NULL,
    biomaterial public.citext,
    item_added timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    package_comment public.citext DEFAULT ''::public.citext
);


ALTER TABLE dpkg.t_data_package_biomaterial OWNER TO d3l243;

--
-- Name: t_data_package_biomaterial pk_t_data_package_biomaterial; Type: CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_data_package_biomaterial
    ADD CONSTRAINT pk_t_data_package_biomaterial PRIMARY KEY (data_pkg_id, biomaterial_id);

--
-- Name: t_data_package_biomaterial fk_t_data_package_biomaterial_t_data_package; Type: FK CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_data_package_biomaterial
    ADD CONSTRAINT fk_t_data_package_biomaterial_t_data_package FOREIGN KEY (data_pkg_id) REFERENCES dpkg.t_data_package(data_pkg_id) ON DELETE CASCADE;

--
-- Name: TABLE t_data_package_biomaterial; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.t_data_package_biomaterial TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE dpkg.t_data_package_biomaterial TO writeaccess;

