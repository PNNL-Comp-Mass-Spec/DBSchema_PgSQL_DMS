--
-- Name: t_analysis_job_processor_group; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_analysis_job_processor_group (
    group_id integer NOT NULL,
    group_name public.citext NOT NULL,
    group_description public.citext,
    group_enabled character(1) NOT NULL,
    group_created timestamp without time zone NOT NULL,
    last_affected timestamp without time zone,
    entered_by public.citext
);


ALTER TABLE public.t_analysis_job_processor_group OWNER TO d3l243;

--
-- Name: TABLE t_analysis_job_processor_group; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_analysis_job_processor_group TO readaccess;

