--
-- Name: t_instrument_ops_role; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_instrument_ops_role (
    role public.citext NOT NULL,
    description public.citext
);


ALTER TABLE public.t_instrument_ops_role OWNER TO d3l243;

--
-- Name: t_instrument_ops_role pk_t_instrument_ops_role; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_instrument_ops_role
    ADD CONSTRAINT pk_t_instrument_ops_role PRIMARY KEY (role);

--
-- Name: TABLE t_instrument_ops_role; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_instrument_ops_role TO readaccess;
GRANT SELECT ON TABLE public.t_instrument_ops_role TO writeaccess;

