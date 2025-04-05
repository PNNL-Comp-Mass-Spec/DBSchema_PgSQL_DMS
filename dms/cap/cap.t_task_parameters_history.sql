--
-- Name: t_task_parameters_history; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_task_parameters_history (
    job integer NOT NULL,
    parameters xml,
    saved timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    most_recent_entry smallint DEFAULT 0 NOT NULL
);


ALTER TABLE cap.t_task_parameters_history OWNER TO d3l243;

--
-- Name: t_task_parameters_history pk_t_task_parameters_history; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_task_parameters_history
    ADD CONSTRAINT pk_t_task_parameters_history PRIMARY KEY (job, saved);

ALTER TABLE cap.t_task_parameters_history CLUSTER ON pk_t_task_parameters_history;

--
-- Name: ix_t_task_parameters_history_most_recent_entry; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_task_parameters_history_most_recent_entry ON cap.t_task_parameters_history USING btree (most_recent_entry);

--
-- Name: t_task_parameters_history trig_t_task_parameters_history_after_delete; Type: TRIGGER; Schema: cap; Owner: d3l243
--

CREATE TRIGGER trig_t_task_parameters_history_after_delete AFTER DELETE ON cap.t_task_parameters_history REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION cap.trigfn_t_task_parameters_history_after_delete();

--
-- Name: t_task_parameters_history trig_t_task_parameters_history_after_insert; Type: TRIGGER; Schema: cap; Owner: d3l243
--

CREATE TRIGGER trig_t_task_parameters_history_after_insert AFTER INSERT ON cap.t_task_parameters_history REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION cap.trigfn_t_task_parameters_history_after_insert();

--
-- Name: t_task_parameters_history trig_t_task_parameters_history_after_update; Type: TRIGGER; Schema: cap; Owner: d3l243
--

CREATE TRIGGER trig_t_task_parameters_history_after_update AFTER UPDATE ON cap.t_task_parameters_history FOR EACH ROW WHEN ((old.saved <> new.saved)) EXECUTE FUNCTION cap.trigfn_t_task_parameters_history_after_update();

--
-- Name: TABLE t_task_parameters_history; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.t_task_parameters_history TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE cap.t_task_parameters_history TO writeaccess;

