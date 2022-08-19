--
-- Name: t_dna_translation_table_map; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_dna_translation_table_map (
    dna_translation_table_id integer NOT NULL
);


ALTER TABLE pc.t_dna_translation_table_map OWNER TO d3l243;

--
-- Name: t_dna_translation_table_map pk_t_dna_translation_table_map; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_dna_translation_table_map
    ADD CONSTRAINT pk_t_dna_translation_table_map PRIMARY KEY (dna_translation_table_id);

--
-- Name: TABLE t_dna_translation_table_map; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_dna_translation_table_map TO readaccess;

