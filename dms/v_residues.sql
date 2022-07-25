--
-- Name: v_residues; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_residues AS
 SELECT t_residues.residue_id,
    t_residues.residue_symbol,
    t_residues.description,
    t_residues.average_mass,
    t_residues.monoisotopic_mass,
    t_residues.empirical_formula,
    t_residues.num_c,
    t_residues.num_h,
    t_residues.num_n,
    t_residues.num_o,
    t_residues.num_s,
    t_residues.amino_acid_name
   FROM public.t_residues;


ALTER TABLE public.v_residues OWNER TO d3l243;

--
-- Name: TABLE v_residues; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_residues TO readaccess;

