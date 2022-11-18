--
-- Name: v_operations_tasks_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_operations_tasks_list_report AS
 SELECT opstask.task_id AS id,
    tasktype.task_type_name AS task_type,
    opstask.task,
    opstask.description,
    COALESCE(u.name_with_username, opstask.requester) AS requester,
    opstask.assigned_personnel,
    opstask.comments,
    l.lab_name AS lab,
    opstask.status,
    opstask.priority,
        CASE
            WHEN (opstask.status OPERATOR(public.=) ANY (ARRAY['Completed'::public.citext, 'Not Implemented'::public.citext])) THEN round((EXTRACT(epoch FROM (opstask.closed - opstask.created)) / (86400)::numeric))
            ELSE round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (opstask.created)::timestamp with time zone)) / (86400)::numeric))
        END AS days_in_queue,
    opstask.work_package,
    opstask.created,
    opstask.closed,
        CASE
            WHEN (opstask.status OPERATOR(public.=) ANY (ARRAY['Completed'::public.citext, 'Not Implemented'::public.citext])) THEN 0
            WHEN (round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (opstask.created)::timestamp with time zone)) / (86400)::numeric)) <= (30)::numeric) THEN 30
            WHEN (round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (opstask.created)::timestamp with time zone)) / (86400)::numeric)) <= (60)::numeric) THEN 60
            WHEN (round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (opstask.created)::timestamp with time zone)) / (86400)::numeric)) <= (90)::numeric) THEN 90
            ELSE 120
        END AS age_bracket
   FROM (((public.t_operations_tasks opstask
     JOIN public.t_operations_task_type tasktype ON ((opstask.task_type_id = tasktype.task_type_id)))
     JOIN public.t_lab_locations l ON ((opstask.lab_id = l.lab_id)))
     LEFT JOIN public.t_users u ON ((opstask.requester OPERATOR(public.=) u.username)));


ALTER TABLE public.v_operations_tasks_list_report OWNER TO d3l243;

--
-- Name: TABLE v_operations_tasks_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_operations_tasks_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_operations_tasks_list_report TO writeaccess;

