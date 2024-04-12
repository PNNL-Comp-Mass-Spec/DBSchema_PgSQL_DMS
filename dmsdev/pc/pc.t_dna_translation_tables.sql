--
-- Name: t_dna_translation_tables; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_dna_translation_tables (
    translation_table_name_id integer NOT NULL,
    translation_table_name public.citext,
    dna_translation_table_id integer
);


ALTER TABLE pc.t_dna_translation_tables OWNER TO d3l243;

--
-- Name: t_dna_translation_tables_translation_table_name_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_dna_translation_tables ALTER COLUMN translation_table_name_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_dna_translation_tables_translation_table_name_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_dna_translation_tables pk_t_dna_translation_tables; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_dna_translation_tables
    ADD CONSTRAINT pk_t_dna_translation_tables PRIMARY KEY (translation_table_name_id);

--
-- Name: t_dna_translation_tables fk_t_dna_translation_tables_t_dna_translation_table_map; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_dna_translation_tables
    ADD CONSTRAINT fk_t_dna_translation_tables_t_dna_translation_table_map FOREIGN KEY (dna_translation_table_id) REFERENCES pc.t_dna_translation_table_map(dna_translation_table_id);

--
-- Name: TABLE t_dna_translation_tables; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_dna_translation_tables TO readaccess;
GRANT SELECT ON TABLE pc.t_dna_translation_tables TO writeaccess;

