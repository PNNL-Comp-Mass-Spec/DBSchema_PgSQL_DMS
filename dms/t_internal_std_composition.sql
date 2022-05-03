--
-- Name: t_internal_std_composition; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_internal_std_composition (
    mix_id integer NOT NULL,
    component_id integer NOT NULL,
    concentration public.citext
);


ALTER TABLE public.t_internal_std_composition OWNER TO d3l243;

--
-- Name: t_internal_std_composition pk_t_internal_std_composition; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_internal_std_composition
    ADD CONSTRAINT pk_t_internal_std_composition PRIMARY KEY (mix_id, component_id);

--
-- Name: TABLE t_internal_std_composition; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_internal_std_composition TO readaccess;

