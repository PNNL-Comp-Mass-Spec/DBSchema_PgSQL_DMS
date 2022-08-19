--
-- Name: t_protein_collection_members; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_protein_collection_members (
    member_id integer NOT NULL,
    original_reference_id integer NOT NULL,
    protein_id integer NOT NULL,
    protein_collection_id integer NOT NULL,
    sorting_index integer,
    original_description_id integer DEFAULT 0 NOT NULL
);


ALTER TABLE pc.t_protein_collection_members OWNER TO d3l243;

--
-- Name: t_protein_collection_members_member_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_protein_collection_members ALTER COLUMN member_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_protein_collection_members_member_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_protein_collection_members pk_t_protein_collection_members; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_protein_collection_members
    ADD CONSTRAINT pk_t_protein_collection_members PRIMARY KEY (member_id);

--
-- Name: ix_t_protein_collection_members; Type: INDEX; Schema: pc; Owner: d3l243
--

CREATE INDEX ix_t_protein_collection_members ON pc.t_protein_collection_members USING btree (protein_id);

--
-- Name: ix_t_protein_collection_members_coll_id; Type: INDEX; Schema: pc; Owner: d3l243
--

CREATE INDEX ix_t_protein_collection_members_coll_id ON pc.t_protein_collection_members USING btree (protein_collection_id);

--
-- Name: ix_t_protein_collection_members_ref_id; Type: INDEX; Schema: pc; Owner: d3l243
--

CREATE INDEX ix_t_protein_collection_members_ref_id ON pc.t_protein_collection_members USING btree (original_reference_id);

--
-- Name: ix_t_protein_collection_members_sorting_index; Type: INDEX; Schema: pc; Owner: d3l243
--

CREATE INDEX ix_t_protein_collection_members_sorting_index ON pc.t_protein_collection_members USING btree (protein_collection_id, sorting_index);

--
-- Name: t_protein_collection_members fk_t_protein_collection_members_t_protein_collections; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_protein_collection_members
    ADD CONSTRAINT fk_t_protein_collection_members_t_protein_collections FOREIGN KEY (protein_collection_id) REFERENCES pc.t_protein_collections(protein_collection_id);

--
-- Name: t_protein_collection_members fk_t_protein_collection_members_t_protein_names; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_protein_collection_members
    ADD CONSTRAINT fk_t_protein_collection_members_t_protein_names FOREIGN KEY (original_reference_id) REFERENCES pc.t_protein_names(reference_id);

--
-- Name: t_protein_collection_members fk_t_protein_collection_members_t_proteins; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_protein_collection_members
    ADD CONSTRAINT fk_t_protein_collection_members_t_proteins FOREIGN KEY (protein_id) REFERENCES pc.t_proteins(protein_id);

--
-- Name: TABLE t_protein_collection_members; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_protein_collection_members TO readaccess;

