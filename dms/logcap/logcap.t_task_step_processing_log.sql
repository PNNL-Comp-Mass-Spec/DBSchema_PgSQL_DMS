--
-- Name: t_task_step_processing_log; Type: TABLE; Schema: logcap; Owner: d3l243
--

CREATE TABLE logcap.t_task_step_processing_log (
    id integer NOT NULL,
    event_id integer NOT NULL,
    job integer NOT NULL,
    step integer NOT NULL,
    processor public.citext NOT NULL,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE logcap.t_task_step_processing_log OWNER TO d3l243;

--
-- Name: t_task_step_processing_log_id_seq; Type: SEQUENCE; Schema: logcap; Owner: d3l243
--

ALTER TABLE logcap.t_task_step_processing_log ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME logcap.t_task_step_processing_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_task_step_processing_log ix_logcap_t_task_step_processing_log_unique_event_id; Type: CONSTRAINT; Schema: logcap; Owner: d3l243
--

ALTER TABLE ONLY logcap.t_task_step_processing_log
    ADD CONSTRAINT ix_logcap_t_task_step_processing_log_unique_event_id UNIQUE (event_id);

--
-- Name: t_task_step_processing_log pk_t_task_step_processing_log; Type: CONSTRAINT; Schema: logcap; Owner: d3l243
--

ALTER TABLE ONLY logcap.t_task_step_processing_log
    ADD CONSTRAINT pk_t_task_step_processing_log PRIMARY KEY (id);

--
-- Name: ix_t_task_step_processing_log_event_id; Type: INDEX; Schema: logcap; Owner: d3l243
--

CREATE INDEX ix_t_task_step_processing_log_event_id ON logcap.t_task_step_processing_log USING btree (event_id);

--
-- Name: ix_t_task_step_processing_log_job_step; Type: INDEX; Schema: logcap; Owner: d3l243
--

CREATE INDEX ix_t_task_step_processing_log_job_step ON logcap.t_task_step_processing_log USING btree (job, step);

--
-- Name: ix_t_task_step_processing_log_processor; Type: INDEX; Schema: logcap; Owner: d3l243
--

CREATE INDEX ix_t_task_step_processing_log_processor ON logcap.t_task_step_processing_log USING btree (processor);

--
-- Name: TABLE t_task_step_processing_log; Type: ACL; Schema: logcap; Owner: d3l243
--

GRANT SELECT ON TABLE logcap.t_task_step_processing_log TO writeaccess;

