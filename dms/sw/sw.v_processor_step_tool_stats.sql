--
-- Name: v_processor_step_tool_stats; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_processor_step_tool_stats AS
 SELECT js.processor,
    js.tool AS step_tool,
    EXTRACT(year FROM js.start) AS the_year,
    EXTRACT(month FROM js.start) AS the_month,
    count(js.step) AS job_step_count,
    dateq.start_max
   FROM (sw.t_job_steps js
     JOIN ( SELECT t_job_steps.processor,
            t_job_steps.tool AS step_tool,
            max(t_job_steps.start) AS start_max
           FROM sw.t_job_steps
          WHERE (COALESCE(t_job_steps.processor, ''::public.citext) OPERATOR(public.<>) ''::public.citext)
          GROUP BY t_job_steps.processor, t_job_steps.tool) dateq ON (((js.processor OPERATOR(public.=) dateq.processor) AND (js.tool OPERATOR(public.=) dateq.step_tool))))
  WHERE (COALESCE(js.processor, ''::public.citext) OPERATOR(public.<>) ''::public.citext)
  GROUP BY js.processor, js.tool, (EXTRACT(year FROM js.start)), (EXTRACT(month FROM js.start)), dateq.start_max;


ALTER VIEW sw.v_processor_step_tool_stats OWNER TO d3l243;

--
-- Name: TABLE v_processor_step_tool_stats; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_processor_step_tool_stats TO readaccess;
GRANT SELECT ON TABLE sw.v_processor_step_tool_stats TO writeaccess;

