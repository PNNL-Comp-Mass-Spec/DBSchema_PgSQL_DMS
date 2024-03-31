--
-- Name: v_residue_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_residue_list_report AS
 SELECT residue_id,
    residue_symbol AS symbol,
    description AS abbreviation,
    amino_acid_name AS amino_acid,
    monoisotopic_mass,
    average_mass,
    empirical_formula,
    num_c,
    num_h,
    num_n,
    num_o,
    num_s
   FROM public.t_residues;


ALTER VIEW public.v_residue_list_report OWNER TO d3l243;

--
-- Name: TABLE v_residue_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_residue_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_residue_list_report TO writeaccess;

