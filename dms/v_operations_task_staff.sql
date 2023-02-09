--
-- Name: v_operations_task_staff; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_operations_task_staff AS
 SELECT u.username,
    u.name_with_username AS name
   FROM (public.t_user_operations_permissions o
     JOIN public.t_users u ON ((o.user_id = u.user_id)))
  WHERE ((u.status OPERATOR(public.=) 'Active'::public.citext) AND (o.operation_id = ANY (ARRAY[16, 36])));


ALTER TABLE public.v_operations_task_staff OWNER TO d3l243;

--
-- Name: VIEW v_operations_task_staff; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_operations_task_staff IS 'Operation_ID to operation name map: 16="DMS_Sample_Preparation", 36="DMS_Sample_Prep_Request_State"';

--
-- Name: TABLE v_operations_task_staff; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_operations_task_staff TO readaccess;
GRANT SELECT ON TABLE public.v_operations_task_staff TO writeaccess;

