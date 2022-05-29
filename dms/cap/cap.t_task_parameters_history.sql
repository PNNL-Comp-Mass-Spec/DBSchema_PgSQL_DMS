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

--
-- Name: ix_t_task_parameters_history_most_recent_entry; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_task_parameters_history_most_recent_entry ON cap.t_task_parameters_history USING btree (most_recent_entry);

