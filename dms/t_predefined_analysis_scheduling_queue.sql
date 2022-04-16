--
-- Name: t_predefined_analysis_scheduling_queue; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_predefined_analysis_scheduling_queue (
    item integer NOT NULL,
    dataset_id integer NOT NULL,
    calling_user public.citext,
    analysis_tool_name_filter public.citext,
    exclude_datasets_not_released smallint,
    prevent_duplicate_jobs smallint,
    state public.citext NOT NULL,
    result_code integer,
    message public.citext,
    jobs_created integer NOT NULL,
    entered timestamp without time zone NOT NULL,
    last_affected timestamp without time zone NOT NULL
);


ALTER TABLE public.t_predefined_analysis_scheduling_queue OWNER TO d3l243;

--
-- Name: TABLE t_predefined_analysis_scheduling_queue; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_predefined_analysis_scheduling_queue TO readaccess;

