--
-- Name: t_default_psm_job_types; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_default_psm_job_types (
    job_type_id integer NOT NULL,
    job_type_name public.citext NOT NULL,
    job_type_description public.citext
);


ALTER TABLE public.t_default_psm_job_types OWNER TO d3l243;

--
-- Name: t_default_psm_job_types pk_t_default_psm_job_types; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_default_psm_job_types
    ADD CONSTRAINT pk_t_default_psm_job_types PRIMARY KEY (job_type_id);

ALTER TABLE public.t_default_psm_job_types CLUSTER ON pk_t_default_psm_job_types;

--
-- Name: ix_t_default_psm_job_types; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_default_psm_job_types ON public.t_default_psm_job_types USING btree (job_type_name);

--
-- Name: TABLE t_default_psm_job_types; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_default_psm_job_types TO readaccess;
GRANT SELECT ON TABLE public.t_default_psm_job_types TO writeaccess;

