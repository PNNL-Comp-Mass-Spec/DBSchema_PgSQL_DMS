--
-- Name: log; Type: TABLE; Schema: timetable; Owner: d3l243
--

CREATE TABLE timetable.log (
    ts timestamp with time zone DEFAULT now(),
    pid integer NOT NULL,
    log_level timetable.log_type NOT NULL,
    client_name text DEFAULT timetable.get_client_name(pg_backend_pid()),
    message text,
    message_data jsonb
);


ALTER TABLE timetable.log OWNER TO d3l243;

--
-- Name: TABLE log; Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON TABLE timetable.log IS 'Stores log entries of active sessions';

--
-- Name: TABLE log; Type: ACL; Schema: timetable; Owner: d3l243
--

GRANT SELECT ON TABLE timetable.log TO writeaccess;
GRANT INSERT,DELETE,TRUNCATE,UPDATE ON TABLE timetable.log TO "svc-dms";

