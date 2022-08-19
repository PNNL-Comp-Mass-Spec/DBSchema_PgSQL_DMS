--
-- Name: v_default_psm_job_tools; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_default_psm_job_tools AS
 SELECT DISTINCT t_default_psm_job_settings.tool_name,
    t_analysis_tool.description
   FROM (public.t_default_psm_job_settings
     JOIN public.t_analysis_tool ON ((t_default_psm_job_settings.tool_name OPERATOR(public.=) t_analysis_tool.analysis_tool)))
  WHERE (t_default_psm_job_settings.enabled > 0);


ALTER TABLE public.v_default_psm_job_tools OWNER TO d3l243;

--
-- Name: TABLE v_default_psm_job_tools; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_default_psm_job_tools TO readaccess;
GRANT SELECT ON TABLE public.v_default_psm_job_tools TO writeaccess;

