--
-- Name: t_job_parameters; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_job_parameters (
    job integer NOT NULL,
    parameters xml
);


ALTER TABLE sw.t_job_parameters OWNER TO d3l243;

--
-- Name: t_job_parameters pk_t_job_parameters; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_job_parameters
    ADD CONSTRAINT pk_t_job_parameters PRIMARY KEY (job);

--
-- Name: t_job_parameters fk_t_job_parameters_t_jobs; Type: FK CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_job_parameters
    ADD CONSTRAINT fk_t_job_parameters_t_jobs FOREIGN KEY (job) REFERENCES sw.t_jobs(job) ON DELETE CASCADE;

--
-- Name: TABLE t_job_parameters; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.t_job_parameters TO readaccess;

