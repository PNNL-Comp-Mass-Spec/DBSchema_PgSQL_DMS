--
-- Name: t_biomaterial_organisms; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_biomaterial_organisms (
    organism_id integer NOT NULL,
    biomaterial_id integer NOT NULL
);


ALTER TABLE public.t_biomaterial_organisms OWNER TO d3l243;

--
-- Name: t_biomaterial_organisms pk_t_biomaterial_organisms; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_biomaterial_organisms
    ADD CONSTRAINT pk_t_biomaterial_organisms PRIMARY KEY (organism_id, biomaterial_id);

--
-- Name: t_biomaterial_organisms fk_t_biomaterial_organisms_t_biomaterial; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_biomaterial_organisms
    ADD CONSTRAINT fk_t_biomaterial_organisms_t_biomaterial FOREIGN KEY (biomaterial_id) REFERENCES public.t_biomaterial(biomaterial_id);

--
-- Name: t_biomaterial_organisms fk_t_biomaterial_organisms_t_organisms; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_biomaterial_organisms
    ADD CONSTRAINT fk_t_biomaterial_organisms_t_organisms FOREIGN KEY (organism_id) REFERENCES public.t_organisms(organism_id);

--
-- Name: TABLE t_biomaterial_organisms; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_biomaterial_organisms TO readaccess;
GRANT SELECT ON TABLE public.t_biomaterial_organisms TO writeaccess;

