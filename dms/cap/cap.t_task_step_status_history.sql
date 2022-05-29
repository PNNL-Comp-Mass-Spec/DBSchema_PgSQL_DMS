--
-- Name: t_task_step_status_history; Type: TABLE; Schema: cap; Owner: d3l243
--

CREATE TABLE cap.t_task_step_status_history (
    entry_id integer NOT NULL,
    posting_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    step_tool public.citext NOT NULL,
    state smallint NOT NULL,
    step_count integer NOT NULL
);


ALTER TABLE cap.t_task_step_status_history OWNER TO d3l243;

--
-- Name: t_task_step_status_history_entry_id_seq; Type: SEQUENCE; Schema: cap; Owner: d3l243
--

ALTER TABLE cap.t_task_step_status_history ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME cap.t_task_step_status_history_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_task_step_status_history pk_t_task_step_status_history; Type: CONSTRAINT; Schema: cap; Owner: d3l243
--

ALTER TABLE ONLY cap.t_task_step_status_history
    ADD CONSTRAINT pk_t_task_step_status_history PRIMARY KEY (entry_id);

--
-- Name: ix_t_task_step_status_history_state; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_task_step_status_history_state ON cap.t_task_step_status_history USING btree (state);

--
-- Name: ix_t_task_step_status_history_step_tool; Type: INDEX; Schema: cap; Owner: d3l243
--

CREATE INDEX ix_t_task_step_status_history_step_tool ON cap.t_task_step_status_history USING btree (step_tool);

