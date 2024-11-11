--
-- Name: v_active_job_stats; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_active_job_stats AS
 SELECT js.tool,
    j.request_id,
    js.state,
    count(*) AS job_steps,
    min(j.job) AS job_min,
    u.name AS job_request_user
   FROM (((sw.v_job_steps js
     JOIN public.t_analysis_job j ON ((js.job = j.job)))
     JOIN public.t_analysis_job_request ajr ON ((j.request_id = ajr.request_id)))
     JOIN public.t_users u ON ((ajr.user_id = u.user_id)))
  WHERE (js.state = ANY (ARRAY[4, 6, 7]))
  GROUP BY js.tool, j.request_id, js.state, u.name;


ALTER VIEW sw.v_active_job_stats OWNER TO d3l243;

--
-- Name: TABLE v_active_job_stats; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_active_job_stats TO readaccess;
GRANT SELECT ON TABLE sw.v_active_job_stats TO writeaccess;

