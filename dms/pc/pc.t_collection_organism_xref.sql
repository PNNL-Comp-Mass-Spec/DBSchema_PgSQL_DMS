--
-- Name: t_collection_organism_xref; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_collection_organism_xref (
    id integer NOT NULL,
    protein_collection_id integer NOT NULL,
    organism_id integer NOT NULL
);


ALTER TABLE pc.t_collection_organism_xref OWNER TO d3l243;

--
-- Name: t_collection_organism_xref_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_collection_organism_xref ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_collection_organism_xref_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_collection_organism_xref pk_t_collection_organism_xref; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_collection_organism_xref
    ADD CONSTRAINT pk_t_collection_organism_xref PRIMARY KEY (id);

--
-- Name: ix_t_collection_organism_xref_prot_collection_id_organism_id; Type: INDEX; Schema: pc; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_collection_organism_xref_prot_collection_id_organism_id ON pc.t_collection_organism_xref USING btree (protein_collection_id, organism_id);

--
-- Name: t_collection_organism_xref fk_t_collection_organism_xref_t_organisms; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_collection_organism_xref
    ADD CONSTRAINT fk_t_collection_organism_xref_t_organisms FOREIGN KEY (organism_id) REFERENCES public.t_organisms(organism_id);

--
-- Name: TABLE t_collection_organism_xref; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_collection_organism_xref TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE pc.t_collection_organism_xref TO writeaccess;

