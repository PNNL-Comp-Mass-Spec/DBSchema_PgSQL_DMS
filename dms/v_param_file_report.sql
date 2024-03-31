--
-- Name: v_param_file_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_param_file_report AS
 SELECT param_file_name,
    param_file_description AS description,
    COALESCE(job_usage_count, 0) AS job_count,
    param_file_id,
    param_file_type_id,
    valid AS is_valid,
    date_created
   FROM public.t_param_files pf;


ALTER VIEW public.v_param_file_report OWNER TO d3l243;

--
-- Name: TABLE v_param_file_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_param_file_report TO readaccess;
GRANT SELECT ON TABLE public.v_param_file_report TO writeaccess;

