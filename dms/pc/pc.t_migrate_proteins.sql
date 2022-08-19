--
-- Name: t_migrate_proteins; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_migrate_proteins (
    protein_id integer NOT NULL,
    sequence public.citext NOT NULL,
    length integer NOT NULL,
    molecular_formula public.citext,
    monoisotopic_mass double precision,
    average_mass double precision,
    sha1_hash public.citext NOT NULL,
    date_created timestamp without time zone,
    date_modified timestamp without time zone,
    is_encrypted smallint,
    seguid character(27)
);


ALTER TABLE pc.t_migrate_proteins OWNER TO d3l243;

--
-- Name: t_migrate_proteins pk_t_migrate_proteins; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_migrate_proteins
    ADD CONSTRAINT pk_t_migrate_proteins PRIMARY KEY (protein_id);

--
-- Name: ix_t_migrate_proteins_date_created; Type: INDEX; Schema: pc; Owner: d3l243
--

CREATE INDEX ix_t_migrate_proteins_date_created ON pc.t_migrate_proteins USING btree (date_created);

--
-- Name: ix_t_migrate_proteins_sha1_hash; Type: INDEX; Schema: pc; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_migrate_proteins_sha1_hash ON pc.t_migrate_proteins USING btree (sha1_hash);

--
-- Name: TABLE t_migrate_proteins; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_migrate_proteins TO readaccess;
GRANT SELECT ON TABLE pc.t_migrate_proteins TO writeaccess;

