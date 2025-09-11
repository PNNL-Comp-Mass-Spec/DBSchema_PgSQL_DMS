--
-- Name: v_pnnl_projects_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_pnnl_projects_detail_report AS
 SELECT p.project_number,
    p.project_title,
    p.setup_date,
    p.effective_date,
    p.inactive_date,
    p.deactivated,
    p.deactivated_date,
    p.resp_employee_id AS responsible_person_employee_id,
    p.resp_username AS responsible_person_username,
    p.resp_hid AS responsible_person_hanford_id,
    u_hid.name AS responsible_person_name,
    p.resp_cost_code,
    p.last_change_date,
    p.last_affected,
    p.invalid,
    p.project_num
   FROM (public.t_pnnl_projects p
     LEFT JOIN public.t_users u_hid ON ((p.resp_hid OPERATOR(public.=) u_hid.hid_number)));


ALTER VIEW public.v_pnnl_projects_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_pnnl_projects_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_pnnl_projects_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_pnnl_projects_detail_report TO writeaccess;

