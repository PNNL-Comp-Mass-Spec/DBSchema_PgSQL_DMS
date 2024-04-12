--
-- Name: t_protein_collections; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_protein_collections (
    protein_collection_id integer NOT NULL,
    collection_name public.citext NOT NULL,
    description public.citext,
    source public.citext,
    collection_type_id smallint DEFAULT 1 NOT NULL,
    collection_state_id smallint DEFAULT 1 NOT NULL,
    primary_annotation_type_id integer NOT NULL,
    num_proteins integer,
    num_residues integer,
    includes_contaminants smallint DEFAULT 0 NOT NULL,
    date_created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    date_modified timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    authentication_hash public.citext,
    contents_encrypted smallint DEFAULT 0 NOT NULL,
    uploaded_by public.citext DEFAULT SESSION_USER,
    migrate_to_filtered_tables smallint DEFAULT 0 NOT NULL
);


ALTER TABLE pc.t_protein_collections OWNER TO d3l243;

--
-- Name: t_protein_collections_protein_collection_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_protein_collections ALTER COLUMN protein_collection_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_protein_collections_protein_collection_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_protein_collections pk_t_protein_collections; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_protein_collections
    ADD CONSTRAINT pk_t_protein_collections PRIMARY KEY (protein_collection_id);

--
-- Name: ix_t_protein_collections_protein_collection; Type: INDEX; Schema: pc; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_protein_collections_protein_collection ON pc.t_protein_collections USING btree (collection_name);

--
-- Name: t_protein_collections trig_t_protein_collections_after_delete; Type: TRIGGER; Schema: pc; Owner: d3l243
--

CREATE TRIGGER trig_t_protein_collections_after_delete AFTER DELETE ON pc.t_protein_collections REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION pc.trigfn_t_protein_collections_after_delete();

--
-- Name: t_protein_collections trig_t_protein_collections_after_insert; Type: TRIGGER; Schema: pc; Owner: d3l243
--

CREATE TRIGGER trig_t_protein_collections_after_insert AFTER INSERT ON pc.t_protein_collections REFERENCING NEW TABLE AS inserted FOR EACH STATEMENT EXECUTE FUNCTION pc.trigfn_t_protein_collections_after_insert();

--
-- Name: t_protein_collections trig_t_protein_collections_after_update; Type: TRIGGER; Schema: pc; Owner: d3l243
--

CREATE TRIGGER trig_t_protein_collections_after_update AFTER UPDATE ON pc.t_protein_collections FOR EACH ROW WHEN ((old.collection_state_id <> new.collection_state_id)) EXECUTE FUNCTION pc.trigfn_t_protein_collections_after_update();

--
-- Name: t_protein_collections trig_t_protein_collections_after_update_all; Type: TRIGGER; Schema: pc; Owner: d3l243
--

CREATE TRIGGER trig_t_protein_collections_after_update_all AFTER UPDATE ON pc.t_protein_collections REFERENCING OLD TABLE AS deleted FOR EACH STATEMENT EXECUTE FUNCTION pc.trigfn_t_protein_collections_after_update_all();

--
-- Name: t_protein_collections fk_t_protein_collections_t_annotation_types; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_protein_collections
    ADD CONSTRAINT fk_t_protein_collections_t_annotation_types FOREIGN KEY (primary_annotation_type_id) REFERENCES pc.t_annotation_types(annotation_type_id);

--
-- Name: t_protein_collections fk_t_protein_collections_t_protein_collection_states; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_protein_collections
    ADD CONSTRAINT fk_t_protein_collections_t_protein_collection_states FOREIGN KEY (collection_state_id) REFERENCES pc.t_protein_collection_states(collection_state_id);

--
-- Name: t_protein_collections fk_t_protein_collections_t_protein_collection_types; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_protein_collections
    ADD CONSTRAINT fk_t_protein_collections_t_protein_collection_types FOREIGN KEY (collection_type_id) REFERENCES pc.t_protein_collection_types(collection_type_id);

--
-- Name: TABLE t_protein_collections; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_protein_collections TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE pc.t_protein_collections TO writeaccess;

