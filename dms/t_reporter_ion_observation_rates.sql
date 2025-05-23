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
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_reporter_ion_observation_rates OWNER TO d3l243;

--
-- Name: t_reporter_ion_observation_rates pk_t_reporter_ion_observation_rates; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_reporter_ion_observation_rates
    ADD CONSTRAINT pk_t_reporter_ion_observation_rates PRIMARY KEY (job);

ALTER TABLE public.t_reporter_ion_observation_rates CLUSTER ON pk_t_reporter_ion_observation_rates;

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
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_reporter_ion_observation_rates TO writeaccess;

