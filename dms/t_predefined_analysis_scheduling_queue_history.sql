--
-- Name: t_predefined_analysis_scheduling_queue_history; Type: TABLE; Schema: public; Owner: d3l243
--

CREATE TABLE public.t_predefined_analysis_scheduling_queue_history (
    entry_id integer NOT NULL,
    dataset_id integer NOT NULL,
    ds_rating smallint NOT NULL,
    jobs_created integer NOT NULL,
    entered timestamp without time zone NOT NULL
);


ALTER TABLE public.t_predefined_analysis_scheduling_queue_history OWNER TO d3l243;

--
-- Name: TABLE t_predefined_analysis_scheduling_queue_history; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.t_predefined_analysis_scheduling_queue_history TO readaccess;

