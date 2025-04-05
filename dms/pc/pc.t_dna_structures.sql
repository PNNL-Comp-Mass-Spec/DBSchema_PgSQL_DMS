--
-- Name: t_dna_structures; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_dna_structures (
    dna_structure_id integer NOT NULL,
    name public.citext,
    description public.citext,
    dna_structure_type_id integer,
    dna_translation_table_id integer,
    assembly_id integer
);


ALTER TABLE pc.t_dna_structures OWNER TO d3l243;

--
-- Name: t_dna_structures_dna_structure_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_dna_structures ALTER COLUMN dna_structure_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_dna_structures_dna_structure_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_dna_structures pk_t_dna_structures; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_dna_structures
    ADD CONSTRAINT pk_t_dna_structures PRIMARY KEY (dna_structure_id);

ALTER TABLE pc.t_dna_structures CLUSTER ON pk_t_dna_structures;

--
-- Name: t_dna_structures fk_t_dna_structures_t_dna_structure_types; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_dna_structures
    ADD CONSTRAINT fk_t_dna_structures_t_dna_structure_types FOREIGN KEY (dna_structure_type_id) REFERENCES pc.t_dna_structure_types(dna_structure_type_id);

--
-- Name: t_dna_structures fk_t_dna_structures_t_dna_translation_table_map; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_dna_structures
    ADD CONSTRAINT fk_t_dna_structures_t_dna_translation_table_map FOREIGN KEY (dna_translation_table_id) REFERENCES pc.t_dna_translation_table_map(dna_translation_table_id);

--
-- Name: t_dna_structures fk_t_dna_structures_t_genome_assembly; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_dna_structures
    ADD CONSTRAINT fk_t_dna_structures_t_genome_assembly FOREIGN KEY (assembly_id) REFERENCES pc.t_genome_assembly(assembly_id);

--
-- Name: TABLE t_dna_structures; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_dna_structures TO readaccess;
GRANT SELECT ON TABLE pc.t_dna_structures TO writeaccess;

