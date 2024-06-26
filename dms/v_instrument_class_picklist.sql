--
-- Name: v_instrument_class_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_class_picklist AS
 SELECT instrument_class AS name,
    comment AS description
   FROM public.t_instrument_class;


ALTER VIEW public.v_instrument_class_picklist OWNER TO d3l243;

--
-- Name: TABLE v_instrument_class_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_class_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_class_picklist TO writeaccess;

