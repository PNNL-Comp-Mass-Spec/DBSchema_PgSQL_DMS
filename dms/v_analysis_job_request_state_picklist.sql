--
-- Name: v_analysis_job_request_state_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_job_request_state_picklist AS
 SELECT t_analysis_job_request_state.request_state_id AS id,
    t_analysis_job_request_state.request_state AS name
   FROM public.t_analysis_job_request_state
  WHERE (t_analysis_job_request_state.request_state OPERATOR(public.<>) 'na'::public.citext);


ALTER VIEW public.v_analysis_job_request_state_picklist OWNER TO d3l243;

--
-- Name: TABLE v_analysis_job_request_state_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_job_request_state_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_analysis_job_request_state_picklist TO writeaccess;

