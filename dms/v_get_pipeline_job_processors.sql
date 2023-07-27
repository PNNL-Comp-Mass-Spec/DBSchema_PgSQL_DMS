--
-- Name: v_get_pipeline_job_processors; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_get_pipeline_job_processors AS
 SELECT j.job,
    p.processor_name AS processor,
    1 AS general_processing
   FROM ((((public.t_analysis_job j
     JOIN public.t_analysis_job_processor_group_associations pga ON ((j.job = pga.job)))
     JOIN public.t_analysis_job_processor_group pg ON ((pga.group_id = pg.group_id)))
     JOIN public.t_analysis_job_processor_group_membership pgm ON ((pg.group_id = pgm.group_id)))
     JOIN public.t_analysis_job_processors p ON ((pgm.processor_id = p.processor_id)))
  WHERE ((pg.group_enabled OPERATOR(public.=) 'Y'::public.citext) AND (pgm.membership_enabled OPERATOR(public.=) 'Y'::public.citext) AND ((j.job_state_id = ANY (ARRAY[1, 2, 8])) OR ((j.job_state_id = 4) AND (j.finish > (CURRENT_TIMESTAMP - '02:00:00'::interval))) OR ((j.job_state_id = 5) AND (j.start > (CURRENT_TIMESTAMP - '30 days'::interval)))))
  GROUP BY j.job, p.processor_name;


ALTER TABLE public.v_get_pipeline_job_processors OWNER TO d3l243;

--
-- Name: VIEW v_get_pipeline_job_processors; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_get_pipeline_job_processors IS 'Returns jobs new, in progress, or holding, jobs completed within the last 2 hours, and jobs failed within the last 30 days';

--
-- Name: TABLE v_get_pipeline_job_processors; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_get_pipeline_job_processors TO readaccess;
GRANT SELECT ON TABLE public.v_get_pipeline_job_processors TO writeaccess;

