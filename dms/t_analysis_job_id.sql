--
-- Name: t_analysis_job_id; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job_id (
    job integer NOT NULL,
    note public.citext,
    created timestamp without time zone NOT NULL
);


ALTER TABLE public.t_analysis_job_id OWNER TO d3l243;

--
-- Name: TABLE t_analysis_job_id; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_id TO readaccess;

