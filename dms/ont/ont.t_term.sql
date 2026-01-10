--
-- Name: t_term; Type: TABLE; Schema: ont; Owner: d3l243
--

CREATE TABLE ont.t_term (
    term_pk public.citext NOT NULL,
    ontology_id integer NOT NULL,
    term_name public.citext NOT NULL,
    identifier public.citext NOT NULL,
    definition public.citext,
    namespace public.citext,
    is_obsolete smallint,
    is_root_term smallint,
    is_leaf smallint,
    updated timestamp without time zone
);


ALTER TABLE ont.t_term OWNER TO d3l243;

--
-- Name: t_term pk_term; Type: CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_term
    ADD CONSTRAINT pk_term PRIMARY KEY (term_pk);

--
-- Name: ix_t_term_identifier; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_term_identifier ON ont.t_term USING btree (identifier);

--
-- Name: ix_t_term_is_leaf; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_term_is_leaf ON ont.t_term USING btree (is_leaf);

--
-- Name: ix_t_term_is_obsolete; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_term_is_obsolete ON ont.t_term USING btree (is_obsolete);

--
-- Name: ix_t_term_namespace; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_term_namespace ON ont.t_term USING btree (namespace);

--
-- Name: ix_t_term_term_name_lower_text_pattern_ops; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_term_term_name_lower_text_pattern_ops ON ont.t_term USING btree (lower((term_name)::text) text_pattern_ops);

--
-- Name: ix_term_ontology_id; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_term_ontology_id ON ont.t_term USING btree (ontology_id);

--
-- Name: TABLE t_term; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.t_term TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE ont.t_term TO writeaccess;

