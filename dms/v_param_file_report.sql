--
-- Name: v_param_file_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_param_file_report AS
 SELECT pf.param_file_name,
    pf.param_file_description AS description,
    COALESCE(pf.job_usage_count, 0) AS job_count,
    pf.param_file_id,
    pf.param_file_type_id,
    pf.valid AS is_valid,
    pf.date_created
   FROM public.t_param_files pf;


ALTER TABLE public.v_param_file_report OWNER TO d3l243;

--
-- Name: TABLE v_param_file_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_param_file_report TO readaccess;

