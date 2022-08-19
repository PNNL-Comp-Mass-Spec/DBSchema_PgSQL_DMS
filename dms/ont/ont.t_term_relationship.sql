--
-- Name: t_term_relationship; Type: TABLE; Schema: ont; Owner: d3l243
--

CREATE TABLE ont.t_term_relationship (
    term_relationship_id integer NOT NULL,
    subject_term_pk public.citext NOT NULL,
    predicate_term_pk public.citext NOT NULL,
    object_term_pk public.citext NOT NULL,
    ontology_id integer DEFAULT 0 NOT NULL
);


ALTER TABLE ont.t_term_relationship OWNER TO d3l243;

--
-- Name: t_term_relationship pk_term_relationship; Type: CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_term_relationship
    ADD CONSTRAINT pk_term_relationship PRIMARY KEY (term_relationship_id);

--
-- Name: ix_t_term_relationship_object_term_pk; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_term_relationship_object_term_pk ON ont.t_term_relationship USING btree (object_term_pk);

--
-- Name: ix_t_term_relationship_ontology_id; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_term_relationship_ontology_id ON ont.t_term_relationship USING btree (ontology_id);

--
-- Name: ix_t_term_relationship_predicate_term_pk; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_term_relationship_predicate_term_pk ON ont.t_term_relationship USING btree (predicate_term_pk);

--
-- Name: ix_t_term_relationship_subject_term_pk; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_term_relationship_subject_term_pk ON ont.t_term_relationship USING btree (subject_term_pk);

--
-- Name: TABLE t_term_relationship; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.t_term_relationship TO readaccess;
GRANT SELECT ON TABLE ont.t_term_relationship TO writeaccess;

