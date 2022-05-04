--
-- Name: t_sample_labelling_reporter_ions; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_sample_labelling_reporter_ions (
    label public.citext NOT NULL,
    channel smallint NOT NULL,
    tag_name public.citext NOT NULL,
    masic_name public.citext,
    reporter_ion_mz double precision
);


ALTER TABLE public.t_sample_labelling_reporter_ions OWNER TO d3l243;

--
-- Name: t_sample_labelling_reporter_ions pk_t_sample_labelling_reporter_ions; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_sample_labelling_reporter_ions
    ADD CONSTRAINT pk_t_sample_labelling_reporter_ions PRIMARY KEY (label, channel);

--
-- Name: t_sample_labelling_reporter_ions fk_t_sample_labelling_reporter_ions_t_sample_labelling; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_sample_labelling_reporter_ions
    ADD CONSTRAINT fk_t_sample_labelling_reporter_ions_t_sample_labelling FOREIGN KEY (label) REFERENCES public.t_sample_labelling(label);

--
-- Name: TABLE t_sample_labelling_reporter_ions; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_sample_labelling_reporter_ions TO readaccess;

