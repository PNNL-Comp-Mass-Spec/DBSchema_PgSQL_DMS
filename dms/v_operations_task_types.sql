--
-- Name: v_operations_task_types; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_operations_task_types AS
 SELECT task_type_name
   FROM public.t_operations_task_type
  WHERE (task_type_active > 0);


ALTER VIEW public.v_operations_task_types OWNER TO d3l243;

--
-- Name: TABLE v_operations_task_types; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_operations_task_types TO readaccess;
GRANT SELECT ON TABLE public.v_operations_task_types TO writeaccess;

