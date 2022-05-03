--
-- Name: t_analysis_job_processor_group_membership; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job_processor_group_membership (
    processor_id integer NOT NULL,
    group_id integer NOT NULL,
    membership_enabled character(1) NOT NULL,
    last_affected timestamp without time zone,
    entered_by public.citext
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
-- Name: TABLE t_analysis_job_processor_group_membership; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_processor_group_membership TO readaccess;

