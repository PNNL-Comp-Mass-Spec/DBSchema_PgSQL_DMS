--
-- Name: v_operations_tasks_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_operations_tasks_entry AS
 SELECT opstask.task_id AS id,
    tasktype.task_type_name,
    opstask.task,
    opstask.requester,
    opstask.requested_personnel,
    opstask.assigned_personnel,
    opstask.description,
    opstask.comments,
    l.lab_name,
    opstask.status,
    opstask.priority,
    opstask.work_package
   FROM ((public.t_operations_tasks opstask
     JOIN public.t_operations_task_type tasktype ON ((opstask.task_type_id = tasktype.task_type_id)))
     JOIN public.t_lab_locations l ON ((opstask.lab_id = l.lab_id)));


ALTER VIEW public.v_operations_tasks_entry OWNER TO d3l243;

--
-- Name: TABLE v_operations_tasks_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_operations_tasks_entry TO readaccess;
GRANT SELECT ON TABLE public.v_operations_tasks_entry TO writeaccess;

