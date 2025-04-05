--
-- Name: t_dna_structure_types; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_dna_structure_types (
    dna_structure_type_id integer NOT NULL,
    name public.citext,
    description public.citext
);


ALTER TABLE pc.t_dna_structure_types OWNER TO d3l243;

--
-- Name: t_dna_structure_types_dna_structure_type_id_seq; Type: SEQUENCE; Schema: pc; Owner: d3l243
--

ALTER TABLE pc.t_dna_structure_types ALTER COLUMN dna_structure_type_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME pc.t_dna_structure_types_dna_structure_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_dna_structure_types pk_t_dna_structure_types; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_dna_structure_types
    ADD CONSTRAINT pk_t_dna_structure_types PRIMARY KEY (dna_structure_type_id);

ALTER TABLE pc.t_dna_structure_types CLUSTER ON pk_t_dna_structure_types;

--
-- Name: TABLE t_dna_structure_types; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_dna_structure_types TO readaccess;
GRANT SELECT ON TABLE pc.t_dna_structure_types TO writeaccess;

