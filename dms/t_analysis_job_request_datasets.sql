--
-- Name: t_analysis_job_request_datasets; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job_request_datasets (
    request_id integer NOT NULL,
    dataset_id integer NOT NULL
);


ALTER TABLE public.t_analysis_job_request_datasets OWNER TO d3l243;

--
-- Name: TABLE t_analysis_job_request_datasets; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_request_datasets TO readaccess;

