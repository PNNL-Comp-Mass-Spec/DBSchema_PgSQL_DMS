--
-- Name: v_operations_task_staff_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_operations_task_staff_picklist AS
 SELECT u.username AS prn,
    u.name_with_username AS name
   FROM (public.t_user_operations_permissions o
     JOIN public.t_users u ON ((o.user_id = u.user_id)))
  WHERE ((u.status OPERATOR(public.=) 'Active'::public.citext) AND (o.operation_id = 16));


ALTER TABLE public.v_operations_task_staff_picklist OWNER TO d3l243;

--
-- Name: VIEW v_operations_task_staff_picklist; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_operations_task_staff_picklist IS 'Operation_ID 16 is operation "DMS_Sample_Preparation"';

--
-- Name: TABLE v_operations_task_staff_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_operations_task_staff_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_operations_task_staff_picklist TO writeaccess;

