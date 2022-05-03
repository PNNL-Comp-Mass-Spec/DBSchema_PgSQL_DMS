--
-- Name: t_experiment_biomaterial; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_experiment_biomaterial (
    exp_id integer NOT NULL,
    biomaterial_id integer NOT NULL
);


ALTER TABLE public.t_experiment_biomaterial OWNER TO d3l243;

--
-- Name: t_experiment_biomaterial pk_t_experiment_biomaterial; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_experiment_biomaterial
    ADD CONSTRAINT pk_t_experiment_biomaterial PRIMARY KEY (exp_id, biomaterial_id);

--
-- Name: TABLE t_experiment_biomaterial; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_experiment_biomaterial TO readaccess;

