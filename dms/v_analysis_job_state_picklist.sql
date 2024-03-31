--
-- Name: v_analysis_job_state_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_state_picklist AS
 SELECT job_state_id AS id,
    job_state AS name,
    comment
   FROM public.t_analysis_job_state;


ALTER VIEW public.v_analysis_job_state_picklist OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_state_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_state_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_state_picklist TO writeaccess;

