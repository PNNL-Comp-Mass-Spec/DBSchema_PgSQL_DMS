--
-- Name: v_param_file_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_param_file_export AS
 SELECT pf.param_file_id,
    pf.param_file_name,
    pft.param_file_type,
    pf.param_file_description,
    pf.date_created,
    pf.date_modified,
    pf.job_usage_count,
    pf.job_usage_last_year,
    pf.valid
   FROM (public.t_param_files pf
     JOIN public.t_param_file_types pft ON ((pf.param_file_type_id = pft.param_file_type_id)));


ALTER VIEW public.v_param_file_export OWNER TO d3l243;

--
-- Name: TABLE v_param_file_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_param_file_export TO readaccess;
GRANT SELECT ON TABLE public.v_param_file_export TO writeaccess;

