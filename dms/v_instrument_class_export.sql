--
-- Name: v_instrument_class_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_class_export AS
 SELECT t_instrument_class.instrument_class,
    t_instrument_class.is_purgeable AS is_purgable,
    t_instrument_class.raw_data_type,
    t_instrument_class.comment
   FROM public.t_instrument_class;


ALTER TABLE public.v_instrument_class_export OWNER TO d3l243;

--
-- Name: TABLE v_instrument_class_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_class_export TO readaccess;

