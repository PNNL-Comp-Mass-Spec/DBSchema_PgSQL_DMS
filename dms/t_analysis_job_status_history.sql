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
-- Name: t_analysis_job_status_history_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: d3l243
--

ALTER TABLE public.t_analysis_job_status_history ALTER COLUMN entry_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.t_analysis_job_status_history_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

--
-- Name: t_analysis_job_status_history pk_t_analysis_job_status_history; Type: CONSTRAINT; Schema: public; Owner: d3l243
--

ALTER TABLE ONLY public.t_analysis_job_status_history
    ADD CONSTRAINT pk_t_analysis_job_status_history PRIMARY KEY (entry_id);

--
-- Name: TABLE t_analysis_job_status_history; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_status_history TO readaccess;

