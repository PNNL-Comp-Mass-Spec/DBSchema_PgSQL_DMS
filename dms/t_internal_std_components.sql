--
-- Name: t_internal_std_components; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_internal_std_components (
    internal_std_component_id integer NOT NULL,
    name public.citext NOT NULL,
    description public.citext,
    monoisotopic_mass double precision NOT NULL,
    charge_minimum integer,
    charge_maximum integer,
    charge_highest_abu integer,
    expected_ganet double precision
);


ALTER TABLE public.t_internal_std_components OWNER TO d3l243;

--
-- Name: t_internal_std_components pk_t_internal_std_components; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_internal_std_components
    ADD CONSTRAINT pk_t_internal_std_components PRIMARY KEY (internal_std_component_id);

ALTER TABLE public.t_internal_std_components CLUSTER ON pk_t_internal_std_components;

--
-- Name: TABLE t_internal_std_components; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_internal_std_components TO readaccess;
GRANT SELECT ON TABLE public.t_internal_std_components TO writeaccess;

