--
-- Name: t_local_processor_job_step_exclusion; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_local_processor_job_step_exclusion (
    id integer NOT NULL,
    step integer NOT NULL
);


ALTER TABLE sw.t_local_processor_job_step_exclusion OWNER TO d3l243;

--
-- Name: t_local_processor_job_step_exclusion pk_t_local_processor_job_step_exclusion; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_local_processor_job_step_exclusion
    ADD CONSTRAINT pk_t_local_processor_job_step_exclusion PRIMARY KEY (id, step);

--
-- Name: TABLE t_local_processor_job_step_exclusion; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.t_local_processor_job_step_exclusion TO readaccess;

