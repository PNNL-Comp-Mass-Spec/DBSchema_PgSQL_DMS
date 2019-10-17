--
-- Name: metric m_id; Type: DEFAULT; Schema: pgwatch2; Owner: pgwatch2
--

ALTER TABLE ONLY pgwatch2.metric ALTER COLUMN m_id SET DEFAULT nextval('pgwatch2.metric_m_id_seq'::regclass);
