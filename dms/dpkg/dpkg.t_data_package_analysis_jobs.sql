--
-- Name: t_data_package_analysis_jobs; Type: TABLE; Schema: dpkg; Owner: d3l243
--

CREATE TABLE dpkg.t_data_package_analysis_jobs (
    data_pkg_id integer NOT NULL,
    job integer NOT NULL,
    tool public.citext,
    dataset_id integer NOT NULL,
    dataset public.citext,
    created timestamp without time zone,
    item_added timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    package_comment public.citext DEFAULT ''::public.citext
);


ALTER TABLE dpkg.t_data_package_analysis_jobs OWNER TO d3l243;

--
-- Name: t_data_package_analysis_jobs pk_t_data_package_analysis_jobs; Type: CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_data_package_analysis_jobs
    ADD CONSTRAINT pk_t_data_package_analysis_jobs PRIMARY KEY (data_pkg_id, job);

--
-- Name: ix_t_data_package_analysis_jobs_dataset_id_data_pkg_id_job; Type: INDEX; Schema: dpkg; Owner: d3l243
--

CREATE INDEX ix_t_data_package_analysis_jobs_dataset_id_data_pkg_id_job ON dpkg.t_data_package_analysis_jobs USING btree (dataset_id, data_pkg_id, job);

--
-- Name: ix_t_data_package_analysis_jobs_job_include_data_pkg_id; Type: INDEX; Schema: dpkg; Owner: d3l243
--

CREATE INDEX ix_t_data_package_analysis_jobs_job_include_data_pkg_id ON dpkg.t_data_package_analysis_jobs USING btree (job) INCLUDE (data_pkg_id);

--
-- Name: t_data_package_analysis_jobs fk_t_data_package_analysis_jobs_t_data_package; Type: FK CONSTRAINT; Schema: dpkg; Owner: d3l243
--

ALTER TABLE ONLY dpkg.t_data_package_analysis_jobs
    ADD CONSTRAINT fk_t_data_package_analysis_jobs_t_data_package FOREIGN KEY (data_pkg_id) REFERENCES dpkg.t_data_package(data_pkg_id) ON DELETE CASCADE;

--
-- Name: TABLE t_data_package_analysis_jobs; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.t_data_package_analysis_jobs TO readaccess;
GRANT SELECT ON TABLE dpkg.t_data_package_analysis_jobs TO writeaccess;

