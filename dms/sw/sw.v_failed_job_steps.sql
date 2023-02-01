--
-- Name: v_failed_job_steps; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_failed_job_steps AS
 SELECT js.job,
    js.dataset,
    js.step,
    js.script,
    js.tool,
    js.state_name,
    js.state,
    js.start,
    js.finish,
    js.runtime_minutes,
    js.processor,
    localprocs.machine,
    js.input_folder,
    js.output_folder,
    js.completion_code,
    js.completion_message,
    js.evaluation_code,
    js.evaluation_message,
    js.transfer_folder_path,
    ((((((('\\'::text || (localprocs.machine)::text) || '\'::text) || "substring"((failurefolderq.value)::text, 1, 1)) || '$'::text) || "substring"((failurefolderq.value)::text, 3, 150)) || '\'::text) || (js.output_folder)::text) AS failed_results_folder_path
   FROM ((sw.v_job_steps js
     JOIN sw.t_local_processors localprocs ON ((js.processor OPERATOR(public.=) localprocs.processor_name)))
     JOIN ( SELECT m.mgr_name,
            v.value
           FROM ((mc.t_param_type t
             JOIN mc.t_param_value v ON ((t.param_type_id = v.param_type_id)))
             JOIN mc.t_mgrs m ON ((v.mgr_id = m.mgr_id)))
          WHERE (t.param_type_id = 114)) failurefolderq ON ((localprocs.processor_name OPERATOR(public.=) failurefolderq.mgr_name)))
  WHERE ((js.state = 6) OR (((js.evaluation_code & 2) = 2) AND (js.start >= (CURRENT_TIMESTAMP - '2 days'::interval))));


ALTER TABLE sw.v_failed_job_steps OWNER TO d3l243;

--
-- Name: VIEW v_failed_job_steps; Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON VIEW sw.v_failed_job_steps IS 'Use a Bitwise Or to look for Evaluation_Codes that include Code 2, which indicates for Sequest that NodeCountActive is less than the expected value';

--
-- Name: TABLE v_failed_job_steps; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_failed_job_steps TO readaccess;
GRANT SELECT ON TABLE sw.v_failed_job_steps TO writeaccess;

