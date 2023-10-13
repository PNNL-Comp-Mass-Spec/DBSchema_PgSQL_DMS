--
-- Name: v_instrument_status_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_status_picklist AS
 SELECT t_instrument_state_name.state_name AS val
   FROM public.t_instrument_state_name;


ALTER TABLE public.v_instrument_status_picklist OWNER TO d3l243;

--
-- Name: TABLE v_instrument_status_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_status_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_status_picklist TO writeaccess;

