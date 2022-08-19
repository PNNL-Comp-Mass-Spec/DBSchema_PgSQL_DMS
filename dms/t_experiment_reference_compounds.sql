--
-- Name: t_experiment_reference_compounds; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_experiment_reference_compounds (
    exp_id integer NOT NULL,
    compound_id integer NOT NULL
);


ALTER TABLE public.t_experiment_reference_compounds OWNER TO d3l243;

--
-- Name: t_experiment_reference_compounds pk_t_experiment_reference_compounds; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_experiment_reference_compounds
    ADD CONSTRAINT pk_t_experiment_reference_compounds PRIMARY KEY (exp_id, compound_id);

--
-- Name: t_experiment_reference_compounds fk_t_experiment_reference_compounds_t_experiments; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_experiment_reference_compounds
    ADD CONSTRAINT fk_t_experiment_reference_compounds_t_experiments FOREIGN KEY (exp_id) REFERENCES public.t_experiments(exp_id);

--
-- Name: t_experiment_reference_compounds fk_t_experiment_reference_compounds_t_reference_compound; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_experiment_reference_compounds
    ADD CONSTRAINT fk_t_experiment_reference_compounds_t_reference_compound FOREIGN KEY (compound_id) REFERENCES public.t_reference_compound(compound_id);

--
-- Name: TABLE t_experiment_reference_compounds; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_experiment_reference_compounds TO readaccess;
GRANT SELECT ON TABLE public.t_experiment_reference_compounds TO writeaccess;

