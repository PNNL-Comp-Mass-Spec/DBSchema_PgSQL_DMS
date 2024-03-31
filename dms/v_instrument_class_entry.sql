--
-- Name: v_instrument_class_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_class_entry AS
 SELECT instrument_class,
    is_purgeable,
    raw_data_type,
    comment,
    params
   FROM public.t_instrument_class;


ALTER VIEW public.v_instrument_class_entry OWNER TO d3l243;

--
-- Name: TABLE v_instrument_class_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_class_entry TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_class_entry TO writeaccess;

