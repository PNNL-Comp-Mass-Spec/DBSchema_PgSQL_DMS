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
-- Name: t_param_file_mass_mods_mod_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_param_file_mass_mods ALTER COLUMN mod_entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_param_file_mass_mods_mod_entry_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_param_file_mass_mods pk_t_peptide_mod_param_file_list_ex; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_param_file_mass_mods
    ADD CONSTRAINT pk_t_peptide_mod_param_file_list_ex PRIMARY KEY (mod_entry_id);

--
-- Name: TABLE t_param_file_mass_mods; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_param_file_mass_mods TO readaccess;

