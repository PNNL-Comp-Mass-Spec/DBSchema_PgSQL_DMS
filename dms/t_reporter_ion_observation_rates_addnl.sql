--
-- Name: t_reporter_ion_observation_rates_addnl; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_reporter_ion_observation_rates_addnl (
    job integer NOT NULL,
    dataset_id integer NOT NULL,
    reporter_ion public.citext NOT NULL,
    top_n_pct integer NOT NULL,
    channel19 real,
    channel20 real,
    channel21 real,
    channel22 real,
    channel23 real,
    channel24 real,
    channel25 real,
    channel26 real,
    channel27 real,
    channel28 real,
    channel29 real,
    channel30 real,
    channel31 real,
    channel32 real,
    channel33 real,
    channel34 real,
    channel35 real,
    channel19_median_intensity integer,
    channel20_median_intensity integer,
    channel21_median_intensity integer,
    channel22_median_intensity integer,
    channel23_median_intensity integer,
    channel24_median_intensity integer,
    channel25_median_intensity integer,
    channel26_median_intensity integer,
    channel27_median_intensity integer,
    channel28_median_intensity integer,
    channel29_median_intensity integer,
    channel30_median_intensity integer,
    channel31_median_intensity integer,
    channel32_median_intensity integer,
    channel33_median_intensity integer,
    channel34_median_intensity integer,
    channel35_median_intensity integer,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_reporter_ion_observation_rates_addnl OWNER TO d3l243;

--
-- Name: t_reporter_ion_observation_rates_addnl pk_t_reporter_ion_observation_rates_addnl; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_reporter_ion_observation_rates_addnl
    ADD CONSTRAINT pk_t_reporter_ion_observation_rates_addnl PRIMARY KEY (job);

--
-- Name: t_reporter_ion_observation_rates_addnl fk_t_reporter_ion_observation_rates_addnl_t_analysis_job; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_reporter_ion_observation_rates_addnl
    ADD CONSTRAINT fk_t_reporter_ion_observation_rates_addnl_t_analysis_job FOREIGN KEY (job) REFERENCES public.t_analysis_job(job);

--
-- Name: t_reporter_ion_observation_rates_addnl fk_t_reporter_ion_observation_rates_addnl_t_sample_labelling; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_reporter_ion_observation_rates_addnl
    ADD CONSTRAINT fk_t_reporter_ion_observation_rates_addnl_t_sample_labelling FOREIGN KEY (reporter_ion) REFERENCES public.t_sample_labelling(label) ON UPDATE CASCADE;

--
-- Name: TABLE t_reporter_ion_observation_rates_addnl; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_reporter_ion_observation_rates_addnl TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_reporter_ion_observation_rates_addnl TO writeaccess;

