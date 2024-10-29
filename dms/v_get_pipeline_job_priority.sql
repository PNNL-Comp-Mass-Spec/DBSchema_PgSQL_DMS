--
-- Name: v_get_pipeline_job_priority; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_get_pipeline_job_priority AS
 SELECT job,
    priority
   FROM public.t_analysis_job j
  WHERE (job_state_id = ANY (ARRAY[1, 2, 8, 20]));


ALTER VIEW public.v_get_pipeline_job_priority OWNER TO d3l243;

--
-- Name: VIEW v_get_pipeline_job_priority; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_get_pipeline_job_priority IS 'Returns job number and priority for jobs with state 1, 2, 8, or 20 (new, in progress, holding, or pending)';

--
-- Name: TABLE v_get_pipeline_job_priority; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_get_pipeline_job_priority TO readaccess;
GRANT SELECT ON TABLE public.v_get_pipeline_job_priority TO writeaccess;

