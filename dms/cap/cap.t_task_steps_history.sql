--
-- Name: t_task_steps_history; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_task_steps_history (
    job integer NOT NULL,
    step integer NOT NULL,
    priority integer,
    tool public.citext NOT NULL,
    shared_result_version smallint,
    signature integer,
    state smallint,
    input_folder_name public.citext,
    output_folder_name public.citext,
    processor public.citext,
    start timestamp without time zone,
    finish timestamp without time zone,
    completion_code integer,
    completion_message public.citext,
    evaluation_code integer,
    evaluation_message public.citext,
    saved timestamp without time zone NOT NULL,
    tool_version_id integer,
    most_recent_entry smallint DEFAULT 0 NOT NULL
);


ALTER TABLE cap.t_task_steps_history OWNER TO d3l243;

--
-- Name: t_task_steps_history pk_t_task_steps_history; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_task_steps_history
    ADD CONSTRAINT pk_t_task_steps_history PRIMARY KEY (job, step, saved);

ALTER TABLE cap.t_task_steps_history CLUSTER ON pk_t_task_steps_history;

--
-- Name: ix_t_task_steps_history_job_step; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_task_steps_history_job_step ON cap.t_task_steps_history USING btree (job, step);

--
-- Name: ix_t_task_steps_history_most_recent_entry; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_task_steps_history_most_recent_entry ON cap.t_task_steps_history USING btree (most_recent_entry);

--
-- Name: ix_t_task_steps_history_state; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_task_steps_history_state ON cap.t_task_steps_history USING btree (state);

--
-- Name: ix_t_task_steps_history_state_output_folder_name; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_task_steps_history_state_output_folder_name ON cap.t_task_steps_history USING btree (state, output_folder_name);

--
-- Name: t_task_steps_history trig_t_task_steps_history_after_delete; Type: TRIGGER; Schema: cap; Owner: d3l243
--

CREATE TRIGGER trig_t_task_steps_history_after_delete AFTER DELETE ON cap.t_task_steps_history REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION cap.trigfn_t_task_steps_history_after_delete();

--
-- Name: t_task_steps_history trig_t_task_steps_history_after_insert; Type: TRIGGER; Schema: cap; Owner: d3l243
--

CREATE TRIGGER trig_t_task_steps_history_after_insert AFTER INSERT ON cap.t_task_steps_history REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION cap.trigfn_t_task_steps_history_after_insert();

--
-- Name: t_task_steps_history trig_t_task_steps_history_after_update; Type: TRIGGER; Schema: cap; Owner: d3l243
--

CREATE TRIGGER trig_t_task_steps_history_after_update AFTER UPDATE ON cap.t_task_steps_history FOR EACH ROW WHEN ((old.saved <> new.saved)) EXECUTE FUNCTION cap.trigfn_t_task_steps_history_after_update();

--
-- Name: TABLE t_task_steps_history; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.t_task_steps_history TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE cap.t_task_steps_history TO writeaccess;

