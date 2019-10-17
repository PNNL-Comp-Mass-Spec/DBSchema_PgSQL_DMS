--
-- Name: schema_version; Type: TABLE; Schema: pgwatch2; Owner: pgwatch2
--

CREATE TABLE pgwatch2.schema_version (
    sv_tag text NOT NULL,
    sv_created_on timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE pgwatch2.schema_version OWNER TO pgwatch2;

--
-- Name: schema_version schema_version_pkey; Type: CONSTRAINT; Schema: pgwatch2; Owner: pgwatch2
--

ALTER TABLE ONLY pgwatch2.schema_version
    ADD CONSTRAINT schema_version_pkey PRIMARY KEY (sv_tag);
