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
-- Name: ix_t_param_file_mass_mods; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_param_file_mass_mods ON public.t_param_file_mass_mods USING btree (param_file_id, local_symbol_id, residue_id, mass_correction_id);

--
-- Name: t_param_file_mass_mods fk_t_param_file_mass_mods_t_mass_correction_factors; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_param_file_mass_mods
    ADD CONSTRAINT fk_t_param_file_mass_mods_t_mass_correction_factors FOREIGN KEY (mass_correction_id) REFERENCES public.t_mass_correction_factors(mass_correction_id);

--
-- Name: t_param_file_mass_mods fk_t_param_file_mass_mods_t_max_quant_mods; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_param_file_mass_mods
    ADD CONSTRAINT fk_t_param_file_mass_mods_t_max_quant_mods FOREIGN KEY (max_quant_mod_id) REFERENCES public.t_max_quant_mods(mod_id);

--
-- Name: t_param_file_mass_mods fk_t_param_file_mass_mods_t_modification_types; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_param_file_mass_mods
    ADD CONSTRAINT fk_t_param_file_mass_mods_t_modification_types FOREIGN KEY (mod_type_symbol) REFERENCES public.t_modification_types(mod_type_symbol);

--
-- Name: t_param_file_mass_mods fk_t_param_file_mass_mods_t_param_files; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_param_file_mass_mods
    ADD CONSTRAINT fk_t_param_file_mass_mods_t_param_files FOREIGN KEY (param_file_id) REFERENCES public.t_param_files(param_file_id) ON UPDATE CASCADE;

--
-- Name: t_param_file_mass_mods fk_t_param_file_mass_mods_t_residues; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_param_file_mass_mods
    ADD CONSTRAINT fk_t_param_file_mass_mods_t_residues FOREIGN KEY (residue_id) REFERENCES public.t_residues(residue_id);

--
-- Name: t_param_file_mass_mods fk_t_param_file_mass_mods_t_seq_local_symbols_list; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_param_file_mass_mods
    ADD CONSTRAINT fk_t_param_file_mass_mods_t_seq_local_symbols_list FOREIGN KEY (local_symbol_id) REFERENCES public.t_seq_local_symbols_list(local_symbol_id);

--
-- Name: TABLE t_param_file_mass_mods; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_param_file_mass_mods TO readaccess;

