--
-- Name: v_instrument_class_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_class_export AS
 SELECT instrument_class,
    is_purgeable,
    raw_data_type,
    comment
   FROM public.t_instrument_class;


ALTER VIEW public.v_instrument_class_export OWNER TO d3l243;

--
-- Name: TABLE v_instrument_class_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_class_export TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_class_export TO writeaccess;

