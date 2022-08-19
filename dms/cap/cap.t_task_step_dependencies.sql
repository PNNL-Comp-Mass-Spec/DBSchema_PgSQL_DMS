--
-- Name: t_task_step_dependencies; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_task_step_dependencies (
    job integer NOT NULL,
    step integer NOT NULL,
    target_step integer NOT NULL,
    condition_test public.citext,
    test_value public.citext,
    evaluated smallint DEFAULT 0 NOT NULL,
    triggered smallint DEFAULT 0 NOT NULL,
    enable_only smallint DEFAULT 0 NOT NULL
);


ALTER TABLE cap.t_task_step_dependencies OWNER TO d3l243;

--
-- Name: t_task_step_dependencies pk_t_task_step_dependencies; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_task_step_dependencies
    ADD CONSTRAINT pk_t_task_step_dependencies PRIMARY KEY (job, step, target_step);

--
-- Name: ix_t_task_step_dependencies; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_task_step_dependencies ON cap.t_task_step_dependencies USING btree (job);

--
-- Name: ix_t_task_step_dependencies_job_id_step_evaluated_triggered; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_task_step_dependencies_job_id_step_evaluated_triggered ON cap.t_task_step_dependencies USING btree (job, step) INCLUDE (evaluated, triggered);

--
-- Name: t_task_step_dependencies fk_t_task_step_dependencies_t_task_steps; Type: FK CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_task_step_dependencies
    ADD CONSTRAINT fk_t_task_step_dependencies_t_task_steps FOREIGN KEY (job, step) REFERENCES cap.t_task_steps(job, step) ON UPDATE CASCADE ON DELETE CASCADE;

--
-- Name: TABLE t_task_step_dependencies; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.t_task_step_dependencies TO readaccess;

