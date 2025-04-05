--
-- Name: t_job_step_status_history; Type: TABLE; Schema: sw; Owner: d3l243
--

CREATE TABLE sw.t_job_step_status_history (
    entry_id integer NOT NULL,
    posting_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    step_tool public.citext NOT NULL,
    state smallint NOT NULL,
    step_count integer NOT NULL
);


ALTER TABLE sw.t_job_step_status_history OWNER TO d3l243;

--
-- Name: t_job_step_status_history_entry_id_seq; Type: SEQUENCE; Schema: sw; Owner: d3l243
--

ALTER TABLE sw.t_job_step_status_history ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME sw.t_job_step_status_history_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_job_step_status_history pk_t_job_step_status_history; Type: CONSTRAINT; Schema: sw; Owner: d3l243
--

ALTER TABLE ONLY sw.t_job_step_status_history
    ADD CONSTRAINT pk_t_job_step_status_history PRIMARY KEY (entry_id);

ALTER TABLE sw.t_job_step_status_history CLUSTER ON pk_t_job_step_status_history;

--
-- Name: ix_t_job_step_status_history_state; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_job_step_status_history_state ON sw.t_job_step_status_history USING btree (state);

--
-- Name: ix_t_job_step_status_history_step_tool; Type: INDEX; Schema: sw; Owner: d3l243
--

CREATE INDEX ix_t_job_step_status_history_step_tool ON sw.t_job_step_status_history USING btree (step_tool);

--
-- Name: TABLE t_job_step_status_history; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.t_job_step_status_history TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE sw.t_job_step_status_history TO writeaccess;

