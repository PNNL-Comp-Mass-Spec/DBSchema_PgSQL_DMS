--
-- Name: v_analysis_job_backlog_history; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_backlog_history AS
 SELECT tool.analysis_tool,
    sh.posting_time,
    sum(sh.job_count) AS backlog_count
   FROM (public.t_analysis_job_status_history sh
     JOIN public.t_analysis_tool tool ON ((sh.tool_id = tool.analysis_tool_id)))
  WHERE (sh.state_id = ANY (ARRAY[1, 2, 3, 8]))
  GROUP BY sh.posting_time, tool.analysis_tool;


ALTER VIEW public.v_analysis_job_backlog_history OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_backlog_history; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_backlog_history TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_backlog_history TO writeaccess;

