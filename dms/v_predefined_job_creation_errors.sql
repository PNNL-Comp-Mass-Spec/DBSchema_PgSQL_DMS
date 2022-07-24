--
-- Name: v_predefined_job_creation_errors; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_predefined_job_creation_errors AS
 SELECT sq.item,
    d.dataset,
    sq.state,
    sq.result_code,
    sq.message,
    sq.jobs_created,
    sq.entered,
    sq.last_affected
   FROM (public.t_predefined_analysis_scheduling_queue sq
     JOIN public.t_dataset d ON ((sq.dataset_id = d.dataset_id)))
  WHERE ((sq.result_code <> 0) AND (sq.state OPERATOR(public.<>) ALL (ARRAY['ErrorIgnore'::public.citext, 'Skipped'::public.citext])) AND (sq.last_affected >= (CURRENT_TIMESTAMP - '14 days'::interval)));


ALTER TABLE public.v_predefined_job_creation_errors OWNER TO d3l243;

--
-- Name: VIEW v_predefined_job_creation_errors; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_predefined_job_creation_errors IS 'Report errors within the last 14 days';

--
-- Name: TABLE v_predefined_job_creation_errors; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_predefined_job_creation_errors TO readaccess;

