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
-- Name: TABLE execution_log; Type: ACL; Schema: timetable; Owner: d3l243
--

GRANT SELECT ON TABLE timetable.execution_log TO writeaccess;
GRANT INSERT,DELETE,TRUNCATE,UPDATE ON TABLE timetable.execution_log TO pgdms;

