--
-- Name: t_analysis_job_id; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job_id (
    job integer NOT NULL,
    note public.citext,
    created timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.t_analysis_job_id OWNER TO d3l243;

--
-- Name: t_analysis_job_id_job_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_analysis_job_id ALTER COLUMN job ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_analysis_job_id_job_seq
    START WITH 522434
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_analysis_job_id pk_t_analysis_job_id; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_id
    ADD CONSTRAINT pk_t_analysis_job_id PRIMARY KEY (job);

ALTER TABLE public.t_analysis_job_id CLUSTER ON pk_t_analysis_job_id;

--
-- Name: TABLE t_analysis_job_id; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_id TO readaccess;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.t_analysis_job_id TO writeaccess;

