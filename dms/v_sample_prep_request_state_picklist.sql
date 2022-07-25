--
-- Name: v_sample_prep_request_state_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_sample_prep_request_state_picklist AS
 SELECT t_sample_prep_request_state_name.state_name AS val,
    t_sample_prep_request_state_name.state_name AS ex,
    t_sample_prep_request_state_name.state_id
   FROM public.t_sample_prep_request_state_name
  WHERE (t_sample_prep_request_state_name.active = 1);


ALTER TABLE public.v_sample_prep_request_state_picklist OWNER TO d3l243;

--
-- Name: TABLE v_sample_prep_request_state_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_sample_prep_request_state_picklist TO readaccess;

