--
-- Name: v_instrument_class_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_class_list_report AS
 SELECT t_instrument_class.instrument_class,
    t_instrument_class.is_purgeable AS is_purgable,
    t_instrument_class.raw_data_type,
    t_instrument_class.requires_preparation,
    t_instrument_class.comment
   FROM public.t_instrument_class;


ALTER TABLE public.v_instrument_class_list_report OWNER TO d3l243;

--
-- Name: TABLE v_instrument_class_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_class_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_class_list_report TO writeaccess;

