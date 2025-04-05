--
-- Name: t_internal_std_composition; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_internal_std_composition (
    mix_id integer NOT NULL,
    component_id integer NOT NULL,
    concentration public.citext DEFAULT ''::public.citext
);


ALTER TABLE public.t_internal_std_composition OWNER TO d3l243;

--
-- Name: t_internal_std_composition pk_t_internal_std_composition; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_internal_std_composition
    ADD CONSTRAINT pk_t_internal_std_composition PRIMARY KEY (mix_id, component_id);

ALTER TABLE public.t_internal_std_composition CLUSTER ON pk_t_internal_std_composition;

--
-- Name: t_internal_std_composition fk_t_internal_standards_composition_t_internal_std_components; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_internal_std_composition
    ADD CONSTRAINT fk_t_internal_standards_composition_t_internal_std_components FOREIGN KEY (component_id) REFERENCES public.t_internal_std_components(internal_std_component_id);

--
-- Name: t_internal_std_composition fk_t_internal_std_composition_t_internal_std_parent_mixes; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_internal_std_composition
    ADD CONSTRAINT fk_t_internal_std_composition_t_internal_std_parent_mixes FOREIGN KEY (mix_id) REFERENCES public.t_internal_std_parent_mixes(parent_mix_id);

--
-- Name: TABLE t_internal_std_composition; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_internal_std_composition TO readaccess;
GRANT SELECT ON TABLE public.t_internal_std_composition TO writeaccess;

