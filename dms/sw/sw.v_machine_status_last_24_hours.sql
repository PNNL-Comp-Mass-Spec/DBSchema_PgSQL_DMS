--
-- Name: v_machine_status_last_24_hours; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_machine_status_last_24_hours AS
 SELECT statusq.group_name,
    statusq.machine,
    statusq.free_memory_mb_max,
    statusq.processor_count_active_max,
    COALESCE(activetoolq.jobcount, (0)::bigint) AS active_tool_count,
        CASE
            WHEN (COALESCE(activetoolq.jobcount, (0)::bigint) = 0) THEN ''::public.citext
            WHEN (COALESCE(activetoolq.jobcount, (0)::bigint) = 1) THEN activetoolq.step_tool_first
            ELSE ((((((activetoolq.step_tool_first)::text || (' & '::public.citext)::text))::public.citext)::text || (activetoolq.step_tool_last)::text))::public.citext
        END AS active_tool_name
   FROM (( SELECT ptg.group_name,
            ms.machine,
            max(ms.free_memory_mb) AS free_memory_mb_max,
            max(ms.processor_count_active) AS processor_count_active_max
           FROM ((sw.t_machine_status_history ms
             JOIN sw.t_machines m ON ((ms.machine OPERATOR(public.=) m.machine)))
             JOIN sw.t_processor_tool_groups ptg ON ((m.proc_tool_group_id = ptg.group_id)))
          WHERE ((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (ms.posting_time)::timestamp with time zone)) / 3600.0) <= (24)::numeric)
          GROUP BY ms.machine, ptg.group_name) statusq
     LEFT JOIN ( SELECT lp.machine,
            count(js.tool) AS jobcount,
            public.min(js.tool) AS step_tool_first,
            public.max(js.tool) AS step_tool_last
           FROM (sw.t_local_processors lp
             JOIN sw.t_job_steps js ON ((js.processor OPERATOR(public.=) lp.processor_name)))
          WHERE (js.state = 4)
          GROUP BY lp.machine) activetoolq ON ((statusq.machine OPERATOR(public.=) activetoolq.machine)));


ALTER VIEW sw.v_machine_status_last_24_hours OWNER TO d3l243;

--
-- Name: TABLE v_machine_status_last_24_hours; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_machine_status_last_24_hours TO readaccess;
GRANT SELECT ON TABLE sw.v_machine_status_last_24_hours TO writeaccess;

