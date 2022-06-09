--
-- Name: t_prep_lc_run_dataset; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_prep_lc_run_dataset (
    prep_lc_run_id integer NOT NULL,
    dataset_id integer NOT NULL
);


ALTER TABLE public.t_prep_lc_run_dataset OWNER TO d3l243;

--
-- Name: t_prep_lc_run_dataset pk_t_prep_lc_run_dataset; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_prep_lc_run_dataset
    ADD CONSTRAINT pk_t_prep_lc_run_dataset PRIMARY KEY (prep_lc_run_id, dataset_id);

--
-- Name: t_prep_lc_run_dataset fk_t_prep_lc_run_dataset_t_dataset; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_prep_lc_run_dataset
    ADD CONSTRAINT fk_t_prep_lc_run_dataset_t_dataset FOREIGN KEY (dataset_id) REFERENCES public.t_dataset(dataset_id);

--
-- Name: t_prep_lc_run_dataset fk_t_prep_lc_run_dataset_t_prep_lc_run; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_prep_lc_run_dataset
    ADD CONSTRAINT fk_t_prep_lc_run_dataset_t_prep_lc_run FOREIGN KEY (prep_lc_run_id) REFERENCES public.t_prep_lc_run(prep_run_id);

--
-- Name: TABLE t_prep_lc_run_dataset; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_prep_lc_run_dataset TO readaccess;

