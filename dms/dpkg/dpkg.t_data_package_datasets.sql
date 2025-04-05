--
-- Name: t_data_package_datasets; Type: TABLE; Schema: dpkg; Owner: d3l243
--

CREATE TABLE dpkg.t_data_package_datasets (
    data_pkg_id integer NOT NULL,
    dataset_id integer NOT NULL,
    dataset public.citext,
    item_added timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    package_comment public.citext DEFAULT ''::public.citext
);


ALTER TABLE dpkg.t_data_package_datasets OWNER TO d3l243;

--
-- Name: t_data_package_datasets pk_t_data_package_datasets; Type: CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_data_package_datasets
    ADD CONSTRAINT pk_t_data_package_datasets PRIMARY KEY (data_pkg_id, dataset_id);

ALTER TABLE dpkg.t_data_package_datasets CLUSTER ON pk_t_data_package_datasets;

--
-- Name: ix_t_data_package_datasets_dataset; Type: INDEX; Schema: dpkg; Owner: d3l243
--

CREATE INDEX ix_t_data_package_datasets_dataset ON dpkg.t_data_package_datasets USING btree (dataset);

--
-- Name: ix_t_data_package_datasets_dataset_lower_text_pattern_ops; Type: INDEX; Schema: dpkg; Owner: d3l243
--

CREATE INDEX ix_t_data_package_datasets_dataset_lower_text_pattern_ops ON dpkg.t_data_package_datasets USING btree (lower((dataset)::text) text_pattern_ops);

--
-- Name: t_data_package_datasets fk_t_data_package_datasets_t_data_package; Type: FK CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_data_package_datasets
    ADD CONSTRAINT fk_t_data_package_datasets_t_data_package FOREIGN KEY (data_pkg_id) REFERENCES dpkg.t_data_package(data_pkg_id) ON DELETE CASCADE;

--
-- Name: TABLE t_data_package_datasets; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.t_data_package_datasets TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE dpkg.t_data_package_datasets TO writeaccess;

