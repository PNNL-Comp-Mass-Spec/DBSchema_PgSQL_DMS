--
-- Name: v_instrument_admin_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_admin_picklist AS
 SELECT ((((instrument)::text || ' '::text) || (usage)::text))::public.citext AS val,
    instrument AS ex
   FROM public.t_instrument_name
  WHERE (status OPERATOR(public.=) ANY (ARRAY['Active'::public.citext, 'Offline'::public.citext, 'Broken'::public.citext]));


ALTER VIEW public.v_instrument_admin_picklist OWNER TO d3l243;

--
-- Name: TABLE v_instrument_admin_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_admin_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_admin_picklist TO writeaccess;

