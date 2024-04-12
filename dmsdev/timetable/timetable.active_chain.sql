--
-- Name: active_chain; Type: TABLE; Schema: timetable; Owner: d3l243
--

CREATE UNLOGGED TABLE timetable.active_chain (
    chain_id bigint NOT NULL,
    client_name text NOT NULL,
    started_at timestamp with time zone DEFAULT now()
);


ALTER TABLE timetable.active_chain OWNER TO d3l243;

--
-- Name: TABLE active_chain; Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON TABLE timetable.active_chain IS 'Stores information about active chains within session';

--
-- Name: TABLE active_chain; Type: ACL; Schema: timetable; Owner: d3l243
--

GRANT SELECT ON TABLE timetable.active_chain TO writeaccess;
GRANT INSERT,DELETE,TRUNCATE,UPDATE ON TABLE timetable.active_chain TO pgdms;

