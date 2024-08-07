--
-- Name: execution_log; Type: TABLE; Schema: timetable; Owner: d3l243
--

CREATE TABLE timetable.execution_log (
    chain_id bigint,
    task_id bigint,
    txid bigint NOT NULL,
    last_run timestamp with time zone DEFAULT now(),
    finished timestamp with time zone,
    pid bigint,
    returncode integer,
    ignore_error boolean,
    kind timetable.command_kind,
    command text,
    output text,
    client_name text NOT NULL
);


ALTER TABLE timetable.execution_log OWNER TO d3l243;

--
-- Name: TABLE execution_log; Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON TABLE timetable.execution_log IS 'Stores log entries of executed tasks and chains';

--
-- Name: ix_execution_log_chain_id_task_id; Type: INDEX; Schema: timetable; Owner: d3l243
--

CREATE INDEX ix_execution_log_chain_id_task_id ON timetable.execution_log USING btree (chain_id, task_id);

--
-- Name: ix_execution_log_finished; Type: INDEX; Schema: timetable; Owner: d3l243
--

CREATE INDEX ix_execution_log_finished ON timetable.execution_log USING btree (finished);

--
-- Name: ix_execution_log_last_run; Type: INDEX; Schema: timetable; Owner: d3l243
--

CREATE INDEX ix_execution_log_last_run ON timetable.execution_log USING btree (last_run);

--
-- Name: TABLE execution_log; Type: ACL; Schema: timetable; Owner: d3l243
--

GRANT SELECT ON TABLE timetable.execution_log TO writeaccess;
GRANT INSERT,DELETE,TRUNCATE,UPDATE ON TABLE timetable.execution_log TO pgdms;

