--
-- Name: v_emsl_instruments; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_emsl_instruments AS
 SELECT emslinst.eus_display_name,
    emslinst.eus_instrument_name,
    emslinst.eus_instrument_id,
    emslinst.local_instrument_name,
    instmap.dms_instrument_id,
    dmsinstname.instrument
   FROM ((public.t_instrument_name dmsinstname
     JOIN public.t_emsl_dms_instrument_mapping instmap ON ((dmsinstname.instrument_id = instmap.dms_instrument_id)))
     RIGHT JOIN public.t_emsl_instruments emslinst ON ((instmap.eus_instrument_id = emslinst.eus_instrument_id)));


ALTER VIEW public.v_emsl_instruments OWNER TO d3l243;

--
-- Name: TABLE v_emsl_instruments; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_emsl_instruments TO readaccess;
GRANT SELECT ON TABLE public.v_emsl_instruments TO writeaccess;

