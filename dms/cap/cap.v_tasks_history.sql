--
-- Name: v_tasks_history; Type: VIEW; Schema: cap; Owner: d3l243
--

CREATE VIEW cap.v_tasks_history AS
 SELECT t.job,
    t.priority,
    t.script,
    t.state,
    tsn.job_state AS state_name,
    ds.dataset,
    t.dataset_id,
    inst.instrument,
    inst.instrument_class,
    t.results_folder_name,
    t.imported,
    t.start,
    t.finish,
    t.saved
   FROM (((cap.t_tasks_history t
     JOIN cap.t_task_state_name tsn ON ((t.state = tsn.job_state_id)))
     LEFT JOIN public.t_dataset ds ON ((t.dataset_id = ds.dataset_id)))
     LEFT JOIN public.t_instrument_name inst ON ((ds.instrument_id = inst.instrument_id)));


ALTER TABLE cap.v_tasks_history OWNER TO d3l243;

--
-- Name: TABLE v_tasks_history; Type: ACL; Schema: cap; Owner: d3l243
--

GRANT SELECT ON TABLE cap.v_tasks_history TO readaccess;
GRANT SELECT ON TABLE cap.v_tasks_history TO writeaccess;

