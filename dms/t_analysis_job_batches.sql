--
-- Name: t_analysis_job_batches; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job_batches (
    batch_id integer NOT NULL,
    batch_created timestamp without time zone NOT NULL,
    batch_description public.citext
);


ALTER TABLE public.t_analysis_job_batches OWNER TO d3l243;

--
-- Name: TABLE t_analysis_job_batches; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_batches TO readaccess;

