--
-- Name: v_dms_pipeline_get_completed_results_transfer; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_dms_pipeline_get_completed_results_transfer AS
 SELECT js.finish,
    js.input_folder_name,
    js.output_folder_name,
    j.dataset,
    j.dataset_id,
    js.step,
    js.job
   FROM (sw.t_job_steps js
     JOIN sw.t_jobs j ON ((js.job = j.job)))
  WHERE ((js.state = 5) AND (js.step_tool OPERATOR(public.=) 'Results_Transfer'::public.citext));


ALTER TABLE cap.v_dms_pipeline_get_completed_results_transfer OWNER TO d3l243;

--
-- Name: TABLE v_dms_pipeline_get_completed_results_transfer; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_dms_pipeline_get_completed_results_transfer TO readaccess;

