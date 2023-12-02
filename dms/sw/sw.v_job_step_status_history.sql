--
-- Name: v_job_step_status_history; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_job_step_status_history AS
 SELECT ct.posting_time,
    COALESCE(ct."Waiting", 0) AS waiting,
    COALESCE(ct."Enabled", 0) AS enabled,
    COALESCE(ct."Running", 0) AS running,
    COALESCE(ct."Completed", 0) AS completed,
    COALESCE(ct."Failed", 0) AS failed,
    COALESCE(ct."Holding", 0) AS holding
   FROM public.crosstab('SELECT date_trunc(''minute'', JSH.Posting_Time) AS Posting_time,
           SSN.step_state as State_Name,
           Sum(Step_Count)
    FROM sw.t_job_step_status_history JSH
             INNER JOIN sw.t_job_step_state_name SSN
               ON JSH.State = SSN.step_state_id
    GROUP BY date_trunc(''minute'', JSH.Posting_Time), SSN.step_state
    ORDER BY Posting_time, State_Name'::text, 'SELECT unnest(''{Waiting, Enabled, Running, Completed, Failed, Holding }''::citext[])'::text) ct(posting_time timestamp without time zone, "Waiting" integer, "Enabled" integer, "Running" integer, "Completed" integer, "Failed" integer, "Holding" integer);


ALTER VIEW sw.v_job_step_status_history OWNER TO d3l243;

--
-- Name: TABLE v_job_step_status_history; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_job_step_status_history TO readaccess;
GRANT SELECT ON TABLE sw.v_job_step_status_history TO writeaccess;

