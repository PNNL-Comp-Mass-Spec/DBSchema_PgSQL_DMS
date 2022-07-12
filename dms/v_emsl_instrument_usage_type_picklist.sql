--
-- Name: v_emsl_instrument_usage_type_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_emsl_instrument_usage_type_picklist AS
 SELECT t_emsl_instrument_usage_type.usage_type_id AS id,
    t_emsl_instrument_usage_type.usage_type,
    t_emsl_instrument_usage_type.description
   FROM public.t_emsl_instrument_usage_type
  WHERE (t_emsl_instrument_usage_type.enabled > 0);


ALTER TABLE public.v_emsl_instrument_usage_type_picklist OWNER TO d3l243;

--
-- Name: TABLE v_emsl_instrument_usage_type_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_emsl_instrument_usage_type_picklist TO readaccess;

