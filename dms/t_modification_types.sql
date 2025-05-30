--
-- Name: t_modification_types; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_modification_types (
    mod_type_symbol character(1) NOT NULL,
    description public.citext,
    mod_type_synonym public.citext
);


ALTER TABLE public.t_modification_types OWNER TO d3l243;

--
-- Name: t_modification_types pk_t_modification_types; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_modification_types
    ADD CONSTRAINT pk_t_modification_types PRIMARY KEY (mod_type_symbol);

ALTER TABLE public.t_modification_types CLUSTER ON pk_t_modification_types;

--
-- Name: TABLE t_modification_types; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_modification_types TO readaccess;
GRANT SELECT ON TABLE public.t_modification_types TO writeaccess;

