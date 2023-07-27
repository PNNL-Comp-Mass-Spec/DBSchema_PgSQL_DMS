--
-- Name: v_instrument_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_picklist AS
 SELECT (((t_instrument_name.instrument)::text || ' '::text) || (t_instrument_name.usage)::text) AS val,
    t_instrument_name.instrument AS ex
   FROM public.t_instrument_name
  WHERE ((NOT (t_instrument_name.instrument OPERATOR(public.~~) 'SW_%'::public.citext)) AND (t_instrument_name.status OPERATOR(public.=) ANY (ARRAY['active'::public.citext, 'offline'::public.citext])) AND (t_instrument_name.operations_role OPERATOR(public.<>) 'QC'::public.citext));


ALTER TABLE public.v_instrument_picklist OWNER TO d3l243;

--
-- Name: TABLE v_instrument_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_picklist TO writeaccess;

