--
-- Name: t_analysis_job_processor_group_membership; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job_processor_group_membership (
    processor_id integer NOT NULL,
    group_id integer NOT NULL,
    membership_enabled public.citext DEFAULT 'Y'::bpchar NOT NULL,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    entered_by public.citext DEFAULT SESSION_USER,
    CONSTRAINT ck_t_analysis_job_processor_group_membership_enabled CHECK (((membership_enabled OPERATOR(public.=) 'N'::public.citext) OR (membership_enabled OPERATOR(public.=) 'Y'::public.citext)))
);


ALTER TABLE public.t_analysis_job_processor_group_membership OWNER TO d3l243;

--
-- Name: t_analysis_job_processor_group_membership pk_t_analysis_job_processor_group_membership; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_processor_group_membership
    ADD CONSTRAINT pk_t_analysis_job_processor_group_membership PRIMARY KEY (processor_id, group_id);

--
-- Name: ix_t_analysis_job_processor_group_membership_group_id_enabled; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_analysis_job_processor_group_membership_group_id_enabled ON public.t_analysis_job_processor_group_membership USING btree (group_id, membership_enabled);

--
-- Name: t_analysis_job_processor_group_membership trig_t_analysis_job_processor_group_membership_after_update; Type: TRIGGER; Schema: public; Owner: d3l243
--

CREATE TRIGGER trig_t_analysis_job_processor_group_membership_after_update AFTER UPDATE ON public.t_analysis_job_processor_group_membership FOR EACH ROW WHEN (((old.processor_id <> new.processor_id) OR (old.group_id <> new.group_id) OR (old.membership_enabled OPERATOR(public.<>) new.membership_enabled))) EXECUTE FUNCTION public.trigfn_t_analysis_job_processor_group_membership_after_update();

--
-- Name: t_analysis_job_processor_group_membership fk_t_analysis_job_processor_group_t_analysis_job_processor; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_processor_group_membership
    ADD CONSTRAINT fk_t_analysis_job_processor_group_t_analysis_job_processor FOREIGN KEY (group_id) REFERENCES public.t_analysis_job_processor_group(group_id);

--
-- Name: t_analysis_job_processor_group_membership fk_t_analysis_job_processors_t_analysis_job_processor_group; Type: FK CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_processor_group_membership
    ADD CONSTRAINT fk_t_analysis_job_processors_t_analysis_job_processor_group FOREIGN KEY (processor_id) REFERENCES public.t_analysis_job_processors(processor_id) ON DELETE CASCADE;

--
-- Name: TABLE t_analysis_job_processor_group_membership; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_processor_group_membership TO readaccess;
GRANT SELECT ON TABLE public.t_analysis_job_processor_group_membership TO writeaccess;

