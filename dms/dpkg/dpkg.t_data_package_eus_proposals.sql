--
-- Name: t_data_package_eus_proposals; Type: TABLE; Schema: dpkg; Owner: d3l243
--

CREATE TABLE dpkg.t_data_package_eus_proposals (
    data_pkg_id integer NOT NULL,
    proposal_id public.citext NOT NULL,
    item_added timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    package_comment public.citext DEFAULT ''::public.citext
);


ALTER TABLE dpkg.t_data_package_eus_proposals OWNER TO d3l243;

--
-- Name: t_data_package_eus_proposals pk_t_data_package_eus_proposals; Type: CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_data_package_eus_proposals
    ADD CONSTRAINT pk_t_data_package_eus_proposals PRIMARY KEY (data_pkg_id, proposal_id);

--
-- Name: t_data_package_eus_proposals fk_t_data_package_eus_proposals_t_data_package; Type: FK CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_data_package_eus_proposals
    ADD CONSTRAINT fk_t_data_package_eus_proposals_t_data_package FOREIGN KEY (data_pkg_id) REFERENCES dpkg.t_data_package(data_pkg_id) ON DELETE CASCADE;

--
-- Name: TABLE t_data_package_eus_proposals; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.t_data_package_eus_proposals TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE dpkg.t_data_package_eus_proposals TO writeaccess;

