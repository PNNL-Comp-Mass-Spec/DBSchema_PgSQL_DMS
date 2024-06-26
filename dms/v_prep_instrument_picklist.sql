--
-- Name: v_prep_instrument_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_prep_instrument_picklist AS
 SELECT instrument_id AS id,
    instrument AS name
   FROM public.t_instrument_name
  WHERE ((instrument_group OPERATOR(public.=) 'PrepHPLC'::public.citext) AND (status OPERATOR(public.=) ANY (ARRAY['Active'::public.citext, 'Offline'::public.citext, 'PrepHPLC'::public.citext])));


ALTER VIEW public.v_prep_instrument_picklist OWNER TO d3l243;

--
-- Name: TABLE v_prep_instrument_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_prep_instrument_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_prep_instrument_picklist TO writeaccess;

