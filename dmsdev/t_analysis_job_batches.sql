--
-- Name: t_analysis_job_batches; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job_batches (
    batch_id integer NOT NULL,
    batch_created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    batch_description public.citext
);


ALTER TABLE public.t_analysis_job_batches OWNER TO d3l243;

--
-- Name: t_analysis_job_batches_batch_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_analysis_job_batches ALTER COLUMN batch_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_analysis_job_batches_batch_id_seq
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_analysis_job_batches pk_t_analysis_job_batches; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_batches
    ADD CONSTRAINT pk_t_analysis_job_batches PRIMARY KEY (batch_id);

--
-- Name: TABLE t_analysis_job_batches; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_batches TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_analysis_job_batches TO writeaccess;

