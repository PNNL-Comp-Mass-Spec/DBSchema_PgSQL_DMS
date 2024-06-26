--
-- Name: v_default_psm_job_types; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_default_psm_job_types AS
 SELECT job_type_name,
    job_type_description,
    job_type_id
   FROM public.t_default_psm_job_types;


ALTER VIEW public.v_default_psm_job_types OWNER TO d3l243;

--
-- Name: TABLE v_default_psm_job_types; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_default_psm_job_types TO readaccess;
GRANT SELECT ON TABLE public.v_default_psm_job_types TO writeaccess;

