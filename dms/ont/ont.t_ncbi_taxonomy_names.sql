--
-- Name: t_ncbi_taxonomy_names; Type: TABLE; Schema: ont; Owner: d3l243
--

CREATE TABLE ont.t_ncbi_taxonomy_names (
    entry_id integer NOT NULL,
    tax_id integer NOT NULL,
    name public.citext NOT NULL,
    unique_name public.citext,
    name_class public.citext NOT NULL
);


ALTER TABLE ont.t_ncbi_taxonomy_names OWNER TO d3l243;

--
-- Name: t_ncbi_taxonomy_names_entry_id_seq; Type: SEQUENCE; Schema: ont; Owner: d3l243
--

ALTER TABLE ont.t_ncbi_taxonomy_names ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ont.t_ncbi_taxonomy_names_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_ncbi_taxonomy_names pk_t_ncbi_taxonomy_names; Type: CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_ncbi_taxonomy_names
    ADD CONSTRAINT pk_t_ncbi_taxonomy_names PRIMARY KEY (entry_id);

--
-- Name: ix_t_ncbi_taxonomy_names_name; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_ncbi_taxonomy_names_name ON ont.t_ncbi_taxonomy_names USING btree (name);

--
-- Name: ix_t_ncbi_taxonomy_names_name_class_name_include_tax_id; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_ncbi_taxonomy_names_name_class_name_include_tax_id ON ont.t_ncbi_taxonomy_names USING btree (name_class, name) INCLUDE (tax_id);

--
-- Name: ix_t_ncbi_taxonomy_names_name_lower_text_pattern_ops; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_ncbi_taxonomy_names_name_lower_text_pattern_ops ON ont.t_ncbi_taxonomy_names USING btree (lower((name)::text) text_pattern_ops);

--
-- Name: ix_t_ncbi_taxonomy_names_tax_id; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_ncbi_taxonomy_names_tax_id ON ont.t_ncbi_taxonomy_names USING btree (tax_id);

--
-- Name: t_ncbi_taxonomy_names fk_t_ncbi_taxonomy_names_t_ncbi_taxonomy_nodes; Type: FK CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_ncbi_taxonomy_names
    ADD CONSTRAINT fk_t_ncbi_taxonomy_names_t_ncbi_taxonomy_nodes FOREIGN KEY (tax_id) REFERENCES ont.t_ncbi_taxonomy_nodes(tax_id);

--
-- Name: TABLE t_ncbi_taxonomy_names; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.t_ncbi_taxonomy_names TO readaccess;
GRANT SELECT ON TABLE ont.t_ncbi_taxonomy_names TO writeaccess;

