--
-- Name: v_eus_import_instruments; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_import_instruments AS
 SELECT instrument_id,
    instrument_name,
    eus_display_name,
    available_hours,
    active_sw,
    primary_instrument
   FROM eus.vw_instruments;


ALTER VIEW public.v_eus_import_instruments OWNER TO d3l243;

--
-- Name: TABLE v_eus_import_instruments; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_import_instruments TO readaccess;
GRANT SELECT ON TABLE public.v_eus_import_instruments TO writeaccess;

