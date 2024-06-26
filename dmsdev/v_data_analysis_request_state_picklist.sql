--
-- Name: v_data_analysis_request_state_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_data_analysis_request_state_picklist AS
 SELECT state_name AS val,
    state_name AS ex,
    state_id
   FROM public.t_data_analysis_request_state_name
  WHERE (active = 1);


ALTER VIEW public.v_data_analysis_request_state_picklist OWNER TO d3l243;

--
-- Name: TABLE v_data_analysis_request_state_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_data_analysis_request_state_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_data_analysis_request_state_picklist TO writeaccess;

