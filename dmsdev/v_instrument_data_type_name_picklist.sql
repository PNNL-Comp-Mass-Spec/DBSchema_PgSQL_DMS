--
-- Name: v_instrument_data_type_name_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_data_type_name_picklist AS
 SELECT raw_data_type_id AS id,
    raw_data_type_name AS name
   FROM public.t_instrument_data_type_name;


ALTER VIEW public.v_instrument_data_type_name_picklist OWNER TO d3l243;

--
-- Name: TABLE v_instrument_data_type_name_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_data_type_name_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_data_type_name_picklist TO writeaccess;

