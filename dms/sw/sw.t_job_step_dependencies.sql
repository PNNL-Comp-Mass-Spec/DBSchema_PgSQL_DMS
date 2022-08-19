--
-- Name: t_job_step_dependencies; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_job_step_dependencies (
    job integer NOT NULL,
    step integer NOT NULL,
    target_step integer NOT NULL,
    condition_test public.citext,
    test_value public.citext,
    evaluated smallint DEFAULT 0 NOT NULL,
    triggered smallint DEFAULT 0 NOT NULL,
    enable_only smallint DEFAULT 0 NOT NULL
);


ALTER TABLE sw.t_job_step_dependencies OWNER TO d3l243;

--
-- Name: t_job_step_dependencies pk_t_job_step_dependencies; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_job_step_dependencies
    ADD CONSTRAINT pk_t_job_step_dependencies PRIMARY KEY (job, step, target_step);

--
-- Name: ix_t_job_step_dependencies; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_job_step_dependencies ON sw.t_job_step_dependencies USING btree (job);

--
-- Name: ix_t_job_step_dependencies_job_id_step_evaluated_triggered; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_job_step_dependencies_job_id_step_evaluated_triggered ON sw.t_job_step_dependencies USING btree (job, step) INCLUDE (evaluated, triggered);

--
-- Name: t_job_step_dependencies fk_t_job_step_dependencies_t_job_steps; Type: FK CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_job_step_dependencies
    ADD CONSTRAINT fk_t_job_step_dependencies_t_job_steps FOREIGN KEY (job, step) REFERENCES sw.t_job_steps(job, step) ON UPDATE CASCADE ON DELETE CASCADE;

--
-- Name: TABLE t_job_step_dependencies; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.t_job_step_dependencies TO readaccess;
GRANT SELECT ON TABLE sw.t_job_step_dependencies TO writeaccess;

