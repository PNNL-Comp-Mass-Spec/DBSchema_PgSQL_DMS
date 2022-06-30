--
-- Name: v_tasks_history; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_tasks_history AS
 SELECT j.job,
    j.priority,
    j.script,
    j.state,
    jsn.job_state AS state_name,
    ds.dataset,
    j.dataset_id,
    inst.instrument,
    inst.instrument_class,
    j.results_folder_name,
    j.imported,
    j.start,
    j.finish,
    j.saved
   FROM (((cap.t_tasks_history j
     JOIN cap.t_task_state_name jsn ON ((j.state = jsn.job_state_id)))
     LEFT JOIN public.t_dataset ds ON ((j.dataset_id = ds.dataset_id)))
     LEFT JOIN public.t_instrument_name inst ON ((ds.instrument_id = inst.instrument_id)));


ALTER TABLE cap.v_tasks_history OWNER TO d3l243;

