--
-- Name: v_operations_user_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_operations_user_list_report AS
 SELECT operation,
    operation_description,
    (public.get_operation_dms_users_name_list(operation_id, 0))::public.citext AS assigned_users
   FROM public.t_user_operations;


ALTER VIEW public.v_operations_user_list_report OWNER TO d3l243;

--
-- Name: VIEW v_operations_user_list_report; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_operations_user_list_report IS 'Note that get_operation_dms_users_name_list only includes Active users';

--
-- Name: TABLE v_operations_user_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_operations_user_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_operations_user_list_report TO writeaccess;

