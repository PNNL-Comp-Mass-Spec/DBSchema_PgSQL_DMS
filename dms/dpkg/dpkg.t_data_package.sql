--
-- Name: t_data_package; Type: TABLE; Schema: dpkg; Owner: d3l243
--

CREATE TABLE dpkg.t_data_package (
    data_pkg_id integer NOT NULL,
    package_name public.citext NOT NULL,
    package_type public.citext DEFAULT 'General'::public.citext NOT NULL,
    description public.citext DEFAULT ''::public.citext,
    comment public.citext DEFAULT ''::public.citext,
    owner_username public.citext,
    requester public.citext,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_modified timestamp without time zone,
    state public.citext DEFAULT 'Active'::public.citext NOT NULL,
    package_folder public.citext NOT NULL,
    storage_path_id integer,
    path_year public.citext DEFAULT EXTRACT(year FROM CURRENT_TIMESTAMP) NOT NULL,
    path_team public.citext DEFAULT 'General'::public.citext NOT NULL,
    biomaterial_item_count integer DEFAULT 0 NOT NULL,
    experiment_item_count integer DEFAULT 0 NOT NULL,
    eus_proposal_item_count integer DEFAULT 0 NOT NULL,
    dataset_item_count integer DEFAULT 0 NOT NULL,
    analysis_job_item_count integer DEFAULT 0 NOT NULL,
    total_item_count integer DEFAULT 0 NOT NULL,
    mass_tag_database public.citext,
    wiki_page_link public.citext,
    instrument public.citext,
    eus_person_id integer,
    eus_proposal_id public.citext,
    eus_instrument_id integer,
    data_doi public.citext,
    manuscript_doi public.citext
);


ALTER TABLE dpkg.t_data_package OWNER TO d3l243;

--
-- Name: t_data_package_data_pkg_id_seq; Type: SEQUENCE; Schema: dpkg; Owner: d3l243
--

ALTER TABLE dpkg.t_data_package ALTER COLUMN data_pkg_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME dpkg.t_data_package_data_pkg_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_data_package pk_t_data_package; Type: CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_data_package
    ADD CONSTRAINT pk_t_data_package PRIMARY KEY (data_pkg_id);

--
-- Name: ix_t_data_package_package_folder; Type: INDEX; Schema: dpkg; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_data_package_package_folder ON dpkg.t_data_package USING btree (package_folder);

--
-- Name: ix_t_data_package_package_name; Type: INDEX; Schema: dpkg; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_data_package_package_name ON dpkg.t_data_package USING btree (package_name);

--
-- Name: ix_t_data_package_state_include_id; Type: INDEX; Schema: dpkg; Owner: d3l243
--

CREATE INDEX ix_t_data_package_state_include_id ON dpkg.t_data_package USING btree (state) INCLUDE (data_pkg_id);

--
-- Name: t_data_package fk_t_data_package_t_data_package_state; Type: FK CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_data_package
    ADD CONSTRAINT fk_t_data_package_t_data_package_state FOREIGN KEY (state) REFERENCES dpkg.t_data_package_state(state_name);

--
-- Name: t_data_package fk_t_data_package_t_data_package_storage; Type: FK CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_data_package
    ADD CONSTRAINT fk_t_data_package_t_data_package_storage FOREIGN KEY (storage_path_id) REFERENCES dpkg.t_data_package_storage(path_id);

--
-- Name: t_data_package fk_t_data_package_t_data_package_teams; Type: FK CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_data_package
    ADD CONSTRAINT fk_t_data_package_t_data_package_teams FOREIGN KEY (path_team) REFERENCES dpkg.t_data_package_teams(team_name);

--
-- Name: t_data_package fk_t_data_package_t_data_package_type; Type: FK CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_data_package
    ADD CONSTRAINT fk_t_data_package_t_data_package_type FOREIGN KEY (package_type) REFERENCES dpkg.t_data_package_type(package_type) ON UPDATE CASCADE;

--
-- Name: TABLE t_data_package; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.t_data_package TO readaccess;
GRANT SELECT ON TABLE dpkg.t_data_package TO writeaccess;

