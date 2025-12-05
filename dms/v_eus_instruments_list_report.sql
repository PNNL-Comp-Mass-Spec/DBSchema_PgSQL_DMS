--
-- Name: v_eus_instruments_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_instruments_list_report AS
 SELECT emslinst.eus_instrument_id,
    emslinst.eus_instrument_name,
    emslinst.eus_display_name,
    emslinst.eus_active_sw AS eus_active,
    instmap.dms_instrument_id,
    dmsinstname.instrument,
    emslinst.local_instrument_name,
    emslinst.local_category_name,
    emslinst.eus_primary_instrument,
    emslinst.last_affected
   FROM ((public.t_instrument_name dmsinstname
     JOIN public.t_emsl_dms_instrument_mapping instmap ON ((dmsinstname.instrument_id = instmap.dms_instrument_id)))
     RIGHT JOIN public.t_emsl_instruments emslinst ON ((instmap.eus_instrument_id = emslinst.eus_instrument_id)));


ALTER VIEW public.v_eus_instruments_list_report OWNER TO d3l243;

--
-- Name: TABLE v_eus_instruments_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_instruments_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_eus_instruments_list_report TO writeaccess;

