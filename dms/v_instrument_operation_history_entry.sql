--
-- Name: v_instrument_operation_history_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_operation_history_entry AS
 SELECT t_instrument_operation_history.entry_id AS id,
    t_instrument_operation_history.instrument,
    t_instrument_operation_history.entered,
    t_instrument_operation_history.entered_by AS posted_by,
    t_instrument_operation_history.note
   FROM public.t_instrument_operation_history;


ALTER TABLE public.v_instrument_operation_history_entry OWNER TO d3l243;

--
-- Name: TABLE v_instrument_operation_history_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_operation_history_entry TO readaccess;

