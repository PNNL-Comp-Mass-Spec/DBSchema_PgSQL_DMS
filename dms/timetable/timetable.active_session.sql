--
-- Name: active_session; Type: TABLE; Schema: timetable; Owner: d3l243
--

CREATE UNLOGGED TABLE timetable.active_session (
    client_pid bigint NOT NULL,
    server_pid bigint NOT NULL,
    client_name text NOT NULL,
    started_at timestamp with time zone DEFAULT now()
);


ALTER TABLE timetable.active_session OWNER TO d3l243;

--
-- Name: TABLE active_session; Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON TABLE timetable.active_session IS 'Stores information about active sessions';

--
-- Name: TABLE active_session; Type: ACL; Schema: timetable; Owner: d3l243
--

GRANT SELECT ON TABLE timetable.active_session TO writeaccess;
GRANT INSERT,DELETE,TRUNCATE,UPDATE ON TABLE timetable.active_session TO pgdms;

