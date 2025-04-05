--
-- Name: t_analysis_job_request_datasets; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job_request_datasets (
    request_id integer NOT NULL,
    dataset_id integer NOT NULL
);


ALTER TABLE public.t_analysis_job_request_datasets OWNER TO d3l243;

--
-- Name: t_analysis_job_request_datasets pk_t_analysis_job_request_datasets; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_request_datasets
    ADD CONSTRAINT pk_t_analysis_job_request_datasets PRIMARY KEY (request_id, dataset_id);

ALTER TABLE public.t_analysis_job_request_datasets CLUSTER ON pk_t_analysis_job_request_datasets;

--
-- Name: ix_t_analysis_job_request_datasets_dataset_id; Type: INDEX; Schema: public; Owner: d3l243
--

CREATE INDEX ix_t_analysis_job_request_datasets_dataset_id ON public.t_analysis_job_request_datasets USING btree (dataset_id);

--
-- Name: TABLE t_analysis_job_request_datasets; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_request_datasets TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_analysis_job_request_datasets TO writeaccess;

