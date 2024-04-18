--
-- Name: config; Type: TABLE; Schema: admin; Owner: pgwatch2
--

CREATE TABLE admin.config (
    key text NOT NULL,
    value text NOT NULL,
    created_on timestamp with time zone DEFAULT now() NOT NULL,
    last_modified_on timestamp with time zone
);


ALTER TABLE admin.config OWNER TO pgwatch2;

--
-- Name: config config_pkey; Type: CONSTRAINT; Schema: admin; Owner: pgwatch2
--

ALTER TABLE ONLY admin.config
    ADD CONSTRAINT config_pkey PRIMARY KEY (key);

--
-- Name: config config_modified; Type: TRIGGER; Schema: admin; Owner: pgwatch2
--

CREATE TRIGGER config_modified BEFORE UPDATE ON admin.config FOR EACH ROW EXECUTE FUNCTION public.trg_config_modified();

