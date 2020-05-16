--
-- Name: monitored_db; Type: TABLE; Schema: pgwatch2; Owner: pgwatch2
--

CREATE TABLE pgwatch2.monitored_db (
    md_id integer NOT NULL,
    md_unique_name text NOT NULL,
    md_hostname text NOT NULL,
    md_port text DEFAULT 5432 NOT NULL,
    md_dbname text NOT NULL,
    md_user text NOT NULL,
    md_password text,
    md_is_superuser boolean DEFAULT false NOT NULL,
    md_sslmode text DEFAULT 'disable'::text NOT NULL,
    md_preset_config_name text DEFAULT 'basic'::text,
    md_config jsonb,
    md_is_enabled boolean DEFAULT true NOT NULL,
    md_last_modified_on timestamp with time zone DEFAULT now() NOT NULL,
    md_statement_timeout_seconds integer DEFAULT 5 NOT NULL,
    md_dbtype text DEFAULT 'postgres'::text NOT NULL,
    md_include_pattern text,
    md_exclude_pattern text,
    md_custom_tags jsonb,
    md_group text DEFAULT 'default'::text NOT NULL,
    md_root_ca_path text DEFAULT ''::text NOT NULL,
    md_client_cert_path text DEFAULT ''::text NOT NULL,
    md_client_key_path text DEFAULT ''::text NOT NULL,
    md_password_type text DEFAULT 'plain-text'::text NOT NULL,
    md_host_config jsonb,
    md_only_if_master boolean DEFAULT false NOT NULL,
    CONSTRAINT monitored_db_md_dbtype_check CHECK ((md_dbtype = ANY (ARRAY['postgres'::text, 'pgbouncer'::text, 'postgres-continuous-discovery'::text, 'patroni'::text, 'patroni-continuous-discovery'::text]))),
    CONSTRAINT monitored_db_md_group_check CHECK ((md_group ~ '\w+'::text)),
    CONSTRAINT monitored_db_md_password_type_check CHECK ((md_password_type = ANY (ARRAY['plain-text'::text, 'aes-gcm-256'::text]))),
    CONSTRAINT monitored_db_md_sslmode_check CHECK ((md_sslmode = ANY (ARRAY['disable'::text, 'require'::text, 'verify-ca'::text, 'verify-full'::text]))),
    CONSTRAINT no_colon_on_unique_name CHECK ((md_unique_name !~ ':'::text)),
    CONSTRAINT preset_or_custom_config CHECK (((NOT ((md_preset_config_name IS NULL) AND (md_config IS NULL))) AND (NOT ((md_preset_config_name IS NOT NULL) AND (md_config IS NOT NULL)))))
);


ALTER TABLE pgwatch2.monitored_db OWNER TO pgwatch2;

--
-- Name: monitored_db_md_id_seq; Type: SEQUENCE; Schema: pgwatch2; Owner: pgwatch2
--

CREATE SEQUENCE pgwatch2.monitored_db_md_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pgwatch2.monitored_db_md_id_seq OWNER TO pgwatch2;

--
-- Name: monitored_db_md_id_seq; Type: SEQUENCE OWNED BY; Schema: pgwatch2; Owner: pgwatch2
--

ALTER SEQUENCE pgwatch2.monitored_db_md_id_seq OWNED BY pgwatch2.monitored_db.md_id;

--
-- Name: monitored_db md_id; Type: DEFAULT; Schema: pgwatch2; Owner: pgwatch2
--

ALTER TABLE ONLY pgwatch2.monitored_db ALTER COLUMN md_id SET DEFAULT nextval('pgwatch2.monitored_db_md_id_seq'::regclass);

--
-- Name: monitored_db monitored_db_md_unique_name_key; Type: CONSTRAINT; Schema: pgwatch2; Owner: pgwatch2
--

ALTER TABLE ONLY pgwatch2.monitored_db
    ADD CONSTRAINT monitored_db_md_unique_name_key UNIQUE (md_unique_name);

--
-- Name: monitored_db monitored_db_pkey; Type: CONSTRAINT; Schema: pgwatch2; Owner: pgwatch2
--

ALTER TABLE ONLY pgwatch2.monitored_db
    ADD CONSTRAINT monitored_db_pkey PRIMARY KEY (md_id);

--
-- Name: monitored_db_md_hostname_md_port_md_dbname_md_is_enabled_idx; Type: INDEX; Schema: pgwatch2; Owner: pgwatch2
--

CREATE UNIQUE INDEX monitored_db_md_hostname_md_port_md_dbname_md_is_enabled_idx ON pgwatch2.monitored_db USING btree (md_hostname, md_port, md_dbname, md_is_enabled) WHERE (NOT (md_dbtype ~ 'patroni'::text));

--
-- Name: monitored_db monitored_db_md_preset_config_name_fkey; Type: FK CONSTRAINT; Schema: pgwatch2; Owner: pgwatch2
--

ALTER TABLE ONLY pgwatch2.monitored_db
    ADD CONSTRAINT monitored_db_md_preset_config_name_fkey FOREIGN KEY (md_preset_config_name) REFERENCES pgwatch2.preset_config(pc_name);

