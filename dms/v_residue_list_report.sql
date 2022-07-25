--
-- Name: v_residue_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_residue_list_report AS
 SELECT t_residues.residue_id,
    t_residues.residue_symbol AS symbol,
    t_residues.description AS abbreviation,
    t_residues.amino_acid_name AS amino_acid,
    t_residues.monoisotopic_mass,
    t_residues.average_mass,
    t_residues.empirical_formula,
    t_residues.num_c,
    t_residues.num_h,
    t_residues.num_n,
    t_residues.num_o,
    t_residues.num_s
   FROM public.t_residues;


ALTER TABLE public.v_residue_list_report OWNER TO d3l243;

--
-- Name: TABLE v_residue_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_residue_list_report TO readaccess;

