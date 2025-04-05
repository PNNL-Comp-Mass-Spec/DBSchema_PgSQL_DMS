--
-- Name: t_local_job_processors; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_local_job_processors (
    job integer NOT NULL,
    processor public.citext NOT NULL,
    general_processing integer NOT NULL
);


ALTER TABLE sw.t_local_job_processors OWNER TO d3l243;

--
-- Name: t_local_job_processors pk_t_local_job_processors; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_local_job_processors
    ADD CONSTRAINT pk_t_local_job_processors PRIMARY KEY (job, processor);

ALTER TABLE sw.t_local_job_processors CLUSTER ON pk_t_local_job_processors;

--
-- Name: ix_t_local_job_processors_job; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_local_job_processors_job ON sw.t_local_job_processors USING btree (job);

--
-- Name: TABLE t_local_job_processors; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.t_local_job_processors TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE sw.t_local_job_processors TO writeaccess;

