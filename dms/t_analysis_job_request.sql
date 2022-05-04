--
-- Name: t_analysis_job_request; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job_request (
    request_id integer NOT NULL,
    request_name public.citext NOT NULL,
    created timestamp without time zone NOT NULL,
    analysis_tool public.citext NOT NULL,
    param_file_name public.citext NOT NULL,
    settings_file_name public.citext,
    organism_db_name public.citext,
    organism_id integer NOT NULL,
    datasets public.citext,
    user_id integer NOT NULL,
    comment public.citext,
    request_state_id integer DEFAULT 0 NOT NULL,
    protein_collection_list public.citext DEFAULT 'na'::public.citext NOT NULL,
    protein_options_list public.citext DEFAULT 'na'::public.citext NOT NULL,
    work_package public.citext,
    job_count integer DEFAULT 0,
    special_processing public.citext,
    dataset_min public.citext,
    dataset_max public.citext,
    data_package_id integer
);


ALTER TABLE public.t_analysis_job_request OWNER TO d3l243;

--
-- Name: t_analysis_job_request pk_t_analysis_job_request; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_request
    ADD CONSTRAINT pk_t_analysis_job_request PRIMARY KEY (request_id);

--
-- Name: ix_t_analysis_job_request_name; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE UNIQUE INDEX ix_t_analysis_job_request_name ON public.t_analysis_job_request USING btree (request_name);

--
-- Name: ix_t_analysis_job_request_request_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_analysis_job_request_request_id ON public.t_analysis_job_request USING btree (request_id) INCLUDE (work_package);

--
-- Name: ix_t_analysis_job_request_state_created; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_analysis_job_request_state_created ON public.t_analysis_job_request USING btree (request_state_id, created);

--
-- Name: TABLE t_analysis_job_request; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_request TO readaccess;

