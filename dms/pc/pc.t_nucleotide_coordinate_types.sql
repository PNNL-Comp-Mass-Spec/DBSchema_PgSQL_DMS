--
-- Name: t_nucleotide_coordinate_types; Type: TABLE; Schema: pc; Owner: d3l243
--

CREATE TABLE pc.t_nucleotide_coordinate_types (
    coordinate_type_id integer NOT NULL,
    name public.citext,
    description public.citext
);


ALTER TABLE pc.t_nucleotide_coordinate_types OWNER TO d3l243;

--
-- Name: t_nucleotide_coordinate_types pk_t_nucleotide_coordinate_types; Type: CONSTRAINT; Schema: pc; Owner: d3l243
--

ALTER TABLE ONLY pc.t_nucleotide_coordinate_types
    ADD CONSTRAINT pk_t_nucleotide_coordinate_types PRIMARY KEY (coordinate_type_id);

--
-- Name: TABLE t_nucleotide_coordinate_types; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.t_nucleotide_coordinate_types TO readaccess;

