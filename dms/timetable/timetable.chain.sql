--
-- Name: chain; Type: TABLE; Schema: timetable; Owner: d3l243
--

CREATE TABLE timetable.chain (
    chain_id bigint NOT NULL,
    chain_name text NOT NULL,
    run_at timetable.cron,
    max_instances integer,
    timeout integer DEFAULT 0,
    live boolean DEFAULT false,
    self_destruct boolean DEFAULT false,
    exclusive_execution boolean DEFAULT false,
    client_name text,
    on_error text
);


ALTER TABLE timetable.chain OWNER TO d3l243;

--
-- Name: TABLE chain; Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON TABLE timetable.chain IS 'Stores information about chains schedule';

--
-- Name: COLUMN chain.run_at; Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON COLUMN timetable.chain.run_at IS 'Extended CRON-style time notation the chain has to be run at';

--
-- Name: COLUMN chain.max_instances; Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON COLUMN timetable.chain.max_instances IS 'Number of instances (clients) this chain can run in parallel';

--
-- Name: COLUMN chain.timeout; Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON COLUMN timetable.chain.timeout IS 'Abort any chain that takes more than the specified number of milliseconds';

--
-- Name: COLUMN chain.live; Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON COLUMN timetable.chain.live IS 'Indication that the chain is ready to run, set to FALSE to pause execution';

--
-- Name: COLUMN chain.self_destruct; Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON COLUMN timetable.chain.self_destruct IS 'Indication that this chain will delete itself after successful run';

--
-- Name: COLUMN chain.exclusive_execution; Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON COLUMN timetable.chain.exclusive_execution IS 'All parallel chains should be paused while executing this chain';

--
-- Name: COLUMN chain.client_name; Type: COMMENT; Schema: timetable; Owner: d3l243
--

COMMENT ON COLUMN timetable.chain.client_name IS 'Only client with this name is allowed to run this chain, set to NULL to allow any client';

--
-- Name: chain_chain_id_seq; Type: SEQUENCE; Schema: timetable; Owner: d3l243
--

CREATE SEQUENCE timetable.chain_chain_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE timetable.chain_chain_id_seq OWNER TO d3l243;

--
-- Name: chain_chain_id_seq; Type: SEQUENCE OWNED BY; Schema: timetable; Owner: d3l243
--

ALTER SEQUENCE timetable.chain_chain_id_seq OWNED BY timetable.chain.chain_id;

--
-- Name: chain chain_id; Type: DEFAULT; Schema: timetable; Owner: d3l243
--

ALTER TABLE ONLY timetable.chain ALTER COLUMN chain_id SET DEFAULT nextval('timetable.chain_chain_id_seq'::regclass);

--
-- Name: chain chain_chain_name_key; Type: CONSTRAINT; Schema: timetable; Owner: d3l243
--

ALTER TABLE ONLY timetable.chain
    ADD CONSTRAINT chain_chain_name_key UNIQUE (chain_name);

--
-- Name: chain chain_pkey; Type: CONSTRAINT; Schema: timetable; Owner: d3l243
--

ALTER TABLE ONLY timetable.chain
    ADD CONSTRAINT chain_pkey PRIMARY KEY (chain_id);

--
-- Name: TABLE chain; Type: ACL; Schema: timetable; Owner: d3l243
--

GRANT SELECT ON TABLE timetable.chain TO writeaccess;
GRANT INSERT,DELETE,TRUNCATE,UPDATE ON TABLE timetable.chain TO pgdms;

