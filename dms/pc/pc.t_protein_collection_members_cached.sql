--
-- Name: t_protein_collection_members_cached; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_protein_collection_members_cached (
    protein_collection_id integer NOT NULL,
    reference_id integer NOT NULL,
    protein_name public.citext NOT NULL,
    description public.citext,
    residue_count integer NOT NULL,
    monoisotopic_mass double precision,
    protein_id integer NOT NULL
);


ALTER TABLE pc.t_protein_collection_members_cached OWNER TO d3l243;

--
-- Name: t_protein_collection_members_cached pk_t_protein_collection_members_cached; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_protein_collection_members_cached
    ADD CONSTRAINT pk_t_protein_collection_members_cached PRIMARY KEY (protein_collection_id, reference_id);

--
-- Name: ix_t_protein_collection_members_cached_protein_id; Type: INDEX; Schema: pc; Owner: d3l243
--

CREATE INDEX ix_t_protein_collection_members_cached_protein_id ON pc.t_protein_collection_members_cached USING btree (protein_id);

--
-- Name: t_protein_collection_members_cached fk_t_protein_collection_members_cached_t_protein_collections; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_protein_collection_members_cached
    ADD CONSTRAINT fk_t_protein_collection_members_cached_t_protein_collections FOREIGN KEY (protein_collection_id) REFERENCES pc.t_protein_collections(protein_collection_id);

--
-- Name: TABLE t_protein_collection_members_cached; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_protein_collection_members_cached TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE pc.t_protein_collection_members_cached TO writeaccess;

