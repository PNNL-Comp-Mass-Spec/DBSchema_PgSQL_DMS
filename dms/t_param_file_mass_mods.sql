--
-- Name: t_param_file_mass_mods; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_param_file_mass_mods (
    mod_entry_id integer NOT NULL,
    residue_id integer,
    local_symbol_id smallint NOT NULL,
    mass_correction_id integer NOT NULL,
    param_file_id integer,
    mod_type_symbol character(1),
    max_quant_mod_id integer
);


ALTER TABLE public.t_param_file_mass_mods OWNER TO d3l243;

--
-- Name: TABLE t_param_file_mass_mods; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_param_file_mass_mods TO readaccess;

