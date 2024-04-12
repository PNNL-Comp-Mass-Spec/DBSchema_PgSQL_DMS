--
-- Name: v_instrument_operation_history_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_operation_history_entry AS
 SELECT entry_id AS id,
    instrument,
    entered,
    entered_by AS posted_by,
    note
   FROM public.t_instrument_operation_history;


ALTER VIEW public.v_instrument_operation_history_entry OWNER TO d3l243;

--
-- Name: TABLE v_instrument_operation_history_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_operation_history_entry TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_operation_history_entry TO writeaccess;

