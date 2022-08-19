--
-- Name: v_eus_import_instruments; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_import_instruments AS
 SELECT vw_instruments.instrument_id,
    vw_instruments.instrument_name,
    vw_instruments.eus_display_name,
    vw_instruments.available_hours,
    vw_instruments.active_sw,
    vw_instruments.primary_instrument
   FROM eus.vw_instruments;


ALTER TABLE public.v_eus_import_instruments OWNER TO d3l243;

--
-- Name: TABLE v_eus_import_instruments; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_import_instruments TO readaccess;
GRANT SELECT ON TABLE public.v_eus_import_instruments TO writeaccess;

