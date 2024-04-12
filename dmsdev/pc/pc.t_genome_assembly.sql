--
-- Name: t_genome_assembly; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_genome_assembly (
    assembly_id integer NOT NULL,
    source_file_path public.citext,
    organism_id integer,
    authority_id integer
);


ALTER TABLE pc.t_genome_assembly OWNER TO d3l243;

--
-- Name: t_genome_assembly_assembly_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_genome_assembly ALTER COLUMN assembly_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_genome_assembly_assembly_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_genome_assembly pk_t_genome_assembly; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_genome_assembly
    ADD CONSTRAINT pk_t_genome_assembly PRIMARY KEY (assembly_id);

--
-- Name: t_genome_assembly fk_t_genome_assembly_t_naming_authorities; Type: FK CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_genome_assembly
    ADD CONSTRAINT fk_t_genome_assembly_t_naming_authorities FOREIGN KEY (authority_id) REFERENCES pc.t_naming_authorities(authority_id);

--
-- Name: TABLE t_genome_assembly; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_genome_assembly TO readaccess;
GRANT SELECT ON TABLE pc.t_genome_assembly TO writeaccess;

