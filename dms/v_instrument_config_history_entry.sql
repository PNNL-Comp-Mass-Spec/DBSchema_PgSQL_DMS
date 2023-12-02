--
-- Name: v_instrument_config_history_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_config_history_entry AS
 SELECT h.entry_id AS id,
    h.instrument,
    h.description,
    h.note,
    h.entered,
    h.entered_by AS posted_by,
    (h.date_of_change)::date AS date_of_change
   FROM public.t_instrument_config_history h;


ALTER VIEW public.v_instrument_config_history_entry OWNER TO d3l243;

--
-- Name: TABLE v_instrument_config_history_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_config_history_entry TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_config_history_entry TO writeaccess;

