--
-- Name: t_position_info; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_position_info (
    position_id integer NOT NULL,
    protein_id integer,
    start_coordinate integer,
    end_coordinate integer,
    reading_frame_type_id smallint,
    dna_structure_id integer
);


ALTER TABLE pc.t_position_info OWNER TO d3l243;

--
-- Name: t_position_info_position_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_position_info ALTER COLUMN position_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_position_info_position_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_position_info pk_t_position_info; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_position_info
    ADD CONSTRAINT pk_t_position_info PRIMARY KEY (position_id);

--
-- Name: t_position_info fk_t_position_info_t_dna_structures; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_position_info
    ADD CONSTRAINT fk_t_position_info_t_dna_structures FOREIGN KEY (dna_structure_id) REFERENCES pc.t_dna_structures(dna_structure_id);

--
-- Name: t_position_info fk_t_position_info_t_proteins; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_position_info
    ADD CONSTRAINT fk_t_position_info_t_proteins FOREIGN KEY (protein_id) REFERENCES pc.t_proteins(protein_id);

--
-- Name: t_position_info fk_t_position_info_t_reading_frame_types; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_position_info
    ADD CONSTRAINT fk_t_position_info_t_reading_frame_types FOREIGN KEY (reading_frame_type_id) REFERENCES pc.t_reading_frame_types(reading_frame_type_id);

