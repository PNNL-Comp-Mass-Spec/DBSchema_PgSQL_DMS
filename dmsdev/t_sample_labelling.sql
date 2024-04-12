--
-- Name: t_sample_labelling; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_sample_labelling (
    label_id integer NOT NULL,
    label public.citext NOT NULL,
    reporter_mz_min double precision,
    reporter_mz_max double precision
);


ALTER TABLE public.t_sample_labelling OWNER TO d3l243;

--
-- Name: t_sample_labelling pk_t_sample_labelling; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_sample_labelling
    ADD CONSTRAINT pk_t_sample_labelling PRIMARY KEY (label_id);

--
-- Name: ix_t_sample_labelling; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_sample_labelling ON public.t_sample_labelling USING btree (label);

--
-- Name: TABLE t_sample_labelling; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_sample_labelling TO readaccess;
GRANT SELECT ON TABLE public.t_sample_labelling TO writeaccess;

