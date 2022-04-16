--
-- Name: t_analysis_job_processors; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job_processors (
    processor_id integer NOT NULL,
    state character(1) NOT NULL,
    processor_name public.citext NOT NULL,
    machine public.citext NOT NULL,
    notes public.citext,
    last_affected timestamp without time zone,
    entered_by public.citext
);


ALTER TABLE public.t_analysis_job_processors OWNER TO d3l243;

--
-- Name: TABLE t_analysis_job_processors; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_processors TO readaccess;

