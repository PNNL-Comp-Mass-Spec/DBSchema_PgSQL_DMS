--
-- Name: v_pnnl_projects_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_pnnl_projects_list_report AS
 SELECT project_number,
    project_title,
    setup_date,
    effective_date,
    inactive_date,
    deactivated,
    deactivated_date,
    resp_employee_id,
    resp_username,
    resp_hid,
    resp_cost_code,
    last_change_date,
    last_affected,
    invalid,
    project_num
   FROM public.t_pnnl_projects;


ALTER VIEW public.v_pnnl_projects_list_report OWNER TO d3l243;

--
-- Name: TABLE v_pnnl_projects_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_pnnl_projects_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_pnnl_projects_list_report TO writeaccess;

