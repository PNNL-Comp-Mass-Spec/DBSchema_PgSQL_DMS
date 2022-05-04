--
-- Name: t_reporter_ion_observation_rates; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_reporter_ion_observation_rates (
    job integer NOT NULL,
    dataset_id integer NOT NULL,
    reporter_ion public.citext NOT NULL,
    top_n_pct integer NOT NULL,
    channel1 real,
    channel2 real,
    channel3 real,
    channel4 real,
    channel5 real,
    channel6 real,
    channel7 real,
    channel8 real,
    channel9 real,
    channel10 real,
    channel11 real,
    channel12 real,
    channel13 real,
    channel14 real,
    channel15 real,
    channel16 real,
    channel17 real,
    channel18 real,
    channel1_all real,
    channel2_all real,
    channel3_all real,
    channel4_all real,
    channel5_all real,
    channel6_all real,
    channel7_all real,
    channel8_all real,
    channel9_all real,
    channel10_all real,
    channel11_all real,
    channel12_all real,
    channel13_all real,
    channel14_all real,
    channel15_all real,
    channel16_all real,
    channel17_all real,
    channel18_all real,
    channel1_median_intensity integer,
    channel2_median_intensity integer,
    channel3_median_intensity integer,
    channel4_median_intensity integer,
    channel5_median_intensity integer,
    channel6_median_intensity integer,
    channel7_median_intensity integer,
    channel8_median_intensity integer,
    channel9_median_intensity integer,
    channel10_median_intensity integer,
    channel11_median_intensity integer,
    channel12_median_intensity integer,
    channel13_median_intensity integer,
    channel14_median_intensity integer,
    channel15_median_intensity integer,
    channel16_median_intensity integer,
    channel17_median_intensity integer,
    channel18_median_intensity integer,
    entered timestamp without time zone NOT NULL
);


ALTER TABLE public.t_reporter_ion_observation_rates OWNER TO d3l243;

--
-- Name: t_reporter_ion_observation_rates pk_t_reporter_ion_observation_rates; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_reporter_ion_observation_rates
    ADD CONSTRAINT pk_t_reporter_ion_observation_rates PRIMARY KEY (job);

--
-- Name: t_reporter_ion_observation_rates fk_t_reporter_ion_observation_rates_t_analysis_job; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_reporter_ion_observation_rates
    ADD CONSTRAINT fk_t_reporter_ion_observation_rates_t_analysis_job FOREIGN KEY (job) REFERENCES public.t_analysis_job(job);

--
-- Name: t_reporter_ion_observation_rates fk_t_reporter_ion_observation_rates_t_sample_labelling; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_reporter_ion_observation_rates
    ADD CONSTRAINT fk_t_reporter_ion_observation_rates_t_sample_labelling FOREIGN KEY (reporter_ion) REFERENCES public.t_sample_labelling(label) ON UPDATE CASCADE;

--
-- Name: TABLE t_reporter_ion_observation_rates; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_reporter_ion_observation_rates TO readaccess;

