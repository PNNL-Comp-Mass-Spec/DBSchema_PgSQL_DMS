--
-- Name: t_job_step_dependencies_history; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_job_step_dependencies_history (
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


ALTER TABLE sw.t_job_step_dependencies_history OWNER TO d3l243;

--
-- Name: t_job_step_dependencies_history pk_t_job_step_dependencies_history; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_job_step_dependencies_history
    ADD CONSTRAINT pk_t_job_step_dependencies_history PRIMARY KEY (job, step, target_step);

--
-- Name: ix_t_job_step_dependencies_history; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_job_step_dependencies_history ON sw.t_job_step_dependencies_history USING btree (job);

--
-- Name: ix_t_job_step_dependencies_history_job_step_eval_triggered; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_job_step_dependencies_history_job_step_eval_triggered ON sw.t_job_step_dependencies_history USING btree (job, step) INCLUDE (evaluated, triggered);

--
-- Name: TABLE t_job_step_dependencies_history; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.t_job_step_dependencies_history TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE sw.t_job_step_dependencies_history TO writeaccess;

