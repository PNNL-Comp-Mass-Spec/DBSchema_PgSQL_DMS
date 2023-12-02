--
-- Name: v_dms_pipeline_get_completed_results_transfer; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_dms_pipeline_get_completed_results_transfer AS
 SELECT ts.finish,
    ts.input_folder_name,
    ts.output_folder_name,
    t.dataset,
    t.dataset_id,
    ts.step,
    ts.job
   FROM (sw.t_job_steps ts
     JOIN sw.t_jobs t ON ((ts.job = t.job)))
  WHERE ((ts.state = 5) AND (ts.tool OPERATOR(public.=) 'Results_Transfer'::public.citext));


ALTER VIEW cap.v_dms_pipeline_get_completed_results_transfer OWNER TO d3l243;

--
-- Name: TABLE v_dms_pipeline_get_completed_results_transfer; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_dms_pipeline_get_completed_results_transfer TO readaccess;
GRANT SELECT ON TABLE cap.v_dms_pipeline_get_completed_results_transfer TO writeaccess;

