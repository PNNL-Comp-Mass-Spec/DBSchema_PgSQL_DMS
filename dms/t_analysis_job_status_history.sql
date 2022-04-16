--
-- Name: t_analysis_job_status_history; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job_status_history (
    entry_id integer NOT NULL,
    posting_time timestamp without time zone NOT NULL,
    tool_id integer NOT NULL,
    state_id integer NOT NULL,
    job_count integer NOT NULL
);


ALTER TABLE public.t_analysis_job_status_history OWNER TO d3l243;

--
-- Name: TABLE t_analysis_job_status_history; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_status_history TO readaccess;

