--
-- Name: t_data_package_experiments; Type: TABLE; Schema: dpkg; Owner: d3l243
--

CREATE TABLE dpkg.t_data_package_experiments (
    data_pkg_id integer NOT NULL,
    experiment_id integer NOT NULL,
    experiment public.citext,
    item_added timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    package_comment public.citext DEFAULT ''::public.citext
);


ALTER TABLE dpkg.t_data_package_experiments OWNER TO d3l243;

--
-- Name: t_data_package_experiments pk_t_data_package_experiments; Type: CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_data_package_experiments
    ADD CONSTRAINT pk_t_data_package_experiments PRIMARY KEY (data_pkg_id, experiment_id);

--
-- Name: t_data_package_experiments fk_t_data_package_experiments_t_data_package; Type: FK CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_data_package_experiments
    ADD CONSTRAINT fk_t_data_package_experiments_t_data_package FOREIGN KEY (data_pkg_id) REFERENCES dpkg.t_data_package(data_pkg_id) ON DELETE CASCADE;

--
-- Name: TABLE t_data_package_experiments; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.t_data_package_experiments TO readaccess;
GRANT SELECT ON TABLE dpkg.t_data_package_experiments TO writeaccess;

