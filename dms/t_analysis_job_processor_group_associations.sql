--
-- Name: t_analysis_job_processor_group_associations; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job_processor_group_associations (
    job integer NOT NULL,
    group_id integer NOT NULL,
    entered timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE public.t_analysis_job_processor_group_associations OWNER TO d3l243;

--
-- Name: t_analysis_job_processor_group_group_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_analysis_job_processor_group ALTER COLUMN group_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_analysis_job_processor_group_group_id_seq
    START WITH 100
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_analysis_job_processor_group_associations pk_t_analysis_job_processor_group_associations; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_processor_group_associations
    ADD CONSTRAINT pk_t_analysis_job_processor_group_associations PRIMARY KEY (job, group_id);

--
-- Name: ix_t_analysis_job_processor_group_associations_group_id_job; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_analysis_job_processor_group_associations_group_id_job ON public.t_analysis_job_processor_group_associations USING btree (group_id) INCLUDE (job);

--
-- Name: t_analysis_job_processor_group_associations fk_t_analysis_job_processor_group_associations_t_analysis_job1; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_processor_group_associations
    ADD CONSTRAINT fk_t_analysis_job_processor_group_associations_t_analysis_job1 FOREIGN KEY (job) REFERENCES public.t_analysis_job(job) ON DELETE CASCADE;

--
-- Name: t_analysis_job_processor_group_associations fk_t_analysis_job_processor_group_associations_t_analysis_job2; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_processor_group_associations
    ADD CONSTRAINT fk_t_analysis_job_processor_group_associations_t_analysis_job2 FOREIGN KEY (group_id) REFERENCES public.t_analysis_job_processor_group(group_id);

--
-- Name: TABLE t_analysis_job_processor_group_associations; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_processor_group_associations TO readaccess;

