--
-- Name: v_get_pipeline_job_priority; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_get_pipeline_job_priority AS
 SELECT j.job,
    j.priority
   FROM public.t_analysis_job j
  WHERE (j.job_state_id = ANY (ARRAY[1, 2, 8]));


ALTER TABLE public.v_get_pipeline_job_priority OWNER TO d3l243;

--
-- Name: TABLE v_get_pipeline_job_priority; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_get_pipeline_job_priority TO readaccess;

