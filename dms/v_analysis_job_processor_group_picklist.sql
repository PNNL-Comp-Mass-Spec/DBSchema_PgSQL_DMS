--
-- Name: v_analysis_job_processor_group_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_processor_group_picklist AS
 SELECT t_analysis_job_processor_group.group_id AS id,
    t_analysis_job_processor_group.group_name,
    ((((t_analysis_job_processor_group.group_name)::text || ' ('::text) || (t_analysis_job_processor_group.group_id)::text) || ')'::text) AS name_with_id
   FROM public.t_analysis_job_processor_group;


ALTER TABLE public.v_analysis_job_processor_group_picklist OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_processor_group_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_processor_group_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_processor_group_picklist TO writeaccess;

