--
-- Name: v_instrument_config_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_config_list_report AS
 SELECT instrument,
    status,
    description,
    usage,
    operations_role AS operations
   FROM public.t_instrument_name;


ALTER VIEW public.v_instrument_config_list_report OWNER TO d3l243;

--
-- Name: TABLE v_instrument_config_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_config_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_config_list_report TO writeaccess;

