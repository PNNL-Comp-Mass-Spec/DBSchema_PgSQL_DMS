--
-- Name: t_protein_names; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_protein_names (
    reference_id integer NOT NULL,
    name public.citext NOT NULL,
    description public.citext,
    annotation_type_id integer DEFAULT 6 NOT NULL,
    reference_fingerprint public.citext NOT NULL,
    date_added timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    protein_id integer NOT NULL
);


ALTER TABLE pc.t_protein_names OWNER TO d3l243;

--
-- Name: t_protein_names_reference_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_protein_names ALTER COLUMN reference_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_protein_names_reference_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_protein_names pk_t_protein_names; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_protein_names
    ADD CONSTRAINT pk_t_protein_names PRIMARY KEY (reference_id);

--
-- Name: ix_t_protein_names_name; Type: INDEX; Schema: pc; Owner: d3l243
--

CREATE INDEX ix_t_protein_names_name ON pc.t_protein_names USING btree (name);

--
-- Name: ix_t_protein_names_protein_id_include_ref_id_name_desc_annotn; Type: INDEX; Schema: pc; Owner: d3l243
--

CREATE INDEX ix_t_protein_names_protein_id_include_ref_id_name_desc_annotn ON pc.t_protein_names USING btree (protein_id) INCLUDE (reference_id, name, description, annotation_type_id);

--
-- Name: ix_t_protein_names_protein_id_reference_id; Type: INDEX; Schema: pc; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_protein_names_protein_id_reference_id ON pc.t_protein_names USING btree (protein_id, reference_id);

--
-- Name: ix_t_protein_names_ref_fingerprint; Type: INDEX; Schema: pc; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_protein_names_ref_fingerprint ON pc.t_protein_names USING btree (reference_fingerprint);

--
-- Name: t_protein_names fk_t_protein_names_t_annotation_types; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_protein_names
    ADD CONSTRAINT fk_t_protein_names_t_annotation_types FOREIGN KEY (annotation_type_id) REFERENCES pc.t_annotation_types(annotation_type_id);

--
-- Name: t_protein_names fk_t_protein_names_t_proteins; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_protein_names
    ADD CONSTRAINT fk_t_protein_names_t_proteins FOREIGN KEY (protein_id) REFERENCES pc.t_proteins(protein_id);

--
-- Name: TABLE t_protein_names; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_protein_names TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE pc.t_protein_names TO writeaccess;
GRANT INSERT,DELETE,UPDATE ON TABLE pc.t_protein_names TO pceditor;

