--
-- Name: t_migrate_protein_headers; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_migrate_protein_headers (
    protein_id integer NOT NULL,
    sequence_head public.citext NOT NULL
);


ALTER TABLE pc.t_migrate_protein_headers OWNER TO d3l243;

--
-- Name: t_migrate_protein_headers pk_t_migrate_protein_headers; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_migrate_protein_headers
    ADD CONSTRAINT pk_t_migrate_protein_headers PRIMARY KEY (protein_id);

--
-- Name: ix_t_migrate_protein_headers; Type: INDEX; Schema: pc; Owner: d3l243
--

CREATE INDEX ix_t_migrate_protein_headers ON pc.t_migrate_protein_headers USING btree (sequence_head);

