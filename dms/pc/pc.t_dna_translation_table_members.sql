--
-- Name: t_dna_translation_table_members; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_dna_translation_table_members (
    translation_entry_id integer NOT NULL,
    coded_aa character(1),
    start_sequence character(1),
    base_1 character(1),
    base_2 character(1),
    base_3 character(1),
    dna_translation_table_id integer
);


ALTER TABLE pc.t_dna_translation_table_members OWNER TO d3l243;

--
-- Name: t_dna_translation_table_members_translation_entry_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_dna_translation_table_members ALTER COLUMN translation_entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_dna_translation_table_members_translation_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_dna_translation_table_members pk_t_dna_translation_table_members; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_dna_translation_table_members
    ADD CONSTRAINT pk_t_dna_translation_table_members PRIMARY KEY (translation_entry_id);

ALTER TABLE pc.t_dna_translation_table_members CLUSTER ON pk_t_dna_translation_table_members;

--
-- Name: t_dna_translation_table_members fk_t_dna_translation_table_members_t_dna_translation_table_map; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_dna_translation_table_members
    ADD CONSTRAINT fk_t_dna_translation_table_members_t_dna_translation_table_map FOREIGN KEY (dna_translation_table_id) REFERENCES pc.t_dna_translation_table_map(dna_translation_table_id);

--
-- Name: TABLE t_dna_translation_table_members; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_dna_translation_table_members TO readaccess;
GRANT SELECT ON TABLE pc.t_dna_translation_table_members TO writeaccess;

