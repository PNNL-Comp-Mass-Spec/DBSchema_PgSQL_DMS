--
-- Name: t_ncbi_taxonomy_nodes; Type: TABLE; Schema: ont; Owner: d3l243
--

CREATE TABLE ont.t_ncbi_taxonomy_nodes (
    tax_id integer NOT NULL,
    parent_tax_id integer NOT NULL,
    rank public.citext NOT NULL,
    embl_code public.citext NOT NULL,
    division_id smallint NOT NULL,
    inherited_div smallint NOT NULL,
    genetic_code_id smallint NOT NULL,
    inherited_gc smallint NOT NULL,
    mito_genetic_code_id smallint NOT NULL,
    inherited_mito_gc smallint NOT NULL,
    gen_bank_hidden smallint NOT NULL,
    hidden_subtree smallint NOT NULL,
    comments public.citext
);


ALTER TABLE ont.t_ncbi_taxonomy_nodes OWNER TO d3l243;

--
-- Name: t_ncbi_taxonomy_nodes pk_t_ncbi_taxonomy_nodes; Type: CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_ncbi_taxonomy_nodes
    ADD CONSTRAINT pk_t_ncbi_taxonomy_nodes PRIMARY KEY (tax_id);

--
-- Name: ix_t_ncbi_taxonomy_nodes_parent_tax_id; Type: INDEX; Schema: ont; Owner: d3l243
--

CREATE INDEX ix_t_ncbi_taxonomy_nodes_parent_tax_id ON ont.t_ncbi_taxonomy_nodes USING btree (parent_tax_id);

--
-- Name: t_ncbi_taxonomy_nodes fk_t_ncbi_taxonomy_nodes_t_ncbi_taxonomy_division; Type: FK CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_ncbi_taxonomy_nodes
    ADD CONSTRAINT fk_t_ncbi_taxonomy_nodes_t_ncbi_taxonomy_division FOREIGN KEY (division_id) REFERENCES ont.t_ncbi_taxonomy_division(division_id);

--
-- Name: t_ncbi_taxonomy_nodes fk_t_ncbi_taxonomy_nodes_t_ncbi_taxonomy_gen_code; Type: FK CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_ncbi_taxonomy_nodes
    ADD CONSTRAINT fk_t_ncbi_taxonomy_nodes_t_ncbi_taxonomy_gen_code FOREIGN KEY (genetic_code_id) REFERENCES ont.t_ncbi_taxonomy_gen_code(genetic_code_id);

--
-- Name: TABLE t_ncbi_taxonomy_nodes; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.t_ncbi_taxonomy_nodes TO readaccess;
GRANT SELECT ON TABLE ont.t_ncbi_taxonomy_nodes TO writeaccess;

