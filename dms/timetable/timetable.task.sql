--
-- Name: task; Type: TABLE; Schema: timetable; Owner: d3l243
--

CREATE TABLE timetable.task (
    task_id bigint NOT NULL,
    chain_id bigint,
    task_order double precision NOT NULL,
    task_name text,
    kind timetable.command_kind DEFAULT 'SQL'::timetable.command_kind NOT NULL,
    command text NOT NULL,
    run_as text,
    database_connection text,
    ignore_error boolean DEFAULT false NOT NULL,
    autonomous boolean DEFAULT false NOT NULL,
    timeout integer DEFAULT 0
);


ALTER TABLE timetable.task OWNER TO d3l243;

--
-- Name: TABLE task; Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON TABLE timetable.task IS 'Holds information about chain elements aka tasks';

--
-- Name: COLUMN task.chain_id; Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON COLUMN timetable.task.chain_id IS 'Link to the chain, if NULL task considered to be disabled';

--
-- Name: COLUMN task.task_order; Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON COLUMN timetable.task.task_order IS 'Indicates the order of task within a chain';

--
-- Name: COLUMN task.kind; Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON COLUMN timetable.task.kind IS 'Indicates whether "command" is SQL, built-in function or an external program';

--
-- Name: COLUMN task.command; Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON COLUMN timetable.task.command IS 'Contains either an SQL command, or command string to be executed';

--
-- Name: COLUMN task.run_as; Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON COLUMN timetable.task.run_as IS 'Role name to run task as. Uses SET ROLE for SQL commands';

--
-- Name: COLUMN task.ignore_error; Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON COLUMN timetable.task.ignore_error IS 'Indicates whether a next task in a chain can be executed regardless of the success of the current one';

--
-- Name: COLUMN task.timeout; Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON COLUMN timetable.task.timeout IS 'Abort any task within a chain that takes more than the specified number of milliseconds';

--
-- Name: task_task_id_seq; Type: SEQUENCE; Schema: timetable; Owner: d3l243
--

CREATE SEQUENCE timetable.task_task_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE timetable.task_task_id_seq OWNER TO d3l243;

--
-- Name: task_task_id_seq; Type: SEQUENCE OWNED BY; Schema: timetable; Owner: d3l243
--

ALTER SEQUENCE timetable.task_task_id_seq OWNED BY timetable.task.task_id;

--
-- Name: task task_id; Type: DEFAULT; Schema: timetable; Owner: d3l243
--

ALTER TABLE ONLY timetable.task ALTER COLUMN task_id SET DEFAULT nextval('timetable.task_task_id_seq'::regclass);

--
-- Name: task task_pkey; Type: CONSTRAINT; Schema: timetable; Owner: d3l243
--

ALTER TABLE ONLY timetable.task
    ADD CONSTRAINT task_pkey PRIMARY KEY (task_id);

--
-- Name: task task_chain_id_fkey; Type: FK CONSTRAINT; Schema: timetable; Owner: d3l243
--

ALTER TABLE ONLY timetable.task
    ADD CONSTRAINT task_chain_id_fkey FOREIGN KEY (chain_id) REFERENCES timetable.chain(chain_id) ON UPDATE CASCADE ON DELETE CASCADE;

--
-- Name: TABLE task; Type: ACL; Schema: timetable; Owner: d3l243
--

GRANT INSERT,DELETE,TRUNCATE,UPDATE ON TABLE timetable.task TO pgdms;
GRANT SELECT ON TABLE timetable.task TO readaccess;

