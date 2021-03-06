--
-- Name: metric; Type: TABLE; Schema: pgwatch2; Owner: pgwatch2
--

CREATE TABLE pgwatch2.metric (
    m_id integer NOT NULL,
    m_name text NOT NULL,
    m_pg_version_from numeric NOT NULL,
    m_sql text NOT NULL,
    m_comment text,
    m_is_active boolean DEFAULT true NOT NULL,
    m_is_helper boolean DEFAULT false NOT NULL,
    m_last_modified_on timestamp with time zone DEFAULT now() NOT NULL,
    m_master_only boolean DEFAULT false NOT NULL,
    m_standby_only boolean DEFAULT false NOT NULL,
    m_column_attrs jsonb,
    m_sql_su text DEFAULT ''::text,
    CONSTRAINT metric_check CHECK ((NOT (m_master_only AND m_standby_only))),
    CONSTRAINT metric_m_name_check CHECK ((m_name ~ '^[a-z0-9_]+$'::text))
);


ALTER TABLE pgwatch2.metric OWNER TO pgwatch2;

--
-- Name: metric m_id; Type: DEFAULT; Schema: pgwatch2; Owner: pgwatch2
--

ALTER TABLE ONLY pgwatch2.metric ALTER COLUMN m_id SET DEFAULT nextval('pgwatch2.metric_m_id_seq'::regclass);

--
-- Name: metric metric_m_name_m_pg_version_from_ke; Type: CONSTRAINT; Schema: pgwatch2; Owner: pgwatch2
--

ALTER TABLE ONLY pgwatch2.metric
    ADD CONSTRAINT metric_m_name_m_pg_version_from_ke UNIQUE (m_name, m_pg_version_from, m_standby_only);

--
-- Name: metric metric_pkey; Type: CONSTRAINT; Schema: pgwatch2; Owner: pgwatch2
--

ALTER TABLE ONLY pgwatch2.metric
    ADD CONSTRAINT metric_pkey PRIMARY KEY (m_id);

