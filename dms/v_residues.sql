--
-- Name: v_residues; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_residues AS
 SELECT residue_id,
    residue_symbol,
    description,
    average_mass,
    monoisotopic_mass,
    empirical_formula,
    num_c,
    num_h,
    num_n,
    num_o,
    num_s,
    amino_acid_name
   FROM public.t_residues;


ALTER VIEW public.v_residues OWNER TO d3l243;

--
-- Name: TABLE v_residues; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_residues TO readaccess;
GRANT SELECT ON TABLE public.v_residues TO writeaccess;

