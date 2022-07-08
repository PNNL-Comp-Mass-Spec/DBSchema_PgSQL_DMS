--
-- Name: v_capture_method_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_capture_method_picklist AS
 SELECT DISTINCT t_instrument_name.capture_method AS val
   FROM public.t_instrument_name
  WHERE (t_instrument_name.status = 'active'::bpchar);


ALTER TABLE public.v_capture_method_picklist OWNER TO d3l243;

--
-- Name: TABLE v_capture_method_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_capture_method_picklist TO readaccess;

