--
-- Name: monitored_db md_id; Type: DEFAULT; Schema: pgwatch2; Owner: pgwatch2
--

ALTER TABLE ONLY pgwatch2.monitored_db ALTER COLUMN md_id SET DEFAULT nextval('pgwatch2.monitored_db_md_id_seq'::regclass);
