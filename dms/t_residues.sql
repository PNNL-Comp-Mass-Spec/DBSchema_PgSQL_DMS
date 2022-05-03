--
-- Name: t_residues; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_residues (
    residue_id integer NOT NULL,
    residue_symbol character(1) NOT NULL,
    description public.citext NOT NULL,
    abbreviation public.citext NOT NULL,
    average_mass double precision NOT NULL,
    monoisotopic_mass double precision NOT NULL,
    num_c smallint NOT NULL,
    num_h smallint NOT NULL,
    num_n smallint NOT NULL,
    num_o smallint NOT NULL,
    num_s smallint NOT NULL,
    empirical_formula public.citext,
    amino_acid_name public.citext
);


ALTER TABLE public.t_residues OWNER TO d3l243;

--
-- Name: t_residues pk_t_residues; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_residues
    ADD CONSTRAINT pk_t_residues PRIMARY KEY (residue_id);

--
-- Name: TABLE t_residues; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_residues TO readaccess;

