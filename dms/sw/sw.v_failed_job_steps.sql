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
    ((('\\'::text || (localprocs.machine)::text) || '\DMS_FailedResults\'::text) || (js.output_folder)::text) AS failed_results_folder_path
   FROM (sw.v_job_steps js
     JOIN sw.t_local_processors localprocs ON ((js.processor OPERATOR(public.=) localprocs.processor_name)))
  WHERE (js.state = 6);


ALTER TABLE sw.v_failed_job_steps OWNER TO d3l243;

--
-- Name: TABLE v_failed_job_steps; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_failed_job_steps TO readaccess;
GRANT SELECT ON TABLE sw.v_failed_job_steps TO writeaccess;

