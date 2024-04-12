--
-- Name: v_eus_instrument_id_lookup; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_instrument_id_lookup AS
 SELECT inst.instrument_id,
    inst.instrument AS instrument_name,
    edm.eus_instrument_id,
    emslinst.eus_display_name,
    emslinst.eus_instrument_name,
    emslinst.local_instrument_name
   FROM ((public.t_emsl_dms_instrument_mapping edm
     JOIN public.t_instrument_name inst ON ((edm.dms_instrument_id = inst.instrument_id)))
     JOIN public.t_emsl_instruments emslinst ON ((edm.eus_instrument_id = emslinst.eus_instrument_id)));


ALTER VIEW public.v_eus_instrument_id_lookup OWNER TO d3l243;

--
-- Name: TABLE v_eus_instrument_id_lookup; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_instrument_id_lookup TO readaccess;
GRANT SELECT ON TABLE public.v_eus_instrument_id_lookup TO writeaccess;

