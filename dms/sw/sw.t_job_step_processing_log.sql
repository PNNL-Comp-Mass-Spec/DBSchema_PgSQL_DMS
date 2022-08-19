--
-- Name: t_job_step_processing_log; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_job_step_processing_log (
    event_id integer NOT NULL,
    job integer NOT NULL,
    step integer NOT NULL,
    processor public.citext NOT NULL,
    remote_info_id integer DEFAULT 0 NOT NULL,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE sw.t_job_step_processing_log OWNER TO d3l243;

--
-- Name: t_job_step_processing_log_event_id_seq; Type: SEQUENCE; Schema: sw; Owner: d3l243
--

ALTER TABLE sw.t_job_step_processing_log ALTER COLUMN event_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sw.t_job_step_processing_log_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_job_step_processing_log pk_t_job_step_processing_log; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_job_step_processing_log
    ADD CONSTRAINT pk_t_job_step_processing_log PRIMARY KEY (event_id);

--
-- Name: ix_t_job_step_processing_log_job_step; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_job_step_processing_log_job_step ON sw.t_job_step_processing_log USING btree (job, step);

--
-- Name: ix_t_job_step_processing_log_processor; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_job_step_processing_log_processor ON sw.t_job_step_processing_log USING btree (processor);

--
-- Name: TABLE t_job_step_processing_log; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.t_job_step_processing_log TO readaccess;

