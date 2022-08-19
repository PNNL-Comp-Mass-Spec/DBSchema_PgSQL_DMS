--
-- Name: v_prep_instrument_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_prep_instrument_picklist AS
 SELECT t_instrument_name.instrument_id AS id,
    t_instrument_name.instrument AS name
   FROM public.t_instrument_name
  WHERE ((t_instrument_name.instrument_group OPERATOR(public.=) 'PrepHPLC'::public.citext) AND (t_instrument_name.status = ANY (ARRAY['active'::bpchar, 'offline'::bpchar])));


ALTER TABLE public.v_prep_instrument_picklist OWNER TO d3l243;

--
-- Name: TABLE v_prep_instrument_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_prep_instrument_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_prep_instrument_picklist TO writeaccess;

