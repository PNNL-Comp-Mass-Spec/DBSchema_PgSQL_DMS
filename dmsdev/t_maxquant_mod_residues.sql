--
-- Name: t_maxquant_mod_residues; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_maxquant_mod_residues (
    mod_id integer NOT NULL,
    residue_id integer NOT NULL
);


ALTER TABLE public.t_maxquant_mod_residues OWNER TO d3l243;

--
-- Name: t_maxquant_mod_residues pk_t_maxquant_mod_residues; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_maxquant_mod_residues
    ADD CONSTRAINT pk_t_maxquant_mod_residues PRIMARY KEY (mod_id, residue_id);

--
-- Name: t_maxquant_mod_residues fk_t_maxquant_mod_residues_t_maxquant_mods; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_maxquant_mod_residues
    ADD CONSTRAINT fk_t_maxquant_mod_residues_t_maxquant_mods FOREIGN KEY (mod_id) REFERENCES public.t_maxquant_mods(mod_id);

--
-- Name: TABLE t_maxquant_mod_residues; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_maxquant_mod_residues TO readaccess;
GRANT SELECT ON TABLE public.t_maxquant_mod_residues TO writeaccess;

