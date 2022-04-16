--
-- Name: t_max_quant_mod_residues; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_max_quant_mod_residues (
    mod_id integer NOT NULL,
    residue_id integer NOT NULL
);


ALTER TABLE public.t_max_quant_mod_residues OWNER TO d3l243;

--
-- Name: TABLE t_max_quant_mod_residues; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_max_quant_mod_residues TO readaccess;

