--
-- Name: preset_config; Type: TABLE; Schema: pgwatch2; Owner: pgwatch2
--

CREATE TABLE pgwatch2.preset_config (
    pc_name text NOT NULL,
    pc_description text NOT NULL,
    pc_config jsonb NOT NULL,
    pc_last_modified_on timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE pgwatch2.preset_config OWNER TO pgwatch2;

--
-- Name: preset_config preset_config_pkey; Type: CONSTRAINT; Schema: pgwatch2; Owner: pgwatch2
--

ALTER TABLE ONLY pgwatch2.preset_config
    ADD CONSTRAINT preset_config_pkey PRIMARY KEY (pc_name);
