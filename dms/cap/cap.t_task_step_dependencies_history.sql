--
-- Name: t_task_step_dependencies_history; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_task_step_dependencies_history (
    job integer NOT NULL,
    step integer NOT NULL,
    target_step integer NOT NULL,
    condition_test public.citext,
    test_value public.citext,
    evaluated smallint DEFAULT 0 NOT NULL,
    triggered smallint DEFAULT 0 NOT NULL,
    enable_only smallint DEFAULT 0 NOT NULL,
    saved timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    initial_save timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE cap.t_task_step_dependencies_history OWNER TO d3l243;

--
-- Name: t_task_step_dependencies_history pk_t_task_step_dependencies_history; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_task_step_dependencies_history
    ADD CONSTRAINT pk_t_task_step_dependencies_history PRIMARY KEY (job, step, target_step);

--
-- Name: ix_t_job_step_dep_history_job_step_evaluated_triggered; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_job_step_dep_history_job_step_evaluated_triggered ON cap.t_task_step_dependencies_history USING btree (job, step) INCLUDE (evaluated, triggered);

--
-- Name: ix_t_task_step_dependencies_history; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_task_step_dependencies_history ON cap.t_task_step_dependencies_history USING btree (job);

--
-- Name: TABLE t_task_step_dependencies_history; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.t_task_step_dependencies_history TO readaccess;
GRANT SELECT ON TABLE cap.t_task_step_dependencies_history TO writeaccess;

