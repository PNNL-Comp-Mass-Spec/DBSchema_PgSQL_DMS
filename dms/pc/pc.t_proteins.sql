--
-- Name: t_proteins; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_proteins (
    protein_id integer NOT NULL,
    sequence public.citext NOT NULL,
    length integer NOT NULL,
    molecular_formula public.citext,
    monoisotopic_mass double precision,
    average_mass double precision,
    sha1_hash public.citext NOT NULL,
    date_created timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    date_modified timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_encrypted smallint,
    seguid character(27)
);


ALTER TABLE pc.t_proteins OWNER TO d3l243;

--
-- Name: t_proteins_protein_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_proteins ALTER COLUMN protein_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_proteins_protein_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_proteins pk_t_proteins; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_proteins
    ADD CONSTRAINT pk_t_proteins PRIMARY KEY (protein_id);

--
-- Name: ix_t_proteins_date_created; Type: INDEX; Schema: pc; Owner: d3l243
--

CREATE INDEX ix_t_proteins_date_created ON pc.t_proteins USING btree (date_created);

--
-- Name: ix_t_proteins_sha1_hash; Type: INDEX; Schema: pc; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_proteins_sha1_hash ON pc.t_proteins USING btree (sha1_hash);

--
-- Name: TABLE t_proteins; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_proteins TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE pc.t_proteins TO writeaccess;
GRANT INSERT,DELETE,UPDATE ON TABLE pc.t_proteins TO pceditor;

