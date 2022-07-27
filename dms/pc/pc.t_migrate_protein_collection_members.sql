--
-- Name: t_migrate_protein_collection_members; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_migrate_protein_collection_members (
    member_id integer NOT NULL,
    original_reference_id integer NOT NULL,
    protein_id integer NOT NULL,
    protein_collection_id integer NOT NULL,
    sorting_index integer,
    original_description_id integer NOT NULL
);


ALTER TABLE pc.t_migrate_protein_collection_members OWNER TO d3l243;

--
-- Name: t_migrate_protein_collection_members pk_t_migrate_protein_collection_members; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_migrate_protein_collection_members
    ADD CONSTRAINT pk_t_migrate_protein_collection_members PRIMARY KEY (member_id);

--
-- Name: ix_t_migrate_protein_collection_members; Type: INDEX; Schema: pc; Owner: d3l243
--

CREATE INDEX ix_t_migrate_protein_collection_members ON pc.t_migrate_protein_collection_members USING btree (protein_id);

--
-- Name: ix_t_migrate_protein_collection_members_coll_id; Type: INDEX; Schema: pc; Owner: d3l243
--

CREATE INDEX ix_t_migrate_protein_collection_members_coll_id ON pc.t_migrate_protein_collection_members USING btree (protein_collection_id);

--
-- Name: ix_t_migrate_protein_collection_members_ref_id; Type: INDEX; Schema: pc; Owner: d3l243
--

CREATE INDEX ix_t_migrate_protein_collection_members_ref_id ON pc.t_migrate_protein_collection_members USING btree (original_reference_id);

--
-- Name: ix_t_migrate_protein_collection_members_sorting_index; Type: INDEX; Schema: pc; Owner: d3l243
--

CREATE INDEX ix_t_migrate_protein_collection_members_sorting_index ON pc.t_migrate_protein_collection_members USING btree (protein_collection_id, sorting_index);

--
-- Name: t_migrate_protein_collection_members fk_t_migrate_protein_collection_members_t_migrate_protein_names; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_migrate_protein_collection_members
    ADD CONSTRAINT fk_t_migrate_protein_collection_members_t_migrate_protein_names FOREIGN KEY (original_reference_id) REFERENCES pc.t_migrate_protein_names(reference_id);

--
-- Name: t_migrate_protein_collection_members fk_t_migrate_protein_collection_members_t_migrate_proteins; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_migrate_protein_collection_members
    ADD CONSTRAINT fk_t_migrate_protein_collection_members_t_migrate_proteins FOREIGN KEY (protein_id) REFERENCES pc.t_migrate_proteins(protein_id);

--
-- Name: t_migrate_protein_collection_members fk_t_migrate_protein_collection_members_t_protein_collections; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_migrate_protein_collection_members
    ADD CONSTRAINT fk_t_migrate_protein_collection_members_t_protein_collections FOREIGN KEY (protein_collection_id) REFERENCES pc.t_protein_collections(protein_collection_id);

