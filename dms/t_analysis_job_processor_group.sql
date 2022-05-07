--
-- Name: t_analysis_job_processor_group; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job_processor_group (
    group_id integer NOT NULL,
    group_name public.citext NOT NULL,
    group_description public.citext,
    group_enabled character(1) DEFAULT 'Y'::bpchar NOT NULL,
    group_created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_affected timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    entered_by public.citext DEFAULT SESSION_USER
);


ALTER TABLE public.t_analysis_job_processor_group OWNER TO d3l243;

--
-- Name: t_analysis_job_processor_group ix_t_analysis_job_processor_group_unique_group_name; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_processor_group
    ADD CONSTRAINT ix_t_analysis_job_processor_group_unique_group_name UNIQUE (group_name);

--
-- Name: t_analysis_job_processor_group pk_t_analysis_job_processor_group; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_processor_group
    ADD CONSTRAINT pk_t_analysis_job_processor_group PRIMARY KEY (group_id);

--
-- Name: TABLE t_analysis_job_processor_group; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_processor_group TO readaccess;

