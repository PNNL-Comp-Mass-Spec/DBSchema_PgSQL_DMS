--
-- Name: v_processors_on_machines_with_active_tools; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_processors_on_machines_with_active_tools AS
 SELECT st.processor_name,
    st.tool_name,
    st.priority,
    st.enabled,
    st.comment,
    st.latest_request,
    st.proc_id,
    st.processor_state,
    st.machine,
    st.total_cpus,
    st.group_id,
    st.group_name,
    st.group_enabled,
    count(DISTINCT (((busyprocessorsq.job)::text || '_'::text) || (busyprocessorsq.step)::text)) AS active_tools,
    min(busyprocessorsq.start) AS start_min,
    max(busyprocessorsq.start) AS start_max,
    max(busyprocessorsq.runtime_predicted_hours) AS runtime_predicted_hours_max
   FROM (sw.v_processor_step_tools_list_report st
     JOIN ( SELECT lp.machine,
            js.tool,
            js.job,
            js.step,
            js.start,
            js.runtime_predicted_hours
           FROM (sw.v_job_steps js
             LEFT JOIN sw.t_local_processors lp ON ((js.processor OPERATOR(public.=) lp.processor_name)))
          WHERE (js.state = 4)) busyprocessorsq ON (((st.machine OPERATOR(public.=) busyprocessorsq.machine) AND (st.tool_name OPERATOR(public.=) busyprocessorsq.tool))))
  GROUP BY st.processor_name, st.tool_name, st.priority, st.enabled, st.comment, st.latest_request, st.proc_id, st.processor_state, st.machine, st.total_cpus, st.group_id, st.group_name, st.group_enabled;


ALTER VIEW sw.v_processors_on_machines_with_active_tools OWNER TO d3l243;

--
-- Name: TABLE v_processors_on_machines_with_active_tools; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_processors_on_machines_with_active_tools TO readaccess;
GRANT SELECT ON TABLE sw.v_processors_on_machines_with_active_tools TO writeaccess;

