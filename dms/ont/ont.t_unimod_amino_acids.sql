--
-- Name: t_unimod_amino_acids; Type: TABLE; Schema: ont; Owner: d3l243
--

CREATE TABLE ont.t_unimod_amino_acids (
    name public.citext NOT NULL,
    full_name public.citext,
    mono_mass real NOT NULL,
    avg_mass real NOT NULL,
    composition public.citext,
    three_letter public.citext
);


ALTER TABLE ont.t_unimod_amino_acids OWNER TO d3l243;

--
-- Name: t_unimod_amino_acids pk_t_unimod_amino_acids; Type: CONSTRAINT; Schema: ont; Owner: d3l243
--

ALTER TABLE ONLY ont.t_unimod_amino_acids
    ADD CONSTRAINT pk_t_unimod_amino_acids PRIMARY KEY (name);

--
-- Name: TABLE t_unimod_amino_acids; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.t_unimod_amino_acids TO readaccess;

