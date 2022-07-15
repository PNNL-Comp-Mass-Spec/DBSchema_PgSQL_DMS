--
-- Name: v_instrument_class_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_class_picklist AS
 SELECT t_instrument_class.instrument_class AS name,
    t_instrument_class.comment AS description
   FROM public.t_instrument_class;


ALTER TABLE public.v_instrument_class_picklist OWNER TO d3l243;

--
-- Name: TABLE v_instrument_class_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_class_picklist TO readaccess;

